import Foundation
import Supabase

@MainActor
struct MacMediaMonitoringService {
    let client: SupabaseClient

    func fetchMonitors(workspaceId: UUID) async throws -> [MediaMonitorRecord] {
        try await client
            .from("monitor_profiles")
            .select()
            .eq("workspace_id", value: workspaceId.uuidString)
            .order("updated_at", ascending: false)
            .execute()
            .value
    }

    func fetchResults(monitorId: UUID, limit: Int = 80) async throws -> [MediaMonitorResultRecord] {
        try await client
            .from("monitor_results")
            .select("id, monitor_profile_id, title, url, author, published_at, sentiment")
            .eq("monitor_profile_id", value: monitorId.uuidString)
            .order("published_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func createMonitor(workspaceId: UUID, userId: UUID, name: String, keywords: String) async throws -> MediaMonitorRecord {
        struct Insert: Encodable {
            let workspace_id: UUID
            let name: String
            let keywords: String
            let created_by: UUID
        }
        return try await client
            .from("monitor_profiles")
            .insert(Insert(workspace_id: workspaceId, name: name, keywords: keywords, created_by: userId))
            .select()
            .single()
            .execute()
            .value
    }
}
