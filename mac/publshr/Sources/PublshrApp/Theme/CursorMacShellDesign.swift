import SwiftUI

/// Layout + colors matched to Cursor Mac light UI (3-column shell).
enum CursorMacShellDesign {
    /// Window / gutter behind the center editor box.
    static let workspaceBackground = Color(hex: 0xF3F2EF)
    /// Left + middle sidebar columns (Cursor agent / repo list).
    static let columnChromeBackground = Color(hex: 0xF3F3F3)
    /// Chat / workspace editor column — solid white (matches submenu column).
    static let editorColumnBackground = Color.white
    static let titleBarBackground = Color(hex: 0xF3F3F3)
    /// Collapsed primary bar menu (icon rail); matches `LibraryGlassDesign.barMenuCollapsedWidth`.
    static let barMenuIconRailWidth: CGFloat = LibraryGlassDesign.barMenuCollapsedWidth
    /// Center column content card.
    static let editorBoxBackground = Color.white
    static let border = Color(hex: 0xE4E2DC)
    static let borderSubtle = Color(hex: 0xEEEDEB)

    static let titleBarHeight: CGFloat = AppWindowChromeMetrics.trafficLightRowHeight
    static let chatToolbarHeight: CGFloat = 36
    static let columnDividerWidth: CGFloat = 1

    static let editorBoxCornerRadius: CGFloat = 10
    static let editorBoxPadding: CGFloat = 12
    static let editorBoxShadow = Color.black.opacity(0.06)

    static let editorHorizontalPadding: CGFloat = 16
    static let editorTopPadding: CGFloat = 0
    static let editorBottomPadding: CGFloat = 12

    static let titlebarControlSize: CGFloat = AppWindowChromeMetrics.controlSize
    static let titlebarIconSize: CGFloat = AppWindowChromeMetrics.controlIconSize
    static let titlebarActionSpacing: CGFloat = AppWindowChromeMetrics.toolbarItemSpacing

    static let centerTitleFont = Font.system(size: 13, weight: .semibold)
    static let centerTitleColor = Color(hex: 0x1A1917)
}

/// White rounded panel for the third column (Cursor center “card” area).
struct CursorEditorColumnBox: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: CursorMacShellDesign.editorBoxCornerRadius, style: .continuous)
                    .fill(CursorMacShellDesign.editorBoxBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CursorMacShellDesign.editorBoxCornerRadius, style: .continuous)
                    .strokeBorder(CursorMacShellDesign.border, lineWidth: 1)
            )
            .shadow(
                color: CursorMacShellDesign.editorBoxShadow,
                radius: 12,
                y: 4
            )
            .clipShape(
                RoundedRectangle(cornerRadius: CursorMacShellDesign.editorBoxCornerRadius, style: .continuous)
            )
    }
}

extension View {
    func cursorEditorColumnBox() -> some View {
        modifier(CursorEditorColumnBox())
    }

    func cursorColumnDividerTrailing() -> some View {
        overlay(alignment: .trailing) {
            Rectangle()
                .fill(CursorMacShellDesign.border)
                .frame(width: CursorMacShellDesign.columnDividerWidth)
        }
    }
}
