import Foundation
import Supabase

/// Upserts `app_background_sync_tasks` so Supabase records each device's background sync cycle.
enum AppBackgroundSyncTaskService {
    struct TaskRow: Encodable {
        let user_id: UUID
        let device_key: String
        let status: String
        let current_step: String
        let client_build: Int
        let client_version: String
        let remote_live_version: String?
        let needs_app_update: Bool
        let last_sync_started_at: String?
        let last_sync_completed_at: String?
        let last_log_excerpt: String
        let last_error: String?
    }

    @MainActor
    static func reportRunning(
        client: SupabaseClient,
        userId: UUID,
        step: String,
        remoteLiveVersion: String?,
        needsAppUpdate: Bool
    ) async {
        await upsert(
            client: client,
            userId: userId,
            status: "running",
            step: step,
            remoteLiveVersion: remoteLiveVersion,
            needsAppUpdate: needsAppUpdate,
            logExcerpt: LocalSyncLogReader.summarize().excerpt,
            error: nil,
            completed: false
        )
    }

    @MainActor
    static func reportCompleted(
        client: SupabaseClient,
        userId: UUID,
        step: String,
        remoteLiveVersion: String?,
        needsAppUpdate: Bool,
        error: String?
    ) async {
        await upsert(
            client: client,
            userId: userId,
            status: error == nil ? "completed" : "failed",
            step: step,
            remoteLiveVersion: remoteLiveVersion,
            needsAppUpdate: needsAppUpdate,
            logExcerpt: LocalSyncLogReader.summarize().excerpt,
            error: error,
            completed: true
        )
    }

    @MainActor
    private static func upsert(
        client: SupabaseClient,
        userId: UUID,
        status: String,
        step: String,
        remoteLiveVersion: String?,
        needsAppUpdate: Bool,
        logExcerpt: String,
        error: String?,
        completed: Bool
    ) async {
        let iso = ISO8601DateFormatter()
        let now = iso.string(from: Date())
        let deviceKey = DeviceIdentityService.stableDeviceKey()
        let row = TaskRow(
            user_id: userId,
            device_key: deviceKey,
            status: status,
            current_step: step,
            client_build: AppReleaseConfig.buildNumber,
            client_version: AppReleaseConfig.liveFullVersion,
            remote_live_version: remoteLiveVersion,
            needs_app_update: needsAppUpdate,
            last_sync_started_at: completed ? nil : now,
            last_sync_completed_at: completed ? now : nil,
            last_log_excerpt: String(logExcerpt.prefix(2_400)),
            last_error: error.map { String($0.prefix(500)) }
        )
        try? await client
            .from("app_background_sync_tasks")
            .upsert(row, onConflict: "user_id,device_key")
            .execute()
    }
}
