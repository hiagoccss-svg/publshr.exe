import SwiftUI

/// Layout + color tokens aligned with Cursor Mac (Light Modern / VS Code light).
enum CursorMacShellDesign {
    static let workspaceBackground = CursorTheme.editorBackground
    static let titleBarBackground = CursorTheme.titleBar
    static let sidebarBackground = CursorTheme.sideBar
    static let editorSurface = CursorTheme.panelBackground
    static let border = CursorTheme.border
    static let borderSubtle = CursorTheme.borderSubtle

    static let titleBarHeight = CursorTheme.workspaceHeaderHeight
    static let chatToolbarHeight = CursorTheme.chatToolbarHeight
    static let tabHeight = CursorTheme.tabBarHeight
    static let tabCornerRadius = CursorTheme.workspaceTabCornerRadius
    static let tabSpacing = CursorTheme.workspaceTabSpacing
    static let tabHorizontalPadding = CursorTheme.workspaceTabHorizontalPadding

    static let sidebarWidth = CursorTheme.navSidebarWidth
    static let barMenuWidth = CursorTheme.activityBarWidth

    static let titlebarControlSize = CursorTheme.toolbarIconHitSize
    static let titlebarIconSize = CursorTheme.toolbarIconSize
    static let titlebarActionSpacing: CGFloat = 4

    static let editorHorizontalPadding: CGFloat = 16
    static let editorTopPadding: CGFloat = 0
    static let editorBottomPadding: CGFloat = 12
}
