import SwiftUI

/// ClickUp Chat 3.0 / 4.0 layout tokens — sidebar filters, sections, badges.
enum ChatClickUpDesign {
    static let sidebarWidth: CGFloat = LibraryGlassDesign.sidebarWidth

    static let headerHeight: CGFloat = 44
    static let searchHeight: CGFloat = 32
    static let filterBarHeight: CGFloat = 40
    static let footerHeight: CGFloat = 40

    static let filterPillHeight: CGFloat = 26
    static let filterPillRadius: CGFloat = 13
    static let filterPillHPadding: CGFloat = 10

    static let sidebarTitleFont = Font.system(size: 14, weight: .semibold)
    static let searchFont = Font.system(size: 12)
    static let filterFont = Font.system(size: 11, weight: .medium)
    static let footerFont = Font.system(size: 10, weight: .medium)

    static let unreadBadgeFont = Font.system(size: 10, weight: .bold)
    static let activityBadgeFont = Font.system(size: 9, weight: .bold)

    static let rowHeight: CGFloat = 32
    static let rowRadius: CGFloat = 6
    static let rowIconSize: CGFloat = 16

    static let sectionTop: CGFloat = 10
    static let sectionBottom: CGFloat = 4
    static let horizontalPadding: CGFloat = 10
}

enum ChatSidebarFilter: String, CaseIterable, Identifiable {
    case all
    case unread
    case pinned
    case dms
    case channels

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: "All"
        case .unread: "Unread"
        case .pinned: "Pinned"
        case .dms: "DMs"
        case .channels: "Channels"
        }
    }
}

enum ChatSidebarLayout: String, CaseIterable {
    case organized
    case recents

    var label: String {
        switch self {
        case .organized: "Organized"
        case .recents: "Recents"
        }
    }
}
