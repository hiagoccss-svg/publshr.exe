import Foundation
import Supabase

@MainActor
final class SpacesService {
    let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

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

    func fetchTasks(spaceId: UUID) async throws -> [SpaceTaskRecord] {
        try await client
            .from("tasks")
            .select()
            .eq("space_id", value: spaceId.uuidString)
            .neq("status", value: SpaceTaskStatus.archived.rawValue)
            .order("sort_order")
            .execute()
            .value
    }

    func createSpace(workspaceId: UUID, ownerId: UUID, name: String) async throws -> SpaceRecord {
        struct Insert: Encodable {
            let workspace_id: UUID
            let owner_id: UUID
            let name: String
        }
        let row: SpaceRecord = try await client
            .from("spaces")
            .insert(Insert(workspace_id: workspaceId, owner_id: ownerId, name: name))
            .select()
            .single()
            .execute()
            .value
        return row
    }

    func createTask(spaceId: UUID, title: String) async throws -> SpaceTaskRecord {
        struct Insert: Encodable {
            let space_id: UUID
            let title: String
        }
        let row: SpaceTaskRecord = try await client
            .from("tasks")
            .insert(Insert(space_id: spaceId, title: title))
            .select()
            .single()
            .execute()
            .value
        return row
    }

    func updateTaskStatus(taskId: UUID, status: SpaceTaskStatus) async throws {
        struct Patch: Encodable { let status: String }
        try await client
            .from("tasks")
            .update(Patch(status: status.rawValue))
            .eq("id", value: taskId.uuidString)
            .execute()
    }
}
