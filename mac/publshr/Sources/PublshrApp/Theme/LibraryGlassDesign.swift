import SwiftUI

/// Reference library UI — proportions from Pinterest / notes-app glass shell (~1200px wide).
enum LibraryGlassDesign {
    /// Primary bar menu (labeled: Daily Note, Inbox, Notes…) — not a 48px icon strip.
    static let barMenuWidth: CGFloat = 200
    /// Universal submenu (Areas, Recent Notes, Channels…).
    static let sidebarWidth: CGFloat = 260
    static let sidebarWidthWide: CGFloat = 272

    @available(*, deprecated, message: "Use barMenuWidth for the reference shell")
    static let activityBarWidth: CGFloat = 48

    static let sidebarSelection = Color(hex: 0xE8E6E1).opacity(0.95)
    static let sidebarGlassFill = Color.white.opacity(0.52)
    static let panelGlassFill = Color.white.opacity(0.68)

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

    // Chrome
    static let headerHeight: CGFloat = 38
    static let statusBarHeight: CGFloat = 22
    static let ctaPillHeight: CGFloat = 36
    static let ctaPillHorizontal: CGFloat = 16

    // Masonry
    static let masonryMinColumnWidth: CGFloat = 240
    static let masonryMaxColumns: Int = 4

    // Colors (warm off-white shell — keep translucent so desktop shows through)
    static let shellBackground = Color(hex: 0xF3F2EF)
    static let workspaceGlass = Color.white.opacity(0.12)
    static let headerGlass = Color.white.opacity(0.55)
    static let cardBackground = Color.white
    static let cardGlassFill = Color.white.opacity(0.72)
    static let primaryCTA = Color(hex: 0x1A1917)
    static let primaryCTAHover = Color(hex: 0x2D2C28)
    static let ink = Color(hex: 0x1A1917)
    static let inkMuted = Color(hex: 0x8A877F)
    static let inkSecondary = Color(hex: 0x5C5A54)
    static let hairline = Color(hex: 0xE4E2DC).opacity(0.55)
    static let cardShadow = Color.black.opacity(0.08)
    static let panelShadow = Color.black.opacity(0.14)
}
