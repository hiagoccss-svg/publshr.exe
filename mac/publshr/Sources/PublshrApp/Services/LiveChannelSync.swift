import Foundation

extension Notification.Name {
    /// Posted when the app has no restorable window — SwiftUI should `openWindow(id: "main")`.
    static let publshrRestoreMainWindow = Notification.Name("com.publshr.restoreMainWindow")
    /// Posted when the app becomes active or wakes — triggers GitHub live sync + Supabase refresh.
    static let publshrPerformLiveSync = Notification.Name("publshrPerformLiveSync")
    /// Posted after each GitHub live poll — refreshes Chat, Spaces, and enterprise data from Supabase.
    static let publshrPerformCloudSync = Notification.Name("publshrPerformCloudSync")
    /// `object`: `AppModule.rawValue` (excluding `.settings`).
    static let publshrSelectModule = Notification.Name("com.publshr.selectModule")
}
