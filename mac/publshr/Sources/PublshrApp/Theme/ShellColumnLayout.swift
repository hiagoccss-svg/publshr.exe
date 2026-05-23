import SwiftUI

/// Three-column shell widths — fixed tokens at 1280pt reference; shrink only when the window is too narrow.
enum ShellColumnLayout {
    static let referenceWindowWidth: CGFloat = 1280

    /// Primary bar menu (Chat / Spaces labels) — Cursor Mac sidebar (~228pt).
    static let barExpandedWidth: CGFloat = 228
    @available(*, deprecated, message: "Bar menu no longer collapses to icon rail")
    static let barCollapsedMin: CGFloat = barExpandedWidth
    @available(*, deprecated, message: "Bar menu no longer collapses to icon rail")
    static let barCollapsedMax: CGFloat = barExpandedWidth

    /// Universal submenu — wider for filters + channel titles (Cursor / ClickUp parity).
    static let submenuWidth: CGFloat = 304
    static let submenuMinWidth: CGFloat = 280

    static let editorMinWidth: CGFloat = 420

    static var dividerWidth: CGFloat { CursorMacShellDesign.columnDividerWidth }

    /// Primary column is always the full labeled bar menu (no icon-rail collapse).
    static func barMenuColumnWidth(
        windowWidth: CGFloat,
        submenuVisible: Bool
    ) -> CGFloat {
        fittedBarExpanded(windowWidth: windowWidth, submenuVisible: submenuVisible)
    }

    static func submenuColumnWidth(
        windowWidth: CGFloat,
        barWidth: CGFloat,
        submenuVisible: Bool
    ) -> CGFloat {
        guard submenuVisible else { return 0 }
        let dividers = dividerWidth * 2
        let available = windowWidth - barWidth - dividers - editorMinWidth
        return min(submenuWidth, max(submenuMinWidth, available))
    }

    /// Editor column receives all remaining width (min `editorMinWidth` when possible).
    static func editorColumnMinWidth(
        windowWidth: CGFloat,
        barWidth: CGFloat,
        submenuWidth: CGFloat,
        submenuVisible: Bool
    ) -> CGFloat {
        let dividers = submenuVisible ? dividerWidth * 2 : dividerWidth
        let remaining = windowWidth - barWidth - (submenuVisible ? submenuWidth : 0) - dividers
        return max(0, remaining)
    }

    private static func fittedBarExpanded(
        windowWidth: CGFloat,
        submenuVisible: Bool
    ) -> CGFloat {
        let dividers = submenuVisible ? dividerWidth * 2 : dividerWidth
        let fixedPeer = submenuVisible ? submenuWidth : 0
        let reserved = fixedPeer + dividers + editorMinWidth
        let availableForBar = windowWidth - reserved
        let minBarForLabels: CGFloat = 200
        return min(barExpandedWidth, max(minBarForLabels, availableForBar))
    }
}
