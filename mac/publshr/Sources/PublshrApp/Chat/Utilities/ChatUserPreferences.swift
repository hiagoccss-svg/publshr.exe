import Foundation

/// Per-user chat preferences persisted locally (status, permission prompts, cached workspace settings).
enum ChatUserPreferences {
    private static let statusKey = "publshr.chat.myStatus"
    private static let notificationsPromptedKey = "publshr.chat.notificationsPrompted"
    private static let microphonePromptedKey = "publshr.chat.microphonePrompted"
    private static let permissionsPrefix = "publshr.chat.permissions."
    private static let sidebarFilterKey = "publshr.chat.sidebarFilter"
    private static let sidebarLayoutKey = "publshr.chat.sidebarLayout"
    private static let sidebarSectionsPrefix = "publshr.chat.sidebarSections."
    private static let lastChannelPrefix = "publshr.chat.lastChannel."
    private static let defaultNotificationKey = "publshr.chat.defaultNotificationLevel"
    private static let pinnedChannelsPrefix = "publshr.chat.pinnedChannels."
    private static let macNotificationsKey = "publshr.chat.macNotificationsEnabled"
    private static let incomingPopupKey = "publshr.chat.incomingMessagePopup"
    private static let popupOpensChannelKey = "publshr.chat.popupOpensChannelWindow"
    private static let localTimeZoneKey = "publshr.chat.timestampsLocalTimeZone"

    /// macOS Notification Center alerts for chat.
    static var macNotificationsEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: macNotificationsKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: macNotificationsKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: macNotificationsKey) }
    }

    /// Teams-style floating preview when a message arrives in another channel.
    static var showIncomingMessagePopup: Bool {
        get {
            if UserDefaults.standard.object(forKey: incomingPopupKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: incomingPopupKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: incomingPopupKey) }
    }

    /// When opening from the popup, also pop the channel into its own window.
    static var popupOpensChannelWindow: Bool {
        get {
            if UserDefaults.standard.object(forKey: popupOpensChannelKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: popupOpensChannelKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: popupOpensChannelKey) }
    }

    /// Show message and last-seen times in the Mac's local timezone (with abbreviation).
    static var showTimestampsInLocalTimeZone: Bool {
        get {
            if UserDefaults.standard.object(forKey: localTimeZoneKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: localTimeZoneKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: localTimeZoneKey) }
    }

    /// Default notify level for new channel memberships (ClickUp: All / Mentions / Mute).
    static func loadDefaultNotificationLevel() -> String {
        UserDefaults.standard.string(forKey: defaultNotificationKey) ?? "all"
    }

    static func saveDefaultNotificationLevel(_ level: String) {
        UserDefaults.standard.set(level, forKey: defaultNotificationKey)
    }

    static func loadPinnedChannelIds(workspaceId: UUID) -> Set<UUID> {
        let key = pinnedChannelsPrefix + workspaceId.uuidString
        guard let raw = UserDefaults.standard.array(forKey: key) as? [String] else {
            return []
        }
        return Set(raw.compactMap { UUID(uuidString: $0) })
    }

    static func savePinnedChannelIds(_ ids: Set<UUID>, workspaceId: UUID) {
        let key = pinnedChannelsPrefix + workspaceId.uuidString
        UserDefaults.standard.set(ids.map(\.uuidString), forKey: key)
    }

    static func loadSidebarFilter() -> ChatSidebarFilter {
        guard let raw = UserDefaults.standard.string(forKey: sidebarFilterKey),
              let filter = ChatSidebarFilter(rawValue: raw) else {
            return .all
        }
        return filter
    }

    static func saveSidebarFilter(_ filter: ChatSidebarFilter) {
        UserDefaults.standard.set(filter.rawValue, forKey: sidebarFilterKey)
    }

    static func loadSidebarLayout() -> ChatSidebarLayout {
        guard let raw = UserDefaults.standard.string(forKey: sidebarLayoutKey),
              let layout = ChatSidebarLayout(rawValue: raw) else {
            return .organized
        }
        return layout
    }

    static func saveSidebarLayout(_ layout: ChatSidebarLayout) {
        UserDefaults.standard.set(layout.rawValue, forKey: sidebarLayoutKey)
    }

    static func loadSidebarSectionExpanded(workspaceId: UUID, section: ChatSidebarSection) -> Bool {
        let key = sidebarSectionsPrefix + workspaceId.uuidString + "." + section.rawValue
        guard UserDefaults.standard.object(forKey: key) != nil else { return true }
        return UserDefaults.standard.bool(forKey: key)
    }

    static func saveSidebarSectionExpanded(_ expanded: Bool, workspaceId: UUID, section: ChatSidebarSection) {
        let key = sidebarSectionsPrefix + workspaceId.uuidString + "." + section.rawValue
        UserDefaults.standard.set(expanded, forKey: key)
    }

    static func loadLastSelectedChannelId(workspaceId: UUID) -> UUID? {
        let key = lastChannelPrefix + workspaceId.uuidString
        guard let raw = UserDefaults.standard.string(forKey: key) else { return nil }
        return UUID(uuidString: raw)
    }

    static func saveLastSelectedChannelId(_ channelId: UUID?, workspaceId: UUID) {
        let key = lastChannelPrefix + workspaceId.uuidString
        if let channelId {
            UserDefaults.standard.set(channelId.uuidString, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

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
