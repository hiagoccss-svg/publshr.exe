import Foundation
import Supabase

@MainActor
final class MediaMonitoringService {
    let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchProfiles(workspaceId: UUID) async throws -> [MonitorProfileRecord] {
        try await client
            .from("monitor_profiles")
            .select()
            .eq("workspace_id", value: workspaceId.uuidString)
            .order("name")
            .execute()
            .value
    }

    func fetchResults(profileId: UUID, limit: Int = 80) async throws -> [MonitorResultRecord] {
        try await client
            .from("monitor_results")
            .select()
            .eq("monitor_profile_id", value: profileId.uuidString)
            .order("published_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func fetchSavedResultIds(workspaceId: UUID) async throws -> Set<UUID> {
        struct Row: Decodable { let monitorResultId: UUID; enum CodingKeys: String, CodingKey { case monitorResultId = "monitor_result_id" } }
        let rows: [Row] = try await client
            .from("saved_coverage")
            .select("monitor_result_id")
            .eq("workspace_id", value: workspaceId.uuidString)
            .execute()
            .value
        return Set(rows.map(\.monitorResultId))
    }

    func saveCoverage(workspaceId: UUID, resultId: UUID) async throws {
        struct Insert: Encodable {
            let workspace_id: UUID
            let monitor_result_id: UUID
        }
        try await client
            .from("saved_coverage")
            .insert(Insert(workspace_id: workspaceId, monitor_result_id: resultId))
            .execute()
    }
}
