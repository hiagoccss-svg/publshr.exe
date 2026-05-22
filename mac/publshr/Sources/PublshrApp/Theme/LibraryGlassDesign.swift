import SwiftUI

/// Reference library UI — exact spacing, radii, and proportions (glass sidebar + masonry cards).
enum LibraryGlassDesign {
    // Layout proportions (~22% sidebar at 1200px)
    static let sidebarWidth: CGFloat = 260
    static let sidebarWidthWide: CGFloat = 272
    static let activityBarWidth: CGFloat = 48
    /// Labeled bar menu (reference: Daily Note, Inbox, Notes…).
    static let activityBarExpandedWidth: CGFloat = 88
    static let sidebarSelection = Color(hex: 0xE8E6E1).opacity(0.9)

    // Spacing (reference image)
    static let outerMargin: CGFloat = 24
    static let gridGutter: CGFloat = 18
    static let cardPadding: CGFloat = 16
    static let cardRadius: CGFloat = 18
    static let sidebarRowRadius: CGFloat = 10
    static let sidebarRowVertical: CGFloat = 6
    static let sidebarRowHorizontal: CGFloat = 10
    static let sectionLabelTop: CGFloat = 8
    static let sectionLabelBottom: CGFloat = 4

    // Chrome
    static let headerHeight: CGFloat = 38
    static let statusBarHeight: CGFloat = 18
    static let ctaPillHeight: CGFloat = 36
    static let ctaPillHorizontal: CGFloat = 16

    // Masonry
    static let masonryMinColumnWidth: CGFloat = 240
    static let masonryMaxColumns: Int = 4

    // Colors (warm off-white shell)
    static let shellBackground = Color(hex: 0xF3F2EF)
    static let workspaceGlass = Color.white.opacity(0.38)
    static let headerGlass = Color.white.opacity(0.72)
    static let cardBackground = Color.white
    static let cardGlassFill = Color.white.opacity(0.72)
    static let primaryCTA = Color(hex: 0x1A1917)
    static let primaryCTAHover = Color(hex: 0x2D2C28)
    static let ink = Color(hex: 0x1A1917)
    static let inkMuted = Color(hex: 0x8A877F)
    static let inkSecondary = Color(hex: 0x5C5A54)
    static let hairline = Color(hex: 0xE4E2DC).opacity(0.65)
    static let cardShadow = Color.black.opacity(0.06)
}
