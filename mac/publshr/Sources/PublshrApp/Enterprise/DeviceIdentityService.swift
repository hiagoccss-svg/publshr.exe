import Foundation
import AppKit
import IOKit
import Supabase

/// Stable device identity for enterprise security and session management.
enum DeviceIdentityService {
    private static let deviceKeyDefaults = "com.publshr.enterprise.deviceKey"

    struct DeviceInfo: Equatable {
        let deviceKey: String
        let deviceName: String
        let platform: String
        let appVersion: String
        let modelIdentifier: String
    }

    static var current: DeviceInfo {
        DeviceInfo(
            deviceKey: stableDeviceKey(),
            deviceName: Host.current().localizedName ?? "Mac",
            platform: "macos",
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0",
            modelIdentifier: hardwareModel()
        )
    }

    static func stableDeviceKey() -> String {
        if let existing = UserDefaults.standard.string(forKey: deviceKeyDefaults), !existing.isEmpty {
            return existing
        }
        let newKey = UUID().uuidString.lowercased()
        UserDefaults.standard.set(newKey, forKey: deviceKeyDefaults)
        return newKey
    }

    static func hardwareModel() -> String {
        var size: size_t = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
    }

    @MainActor
    static func register(client: SupabaseClient, userId: UUID, workspaceId: UUID?) async {
        let info = current
        struct Upsert: Encodable {
            let user_id: UUID
            let workspace_id: UUID?
            let device_key: String
            let device_name: String
            let platform: String
            let app_version: String
            let last_seen_at: String
        }
        let iso = ISO8601DateFormatter().string(from: Date())
        let row = Upsert(
            user_id: userId,
            workspace_id: workspaceId,
            device_key: info.deviceKey,
            device_name: info.deviceName,
            platform: info.platform,
            app_version: info.appVersion,
            last_seen_at: iso
        )
        try? await client
            .from("device_registrations")
            .upsert(row, onConflict: "user_id,device_key")
            .execute()
    }
}
