import Foundation

extension Notification.Name {
    /// Posted when the app becomes active or wakes — triggers GitHub live sync.
    static let publshrPerformLiveSync = Notification.Name("publshrPerformLiveSync")

    /// Posted alongside live sync — refreshes Chat, Spaces, and Supabase session data.
    static let publshrPerformEnterpriseSync = Notification.Name("publshrPerformEnterpriseSync")
}
