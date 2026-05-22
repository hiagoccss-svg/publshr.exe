import Foundation
import Supabase

@MainActor
final class SpacesService {
    let client: SupabaseClient
    private var realtimeTask: Task<Void, Never>?
    private let jsonDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    init(client: SupabaseClient) {
        self.client = client
    }

    func stopRealtime() {
        realtimeTask?.cancel()
        realtimeTask = nil
    }

    // MARK: - Spaces

    func fetchSpaces(workspaceId: UUID) async throws -> [SpaceRecord] {
        try await client
            .from("spaces")
            .select()
            .eq("workspace_id", value: workspaceId.uuidString)
            .eq("is_archived", value: false)
            .order("is_pinned", ascending: false)
            .order("name")
            .execute()
            .value
    }

    func createSpace(workspaceId: UUID, ownerId: UUID, name: String, type: String = "general") async throws -> SpaceRecord {
        struct Insert: Encodable {
            let workspace_id: UUID
            let owner_id: UUID
            let name: String
            let type: String
        }
        let row: SpaceRecord = try await client
            .from("spaces")
            .insert(Insert(workspace_id: workspaceId, owner_id: ownerId, name: name, type: type))
            .select()
            .single()
            .execute()
            .value
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

    // MARK: - Folders & lists (ClickUp hierarchy)

    func fetchFolders(spaceId: UUID) async throws -> [SpaceFolderRecord] {
        try await client
            .from("space_folders")
            .select()
            .eq("space_id", value: spaceId.uuidString)
            .eq("is_archived", value: false)
            .order("sort_order")
            .execute()
            .value
    }

    func fetchLists(spaceId: UUID, folderId: UUID? = nil) async throws -> [SpaceListRecord] {
        var query = client
            .from("space_lists")
            .select()
            .eq("space_id", value: spaceId.uuidString)
            .eq("is_archived", value: false)
        if let folderId {
            query = query.eq("folder_id", value: folderId.uuidString)
        }
        return try await query.order("sort_order").execute().value
    }

    func createFolder(spaceId: UUID, name: String) async throws -> SpaceFolderRecord {
        struct Insert: Encodable { let space_id: UUID; let name: String }
        return try await client
            .from("space_folders")
            .insert(Insert(space_id: spaceId, name: name))
            .select()
            .single()
            .execute()
            .value
    }

    func createList(spaceId: UUID, folderId: UUID?, name: String) async throws -> SpaceListRecord {
        struct Insert: Encodable {
            let space_id: UUID
            let folder_id: UUID?
            let name: String
        }
        return try await client
            .from("space_lists")
            .insert(Insert(space_id: spaceId, folder_id: folderId, name: name))
            .select()
            .single()
            .execute()
            .value
    }

    // MARK: - Tasks

    func fetchTasks(spaceId: UUID, listId: UUID? = nil) async throws -> [SpaceTaskRecord] {
        var query = client
            .from("tasks")
            .select()
            .eq("space_id", value: spaceId.uuidString)
            .neq("status", value: SpaceTaskStatus.archived.rawValue)
        if let listId {
            query = query.eq("list_id", value: listId.uuidString)
        }
        return try await query.order("sort_order").execute().value
    }

    func createTask(
        spaceId: UUID,
        title: String,
        listId: UUID? = nil,
        status: SpaceTaskStatus = .todo,
        priority: SpaceTaskPriority = .normal,
        assigneeId: UUID? = nil,
        dueDate: String? = nil
    ) async throws -> SpaceTaskRecord {
        struct Insert: Encodable {
            let space_id: UUID
            let list_id: UUID?
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
                list_id: listId,
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
        return row
    }

    func updateTaskStatus(taskId: UUID, status: SpaceTaskStatus) async throws {
        _ = try await updateTask(id: taskId, patch: SpaceTaskPatch(status: status.rawValue))
    }

    func archiveTask(taskId: UUID) async throws {
        _ = try await updateTask(id: taskId, patch: SpaceTaskPatch(status: SpaceTaskStatus.archived.rawValue))
    }

    // MARK: - Activity

    func fetchActivity(spaceId: UUID, limit: Int = 40) async throws -> [SpaceActivityRecord] {
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
        let row: SpaceCommentRecord = try await client
            .from("space_comments")
            .insert(Insert(space_id: spaceId, task_id: taskId, user_id: userId, body: body))
            .select()
            .single()
            .execute()
            .value
        return row
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

    func createDocument(spaceId: UUID, title: String, docType: String = "brief") async throws -> SpaceDocumentRecord {
        struct Insert: Encodable {
            let space_id: UUID
            let title: String
            let doc_type: String
        }
        let row: SpaceDocumentRecord = try await client
            .from("documents")
            .insert(Insert(space_id: spaceId, title: title, doc_type: docType))
            .select()
            .single()
            .execute()
            .value
        return row
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
        guard !ids.isEmpty else {
            let all: [Profile] = try await client.from("profiles").select().execute().value
            return all
        }
        let profiles: [Profile] = try await client
            .from("profiles")
            .select()
            .in("id", values: ids.map(\.uuidString))
            .execute()
            .value
        return profiles
    }

    // MARK: - Realtime

    func subscribeWorkspace(
        workspaceId: UUID,
        onTaskChange: @escaping @Sendable () -> Void,
        onSpaceChange: @escaping @Sendable () -> Void
    ) {
        realtimeTask?.cancel()
        realtimeTask = Task {
            let channel = await client.channel("spaces-\(workspaceId.uuidString)")
            let taskInserts = await channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "tasks"
            )
            let taskUpdates = await channel.postgresChange(
                UpdateAction.self,
                schema: "public",
                table: "tasks"
            )
            let spaceUpdates = await channel.postgresChange(
                UpdateAction.self,
                schema: "public",
                table: "spaces",
                filter: "workspace_id=eq.\(workspaceId.uuidString)"
            )
            await channel.subscribe()
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    for await _ in taskInserts { onTaskChange() }
                }
                group.addTask {
                    for await _ in taskUpdates { onTaskChange() }
                }
                group.addTask {
                    for await _ in spaceUpdates { onSpaceChange() }
                }
            }
        }
    }
}
