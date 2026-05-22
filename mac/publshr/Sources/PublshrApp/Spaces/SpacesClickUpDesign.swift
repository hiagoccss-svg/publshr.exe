import SwiftUI

/// ClickUp-inspired layout tokens for Spaces (sidebar tree, breadcrumbs, views, board).
enum SpacesClickUpDesign {
    // Sidebar
    static let sidebarWidth: CGFloat = LibraryGlassDesign.sidebarWidth
    static let sidebarSectionTop: CGFloat = 12
    static let sidebarSectionBottom: CGFloat = 6
    static let sidebarRowHeight: CGFloat = 30
    static let sidebarRowRadius: CGFloat = LibraryGlassDesign.sidebarRowRadius
    static let sidebarIndentStep: CGFloat = 18
    static let sidebarIconWidth: CGFloat = 16
    static let sidebarHorizontalPadding: CGFloat = 10
    static let treeExpandHitWidth: CGFloat = 22

    // Workspace chrome
    static let breadcrumbBarHeight: CGFloat = 36
    static let viewsBarHeight: CGFloat = 40
    static let chromeHorizontalPadding: CGFloat = 16
    static let chromeItemSpacing: CGFloat = 8

    // Board
    static let boardColumnWidth: CGFloat = 280
    static let boardColumnSpacing: CGFloat = 12
    static let boardColumnPadding: CGFloat = 12
    static let boardCardSpacing: CGFloat = 8
    static let boardCardPadding: CGFloat = LibraryGlassDesign.cardPadding

    // Overview & docs
    static let overviewPadding: CGFloat = LibraryGlassDesign.outerMargin
    static let overviewSectionSpacing: CGFloat = LibraryGlassDesign.gridGutter
    static let metricCardPadding: CGFloat = LibraryGlassDesign.cardPadding
    static let metricCardRadius: CGFloat = LibraryGlassDesign.cardRadius
    static let docRowPadding: CGFloat = LibraryGlassDesign.cardPadding
    static let docRowRadius: CGFloat = LibraryGlassDesign.cardRadius
    static let boardCardRadius: CGFloat = LibraryGlassDesign.cardRadius

    // Inspector
    static let inspectorWidth: CGFloat = 340
    static let inspectorPadding: CGFloat = 16

    // Typography
    static let breadcrumbFont = Font.system(size: 12, weight: .medium)
    static let treeRowFont = Font.system(size: 13)
    static let treeRowSelectedFont = Font.system(size: 13, weight: .semibold)
    static let viewsTabFont = Font.system(size: 12, weight: .medium)
    static let sectionLabelFont = Font.system(size: 10, weight: .semibold)
}
