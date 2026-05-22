import Foundation
import Supabase

@MainActor
final class SpacesService {
    let client: SupabaseClient
    let store: SpacesLocalStore
    private var realtimeTask: Task<Void, Never>?
    private let jsonDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    init(client: SupabaseClient, store: SpacesLocalStore = SpacesLocalStore()) {
        self.client = client
        self.store = store
    }

    func stopRealtime() {
        realtimeTask?.cancel()
        realtimeTask = nil
    }

    // MARK: - Spaces

    func fetchSpaces(workspaceId: UUID) async throws -> [SpaceRecord] {
        let rows: [SpaceRecord] = try await client
            .from("spaces")
            .select()
            .eq("workspace_id", value: workspaceId.uuidString)
            .eq("is_archived", value: false)
            .order("is_pinned", ascending: false)
            .order("name")
            .execute()
            .value
        store.saveSpaces(rows, workspaceId: workspaceId)
        return rows
    }

    func createSpace(
        workspaceId: UUID,
        ownerId: UUID,
        name: String,
        type: String = "general",
        description: String = ""
    ) async throws -> SpaceRecord {
        struct Insert: Encodable {
            let workspace_id: UUID
            let owner_id: UUID
            let name: String
            let type: String
            let description: String
        }
        let row: SpaceRecord = try await client
            .from("spaces")
            .insert(Insert(workspace_id: workspaceId, owner_id: ownerId, name: name, type: type, description: description))
            .select()
            .single()
            .execute()
            .value

        struct MemberInsert: Encodable {
            let space_id: UUID
            let user_id: UUID
            let role: String
        }
        try? await client
            .from("space_members")
            .insert(MemberInsert(space_id: row.id, user_id: ownerId, role: "owner"))
            .execute()

        return row
    }

    func updateSpace(id: UUID, name: String? = nil, description: String? = nil, isPinned: Bool? = nil) async throws {
        struct Patch: Encodable {
            var name: String?
            var description: String?
            var is_pinned: Bool?
        }
        try await client
            .from("spaces")
            .update(Patch(name: name, description: description, is_pinned: isPinned))
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Tasks

    func fetchTasks(spaceId: UUID) async throws -> [SpaceTaskRecord] {
        let rows: [SpaceTaskRecord] = try await client
            .from("tasks")
            .select()
            .eq("space_id", value: spaceId.uuidString)
            .neq("status", value: SpaceTaskStatus.archived.rawValue)
            .order("sort_order")
            .execute()
            .value
        store.saveTasks(rows, spaceId: spaceId)
        return rows
    }

    func createTask(
        spaceId: UUID,
        title: String,
        status: SpaceTaskStatus = .todo,
        priority: SpaceTaskPriority = .normal,
        assigneeId: UUID? = nil,
        dueDate: String? = nil
    ) async throws -> SpaceTaskRecord {
        struct Insert: Encodable {
            let space_id: UUID
            let title: String
            let status: String
            let priority: String
            let assignee_id: UUID?
            let due_date: String?
        }
        let row: SpaceTaskRecord = try await client
            .from("tasks")
            .insert(Insert(
                space_id: spaceId,
                title: title,
                status: status.rawValue,
                priority: priority.rawValue,
                assignee_id: assigneeId,
                due_date: dueDate
            ))
            .select()
            .single()
            .execute()
            .value
        store.upsertTask(row)
        return row
    }

    func updateTask(id: UUID, patch: SpaceTaskPatch) async throws -> SpaceTaskRecord {
        let row: SpaceTaskRecord = try await client
            .from("tasks")
            .update(patch)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
        store.upsertTask(row)
        return row
    }

    func updateTaskStatus(taskId: UUID, status: SpaceTaskStatus) async throws {
        _ = try await updateTask(id: taskId, patch: SpaceTaskPatch(status: status.rawValue))
    }

    func archiveTask(taskId: UUID) async throws {
        _ = try await updateTask(id: taskId, patch: SpaceTaskPatch(status: SpaceTaskStatus.archived.rawValue))
        store.removeTask(id: taskId)
    }

    // MARK: - Activity

    func fetchActivity(spaceId: UUID, limit: Int = 50) async throws -> [SpaceActivityRecord] {
        try await client
            .from("space_activity")
            .select()
            .eq("space_id", value: spaceId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func logActivity(
        spaceId: UUID,
        userId: UUID,
        action: String,
        entityType: String,
        entityId: UUID
    ) async throws {
        struct Insert: Encodable {
            let space_id: UUID
            let user_id: UUID
            let action: String
            let entity_type: String
            let entity_id: UUID
        }
        try await client
            .from("space_activity")
            .insert(Insert(
                space_id: spaceId,
                user_id: userId,
                action: action,
                entity_type: entityType,
                entity_id: entityId
            ))
            .execute()
    }

    // MARK: - Comments

    func fetchComments(taskId: UUID) async throws -> [SpaceCommentRecord] {
        try await client
            .from("space_comments")
            .select()
            .eq("task_id", value: taskId.uuidString)
            .order("created_at")
            .execute()
            .value
    }

    func postComment(spaceId: UUID, taskId: UUID, userId: UUID, body: String) async throws -> SpaceCommentRecord {
        struct Insert: Encodable {
            let space_id: UUID
            let task_id: UUID
            let user_id: UUID
            let body: String
        }
        return try await client
            .from("space_comments")
            .insert(Insert(space_id: spaceId, task_id: taskId, user_id: userId, body: body))
            .select()
            .single()
            .execute()
            .value
    }

    // MARK: - Documents

    func fetchDocuments(spaceId: UUID) async throws -> [SpaceDocumentRecord] {
        try await client
            .from("documents")
            .select()
            .eq("space_id", value: spaceId.uuidString)
            .order("updated_at", ascending: false)
            .execute()
            .value
    }

    func createDocument(spaceId: UUID, title: String, docType: String = "brief", content: String = "") async throws -> SpaceDocumentRecord {
        struct Insert: Encodable {
            let space_id: UUID
            let title: String
            let doc_type: String
            let content: String
        }
        return try await client
            .from("documents")
            .insert(Insert(space_id: spaceId, title: title, doc_type: docType, content: content))
            .select()
            .single()
            .execute()
            .value
    }

    func updateDocument(id: UUID, title: String?, content: String?) async throws -> SpaceDocumentRecord {
        struct Patch: Encodable {
            var title: String?
            var content: String?
        }
        return try await client
            .from("documents")
            .update(Patch(title: title, content: content))
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    // MARK: - Approvals & files

    func fetchApprovals(spaceId: UUID) async throws -> [SpaceApprovalRecord] {
        try await client
            .from("approvals")
            .select()
            .eq("space_id", value: spaceId.uuidString)
            .order("updated_at", ascending: false)
            .execute()
            .value
    }

    func fetchFiles(spaceId: UUID) async throws -> [SpaceFileRecord] {
        try await client
            .from("space_files")
            .select()
            .eq("space_id", value: spaceId.uuidString)
            .order("updated_at", ascending: false)
            .execute()
            .value
    }

    // MARK: - Profiles

    func fetchWorkspaceProfiles(workspaceId: UUID) async throws -> [Profile] {
        struct MemberRow: Decodable { let user_id: UUID }
        let members: [MemberRow] = (try? await client
            .from("workspace_members")
            .select("user_id")
            .eq("workspace_id", value: workspaceId.uuidString)
            .execute()
            .value) ?? []

        let ids = members.map(\.user_id)
        if ids.isEmpty {
            let all: [Profile] = try await client.from("profiles").select().execute().value
            return all
        }
        return try await client
            .from("profiles")
            .select()
            .in("id", values: ids.map(\.uuidString))
            .execute()
            .value
    }

    func cachedSpaces(workspaceId: UUID) -> [SpaceRecord] {
        store.loadSpaces(workspaceId: workspaceId)
    }

    func cachedTasks(spaceId: UUID) -> [SpaceTaskRecord] {
        store.loadTasks(spaceId: spaceId)
    }

    // MARK: - Realtime

    func subscribeWorkspace(
        workspaceId: UUID,
        spaceIds: @escaping @Sendable () -> [UUID],
        selectedSpaceId: @escaping @Sendable () -> UUID?,
        onTaskChange: @escaping @Sendable (UUID?) -> Void,
        onSpaceChange: @escaping @Sendable () -> Void,
        onCommentChange: @escaping @Sendable (UUID) -> Void
    ) {
        realtimeTask?.cancel()
        realtimeTask = Task { [jsonDecoder] in
            let channel = await client.channel("spaces-live-\(workspaceId.uuidString)")
            let taskInserts = await channel.postgresChange(InsertAction.self, schema: "public", table: "tasks")
            let taskUpdates = await channel.postgresChange(UpdateAction.self, schema: "public", table: "tasks")
            let spaceUpdates = await channel.postgresChange(
                UpdateAction.self,
                schema: "public",
                table: "spaces",
                filter: "workspace_id=eq.\(workspaceId.uuidString)"
            )
            let commentInserts = await channel.postgresChange(InsertAction.self, schema: "public", table: "space_comments")
            await channel.subscribe()

            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    for await action in taskInserts {
                        Self.handleTaskAction(action, decoder: jsonDecoder, spaceIds: spaceIds, selectedSpaceId: selectedSpaceId, onTaskChange: onTaskChange)
                    }
                }
                group.addTask {
                    for await action in taskUpdates {
                        Self.handleTaskUpdateAction(action, decoder: jsonDecoder, spaceIds: spaceIds, selectedSpaceId: selectedSpaceId, onTaskChange: onTaskChange)
                    }
                }
                group.addTask {
                    for await _ in spaceUpdates { onSpaceChange() }
                }
                group.addTask {
                    for await action in commentInserts {
                        guard let record = try? action.decodeRecord(as: SpaceCommentRecord.self, decoder: jsonDecoder),
                              let taskId = record.taskId else { continue }
                        onCommentChange(taskId)
                    }
                }
            }
        }
    }

    private static func handleTaskAction(
        _ action: InsertAction,
        decoder: JSONDecoder,
        spaceIds: @Sendable () -> [UUID],
        selectedSpaceId: @Sendable () -> UUID?,
        onTaskChange: @Sendable (UUID?) -> Void
    ) {
        guard let record = try? action.decodeRecord(as: SpaceTaskRecord.self, decoder: decoder) else {
            onTaskChange(selectedSpaceId())
            return
        }
        guard spaceIds().contains(record.spaceId) else { return }
        onTaskChange(record.spaceId)
    }

    private static func handleTaskUpdateAction(
        _ action: UpdateAction,
        decoder: JSONDecoder,
        spaceIds: @Sendable () -> [UUID],
        selectedSpaceId: @Sendable () -> UUID?,
        onTaskChange: @Sendable (UUID?) -> Void
    ) {
        guard let record = try? action.decodeRecord(as: SpaceTaskRecord.self, decoder: decoder) else {
            onTaskChange(selectedSpaceId())
            return
        }
        guard spaceIds().contains(record.spaceId) else { return }
        onTaskChange(record.spaceId)
    }
}
