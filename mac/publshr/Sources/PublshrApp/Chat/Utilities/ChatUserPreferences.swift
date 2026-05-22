import Foundation

/// Per-user chat preferences persisted locally (status, permission prompts, cached workspace settings).
enum ChatUserPreferences {
    private static let statusKey = "publshr.chat.myStatus"
    private static let notificationsPromptedKey = "publshr.chat.notificationsPrompted"
    private static let microphonePromptedKey = "publshr.chat.microphonePrompted"
    private static let permissionsPrefix = "publshr.chat.permissions."

    static func loadMyStatus() -> ChatPresenceStatus {
        guard let raw = UserDefaults.standard.string(forKey: statusKey),
              let status = ChatPresenceStatus(rawValue: raw) else {
            return .online
        }
        return status
    }

    static func saveMyStatus(_ status: ChatPresenceStatus) {
        UserDefaults.standard.set(status.rawValue, forKey: statusKey)
    }

    static var didPromptForNotifications: Bool {
        get { UserDefaults.standard.bool(forKey: notificationsPromptedKey) }
        set { UserDefaults.standard.set(newValue, forKey: notificationsPromptedKey) }
    }

    static var didPromptForMicrophone: Bool {
        get { UserDefaults.standard.bool(forKey: microphonePromptedKey) }
        set { UserDefaults.standard.set(newValue, forKey: microphonePromptedKey) }
    }

    static func cachedPermissions(workspaceId: UUID) -> ChatWorkspacePermissions? {
        guard let data = UserDefaults.standard.data(forKey: permissionsPrefix + workspaceId.uuidString),
              let decoded = try? JSONDecoder().decode(ChatWorkspacePermissions.self, from: data) else {
            return nil
        }
        return decoded
    }

    static func cachePermissions(_ permissions: ChatWorkspacePermissions, workspaceId: UUID) {
        guard let data = try? JSONEncoder().encode(permissions) else { return }
        UserDefaults.standard.set(data, forKey: permissionsPrefix + workspaceId.uuidString)
    }
}
