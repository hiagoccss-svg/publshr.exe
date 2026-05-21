import SwiftUI

enum AppVersionLabel {
    static var current: String { "0.3.0" }
}

enum PublshrTheme {
    static let railWidth: CGFloat = 56
    static let sidebarWidth: CGFloat = 240
    static let contextWidth: CGFloat = 260

    static let bg = Color(red: 0.98, green: 0.98, blue: 0.99)
    static let sidebar = Color(red: 0.96, green: 0.96, blue: 0.97)
    static let panel = Color.white
    static let border = Color.black.opacity(0.08)
    static let accent = Color(red: 0.10, green: 0.45, blue: 0.95)
    static let textPrimary = Color(red: 0.12, green: 0.12, blue: 0.14)
    static let textSecondary = Color.black.opacity(0.45)
    static let topBar = Color.white
}
