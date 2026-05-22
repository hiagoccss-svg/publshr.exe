import SwiftUI

/// Cursor on Mac — Light Modern (auth & default UI) and Dark Modern (IDE).
enum AppAppearance: String, CaseIterable {
    case light
    case dark
}

struct ThemePalette {
    let activityBar: Color
    let activityBarForeground: Color
    let activityBarForegroundDim: Color
    let navSidebar: Color
    let titleBar: Color
    let sideBar: Color
    let sideBarSectionHeader: Color
    let editorBackground: Color
    let editorLineHighlight: Color
    let tabActiveBackground: Color
    let tabInactiveBackground: Color
    let panelBackground: Color
    let chatBackground: Color
    let border: Color
    let borderSubtle: Color
    let foreground: Color
    let foregroundMuted: Color
    let foregroundDim: Color
    let accent: Color
    let accentHover: Color
    let buttonBackground: Color
    let buttonHover: Color
    let buttonForeground: Color
    let inputBackground: Color
    let inputBorder: Color
    let inputBorderFocus: Color
    let statusBar: Color
    let statusBarForeground: Color
    let authBackground: Color
    let authCard: Color
    let authCardShadow: Color
    let error: Color
    let success: Color
    let biometricTint: Color
}

enum CursorTheme {
    /// Global appearance — auth uses light; IDE can follow this.
    static var appearance: AppAppearance = .light

    static var palette: ThemePalette {
        appearance == .light ? light : dark
    }

    // MARK: - Light Modern (Cursor Mac default light — VS Code Light Modern)

    static let light = ThemePalette(
        activityBar: Color(hex: 0xFFFFFF),
        activityBarForeground: Color(hex: 0x3B3B3B),
        activityBarForegroundDim: Color(hex: 0x9D9D9D),
        navSidebar: Color(hex: 0xFFFFFF),
        titleBar: Color(hex: 0xFFFFFF),
        sideBar: Color(hex: 0xFFFFFF),
        sideBarSectionHeader: Color(hex: 0x6E6E6E),
        editorBackground: Color(hex: 0xFFFFFF),
        editorLineHighlight: Color(hex: 0xE8E8E8),
        tabActiveBackground: Color(hex: 0xFFFFFF),
        tabInactiveBackground: Color(hex: 0xECECEC),
        panelBackground: Color(hex: 0xFAFAFA),
        chatBackground: Color(hex: 0xFFFFFF),
        border: Color(hex: 0xECECEC),
        borderSubtle: Color(hex: 0xF0F0F0),
        foreground: Color(hex: 0x3B3B3B),
        foregroundMuted: Color(hex: 0x717171),
        foregroundDim: Color(hex: 0x9D9D9D),
        accent: Color(hex: 0x0078D4),
        accentHover: Color(hex: 0x006BB3),
        buttonBackground: Color(hex: 0x005FB8),
        buttonHover: Color(hex: 0x0258A8),
        buttonForeground: Color.white,
        inputBackground: Color(hex: 0xFFFFFF),
        inputBorder: Color(hex: 0xCECECE),
        inputBorderFocus: Color(hex: 0x0078D4),
        statusBar: Color(hex: 0xF3F3F3),
        statusBarForeground: Color(hex: 0x616161),
        authBackground: Color(hex: 0xF3F3F3),
        authCard: Color(hex: 0xFFFFFF),
        authCardShadow: Color.black.opacity(0.08),
        error: Color(hex: 0xC72E2E),
        success: Color(hex: 0x22863A),
        biometricTint: Color(hex: 0x0078D4)
    )

    // MARK: - Dark Modern

    static let dark = ThemePalette(
        activityBar: Color(hex: 0x2D2D2D),
        activityBarForeground: Color(hex: 0xCCCCCC),
        activityBarForegroundDim: Color(hex: 0x6E6E6E),
        navSidebar: Color(hex: 0x252526),
        titleBar: Color(hex: 0x1E1E1E),
        sideBar: Color(hex: 0x252526),
        sideBarSectionHeader: Color(hex: 0xBBBBBB),
        editorBackground: Color(hex: 0x1E1E1E),
        editorLineHighlight: Color(hex: 0x2A2D2E),
        tabActiveBackground: Color(hex: 0x1E1E1E),
        tabInactiveBackground: Color(hex: 0x2D2D2D),
        panelBackground: Color(hex: 0x181818),
        chatBackground: Color(hex: 0x1E1E1E),
        border: Color(hex: 0x2B2B2B),
        borderSubtle: Color(hex: 0x3C3C3C),
        foreground: Color(hex: 0xCCCCCC),
        foregroundMuted: Color(hex: 0x9D9D9D),
        foregroundDim: Color(hex: 0x6E6E6E),
        accent: Color(hex: 0x007FD4),
        accentHover: Color(hex: 0x1A8AD4),
        buttonBackground: Color(hex: 0x0E639C),
        buttonHover: Color(hex: 0x1177BB),
        buttonForeground: Color.white,
        inputBackground: Color(hex: 0x3C3C3C),
        inputBorder: Color(hex: 0x3C3C3C),
        inputBorderFocus: Color(hex: 0x007FD4),
        statusBar: Color(hex: 0xF3F3F3),
        statusBarForeground: Color(hex: 0x616161),
        authBackground: Color(hex: 0x181818),
        authCard: Color(hex: 0x252526),
        authCardShadow: Color.black.opacity(0.35),
        error: Color(hex: 0xF14C4C),
        success: Color(hex: 0x89D185),
        biometricTint: Color(hex: 0x007FD4)
    )

    // Convenience forwards (existing code uses CursorTheme.foreground etc.)
    static var activityBar: Color { palette.activityBar }
    static var activityBarForeground: Color { palette.activityBarForeground }
    static var activityBarForegroundDim: Color { palette.activityBarForegroundDim }
    static var navSidebar: Color { palette.navSidebar }
    static var titleBar: Color { palette.titleBar }
    static var sideBar: Color { palette.sideBar }
    static var sideBarSectionHeader: Color { palette.sideBarSectionHeader }
    static var editorBackground: Color { palette.editorBackground }
    static var editorLineHighlight: Color { palette.editorLineHighlight }
    static var tabActiveBackground: Color { palette.tabActiveBackground }
    static var tabInactiveBackground: Color { palette.tabInactiveBackground }
    static var panelBackground: Color { palette.panelBackground }
    static var chatBackground: Color { palette.chatBackground }
    static var border: Color { palette.border }
    static var borderSubtle: Color { palette.borderSubtle }
    static var foreground: Color { palette.foreground }
    static var foregroundMuted: Color { palette.foregroundMuted }
    static var foregroundDim: Color { palette.foregroundDim }
    static var accent: Color { palette.accent }
    static var accentHover: Color { palette.accentHover }
    static var buttonBackground: Color { palette.buttonBackground }
    static var buttonHover: Color { palette.buttonHover }
    static var buttonForeground: Color { palette.buttonForeground }
    static var inputBackground: Color { palette.inputBackground }
    static var inputBorder: Color { palette.inputBorder }
    static var inputBorderFocus: Color { palette.inputBorderFocus }
    static var statusBar: Color { palette.statusBar }
    static var statusBarForeground: Color { palette.statusBarForeground }
    static var authBackground: Color { palette.authBackground }
    static var authCard: Color { palette.authCard }
    static var authCardShadow: Color { palette.authCardShadow }
    static var error: Color { palette.error }
    static var success: Color { palette.success }
    static var biometricTint: Color { palette.biometricTint }

    static let activityBarWidth: CGFloat = 48
    static let activityBarIconSize: CGFloat = 15
    /// Settings / module nav column inside the main window.
    static let settingsSidebarWidth: CGFloat = 212
    static let navSidebarWidth: CGFloat = 240
    /// Leading reserve for macOS traffic lights (toolbar shares the title-bar row).
    static let trafficLightLeadingPadding: CGFloat = 72
    /// @deprecated Use traffic-light padding on the unified toolbar only.
    static let windowChromeTopInset: CGFloat = 28
    static let sideBarWidth: CGFloat = 260
    static let chatPanelWidth: CGFloat = 520
    static let titleBarHeight: CGFloat = 38
    static let chatToolbarHeight: CGFloat = 36
    static let statusBarHeight: CGFloat = 18
    static let chatRowSpacing: CGFloat = 16
    static let chatSidebarRowHeight: CGFloat = 30
    static let tabBarHeight: CGFloat = 35
    /// Unified title-bar / toolbar row (icons align with traffic lights).
    static let workspaceHeaderHeight: CGFloat = 38
    static let toolbarIconSize: CGFloat = 11
    static let toolbarIconHitSize: CGFloat = 24
    static var toolbarIconForeground: Color { foregroundMuted }
    static let workspaceTabSpacing: CGFloat = 6
    static let workspaceTabHorizontalPadding: CGFloat = 10
    static let workspaceTabCornerRadius: CGFloat = 7
    /// Hairline separators (sidebars, header, composer).
    static let hairlineOpacity: Double = 0.45
    static var hairline: Color { border.opacity(hairlineOpacity) }
    /// Activity icons align with the workspace header row under traffic lights.
    static let activityBarIconBandHeight: CGFloat = 44
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

private struct ThemePaletteKey: EnvironmentKey {
    static let defaultValue = CursorTheme.palette
}

extension EnvironmentValues {
    var cursorPalette: ThemePalette {
        get { self[ThemePaletteKey.self] }
        set { self[ThemePaletteKey.self] = newValue }
    }
}
