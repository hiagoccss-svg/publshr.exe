import SwiftUI

/// Cursor on Mac (Default Dark Modern) color tokens.
enum CursorTheme {
    // Activity bar / title bar
    static let activityBar = Color(hex: 0x181818)
    static let titleBar = Color(hex: 0x181818)

    // Side bar
    static let sideBar = Color(hex: 0x252526)
    static let sideBarSectionHeader = Color(hex: 0xBBBBBB)

    // Editor
    static let editorBackground = Color(hex: 0x1E1E1E)
    static let editorLineHighlight = Color(hex: 0x2A2D2E)
    static let tabActiveBackground = Color(hex: 0x1E1E1E)
    static let tabInactiveBackground = Color(hex: 0x2D2D2D)

    // Panel / chat
    static let panelBackground = Color(hex: 0x181818)
    static let chatBackground = Color(hex: 0x1E1E1E)

    // Borders & dividers
    static let border = Color(hex: 0x2B2B2B)
    static let borderSubtle = Color(hex: 0x3C3C3C)

    // Text
    static let foreground = Color(hex: 0xCCCCCC)
    static let foregroundMuted = Color(hex: 0x9D9D9D)
    static let foregroundDim = Color(hex: 0x6E6E6E)

    // Accent (Cursor / VS Code focus)
    static let accent = Color(hex: 0x007FD4)
    static let accentHover = Color(hex: 0x1A8AD4)
    static let buttonBackground = Color(hex: 0x0E639C)
    static let buttonHover = Color(hex: 0x1177BB)

    // Input
    static let inputBackground = Color(hex: 0x3C3C3C)
    static let inputBorder = Color(hex: 0x3C3C3C)

    // Status bar
    static let statusBar = Color(hex: 0x007ACC)
    static let statusBarForeground = Color.white

    // Auth card
    static let authCard = Color(hex: 0x252526)
    static let error = Color(hex: 0xF14C4C)
    static let success = Color(hex: 0x89D185)

    // Layout (pt) — matches Cursor chrome
    static let activityBarWidth: CGFloat = 48
    static let sideBarWidth: CGFloat = 260
    static let chatPanelWidth: CGFloat = 520
    static let titleBarHeight: CGFloat = 38
    static let statusBarHeight: CGFloat = 22
    static let tabBarHeight: CGFloat = 35
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
