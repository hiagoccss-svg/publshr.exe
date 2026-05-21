import SwiftUI

enum AppVersionLabel {
    static var current: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.2.0"
    }
}

enum PublshrTheme {
    static let railWidth: CGFloat = 52
    static let sidebarWidth: CGFloat = 260

    static let bg = Color(red: 0.12, green: 0.12, blue: 0.13)
    static let sidebar = Color(red: 0.15, green: 0.15, blue: 0.16)
    static let panel = Color(red: 0.10, green: 0.10, blue: 0.11)
    static let border = Color.white.opacity(0.08)
    static let accent = Color(red: 0.35, green: 0.55, blue: 1.0)
    static let textSecondary = Color.white.opacity(0.55)
}
