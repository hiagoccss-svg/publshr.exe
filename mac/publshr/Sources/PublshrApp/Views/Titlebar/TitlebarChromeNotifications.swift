import Foundation

extension Notification.Name {
    static let publshrTitlebarToggleSidebar = Notification.Name("com.publshr.titlebar.toggleSidebar")
    static let publshrTitlebarNewChat = Notification.Name("com.publshr.titlebar.newChat")
    static let publshrTitlebarNewDM = Notification.Name("com.publshr.titlebar.newDM")
    static let publshrTitlebarCommandPalette = Notification.Name("com.publshr.titlebar.commandPalette")
    static let publshrTitlebarSearch = Notification.Name("com.publshr.titlebar.search")
    static let publshrTitlebarNotifications = Notification.Name("com.publshr.titlebar.notifications")
    static let publshrTitlebarNavigateBack = Notification.Name("com.publshr.titlebar.navigateBack")
    static let publshrTitlebarNavigateForward = Notification.Name("com.publshr.titlebar.navigateForward")
}

/// Human-readable shortcut hints for tooltips (mirrors menu shortcuts in `PublshrApp`).
enum TitlebarShortcutHint {
    static let toggleSidebar = "⌘\\"
    static let newChat = "⌘N"
    static let commandPalette = "⇧⌘P"
    static let search = "⇧⌘F"
    static let navigateBack = "⌘["
    static let navigateForward = "⌘]"
    static let settings = "⌘,"

    static func tooltip(_ title: String, shortcut: String?) -> String {
        guard let shortcut, !shortcut.isEmpty else { return title }
        return "\(title) (\(shortcut))"
    }
}
