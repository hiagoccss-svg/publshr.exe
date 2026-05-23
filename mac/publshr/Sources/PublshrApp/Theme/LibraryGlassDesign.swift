import SwiftUI

/// Reference library UI — proportions from Pinterest / notes-app glass shell (~1280px wide).
enum LibraryGlassDesign {
    /// Primary bar menu expanded width (`ShellColumnLayout.barExpandedWidth`).
    static let barMenuWidth: CGFloat = ShellColumnLayout.barExpandedWidth
    /// Universal submenu — fixed width (ClickUp / Spaces sidebar ~272pt; same in every module).
    static let sidebarWidthWide: CGFloat = ShellColumnLayout.submenuWidth
    static let sidebarWidth: CGFloat = sidebarWidthWide
    /// Collapsed primary column (icon rail); see `ShellColumnLayout.barCollapsedMax`.
    static let barMenuCollapsedWidth: CGFloat = ShellColumnLayout.barCollapsedMax

    /// Horizontal inset for bar-menu rows (tighter than submenu rows).
    static let barMenuRowHorizontal: CGFloat = 10

    /// Column 1 — fixed expanded width; compact icon rail capped below titlebar traffic reserve.
    static func barMenuColumnWidth(
        expanded: Bool,
        windowWidth: CGFloat,
        trafficInset: CGFloat,
        submenuVisible: Bool = true
    ) -> CGFloat {
        ShellColumnLayout.barMenuColumnWidth(
            expanded: expanded,
            windowWidth: windowWidth,
            trafficInset: trafficInset,
            submenuVisible: submenuVisible
        )
    }

    /// Column 2 — fixed universal submenu; shrinks only if the window cannot fit editor minimum.
    static func submenuColumnWidth(
        for windowWidth: CGFloat,
        barWidth: CGFloat,
        submenuVisible: Bool = true
    ) -> CGFloat {
        ShellColumnLayout.submenuColumnWidth(
            windowWidth: windowWidth,
            barWidth: barWidth,
            submenuVisible: submenuVisible
        )
    }

    /// Backward-compatible submenu width (assumes default bar + visible submenu).
    static func submenuColumnWidth(for windowWidth: CGFloat) -> CGFloat {
        let bar = barMenuColumnWidth(
            expanded: true,
            windowWidth: windowWidth,
            trafficInset: AppWindowChromeMetrics.trafficLightLeadingInset,
            submenuVisible: true
        )
        return submenuColumnWidth(for: windowWidth, barWidth: bar, submenuVisible: true)
    }
    /// Column 2 — lighter grey than the primary bar (reads as a soft step toward the editor).
    static let submenuColumnBackground = Color(hex: 0xF4F4F4)
    /// Column 1 — light grey rail behind module icons / bar menu.
    static let primaryBarColumnBackground = Color(hex: 0xE8E8E8)
    /// Chat submenu footer strip (enterprise chrome).
    static let submenuFooterBackground = Color(hex: 0xFAFAF8)

    @available(*, deprecated, message: "Use barMenuWidth for the reference shell")
    static let activityBarWidth: CGFloat = 48

    /// Selected sidebar row (reference: warm beige pill on Chat).
    static let sidebarSelection = Color(hex: 0xE6E2DA)
    static let sidebarSelectionStroke = Color(hex: 0xD8D4CC)
    static let sidebarGlassFill = Color(hex: 0xF7F6F3).opacity(0.88)
    /// Primary bar menu (~200px) — light tint so the desktop wallpaper tints through.
    static let primaryBarGlassFill = Color(hex: 0xEBE8E3).opacity(0.55)
    static let primaryBarGlassStroke = Color.white.opacity(0.12)
    /// @deprecated Submenu uses `submenuColumnBackground` (solid white).
    static let submenuGlassFill = Color.white
    /// Main chat/spaces floating panel — near-opaque white card on gray shell.
    static let panelGlassFill = Color.white.opacity(0.96)

    // Spacing (reference image)
    static let outerMargin: CGFloat = 20
    static let contentPanelRadius: CGFloat = 20
    static let gridGutter: CGFloat = 18
    static let cardPadding: CGFloat = 16
    static let cardRadius: CGFloat = 18
    static let sidebarRowRadius: CGFloat = 10
    static let sidebarRowVertical: CGFloat = 7
    static let sidebarRowHorizontal: CGFloat = 12
    static let sectionLabelTop: CGFloat = 10
    static let sectionLabelBottom: CGFloat = 4
    static let barMenuRowHeight: CGFloat = 34

    // Chrome (titlebar row — see AppWindowChromeMetrics.unifiedTitlebarRowHeight)
    static let headerHeight: CGFloat = AppWindowChromeMetrics.unifiedTitlebarRowHeight
    static let statusBarHeight: CGFloat = 22
    static let ctaPillHeight: CGFloat = 36
    static let ctaPillHorizontal: CGFloat = 16
    static let askAIPillFill = Color(hex: 0xE8D4DC).opacity(0.72)
    static let askAIPillStroke = Color(hex: 0xD4B8C4).opacity(0.45)
    static let documentTabFill = Color(hex: 0xEEEDEA)
    static let documentTabSelectedFill = Color.white

    /// Inactive filter pills (All / Unread / DMs / Channels).
    static let filterPillInactiveFill = Color(hex: 0xEEEDEA)
    static let filterPillInactiveStroke = Color(hex: 0xE4E2DC)

    // Masonry
    static let masonryMinColumnWidth: CGFloat = 240
    static let masonryMaxColumns: Int = 4

    // Colors (warm off-white shell — keep translucent so desktop shows through)
    static let shellBackground = Color(hex: 0xF3F2EF)
    static let workspaceGlass = Color.white.opacity(0.12)
    static let headerGlass = Color.white.opacity(0.38)
    static let cardBackground = Color.white
    static let cardGlassFill = Color.white.opacity(0.72)
    static let primaryCTA = Color(hex: 0x1A1917)
    static let primaryCTAHover = Color(hex: 0x2D2C28)
    static let ink = Color(hex: 0x1A1917)
    static let inkMuted = Color(hex: 0x8A877F)
    static let inkSecondary = Color(hex: 0x5C5A54)
    static let hairline = Color(hex: 0xE4E2DC)
    static let contentDivider = Color(hex: 0xEBEAE6)
    static let cardShadow = Color.black.opacity(0.08)
    static let panelShadow = Color.black.opacity(0.14)
}
