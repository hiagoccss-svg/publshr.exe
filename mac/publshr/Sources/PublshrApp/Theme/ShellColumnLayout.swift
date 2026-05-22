import SwiftUI

/// Three-column shell widths — fixed tokens at 1280pt reference; shrink only when the window is too narrow.
enum ShellColumnLayout {
    static let referenceWindowWidth: CGFloat = 1280

    /// Primary bar menu (Chat / Spaces labels) — Cursor Mac ~200pt, not a % of window.
    static let barExpandedWidth: CGFloat = 200
    /// Icon-only bar column (content below titlebar; traffic lights live in titlebar band).
    static let barCollapsedMin: CGFloat = 56
    /// Cap collapsed column so traffic-light reserve does not waste body width.
    static let barCollapsedMax: CGFloat = 96

    static let submenuWidth: CGFloat = 272
    static let submenuMinWidth: CGFloat = 240

    static let editorMinWidth: CGFloat = 420

    static var dividerWidth: CGFloat { CursorMacShellDesign.columnDividerWidth }

    static func barMenuColumnWidth(
        expanded: Bool,
        windowWidth: CGFloat,
        trafficInset: CGFloat,
        submenuVisible: Bool
    ) -> CGFloat {
        if expanded {
            return fittedBarExpanded(windowWidth: windowWidth, submenuVisible: submenuVisible)
        }
        let globalCluster =
            AppWindowChromeMetrics.controlSize * 4
            + AppWindowChromeMetrics.toolbarLeadingClusterSpacing * 3
        let navCluster =
            AppWindowChromeMetrics.controlSize * 2
            + AppWindowChromeMetrics.toolbarItemSpacing
        let trafficLed = trafficInset + globalCluster + navCluster + 12
        let iconLed = AppWindowChromeMetrics.controlSize + 12
        let compact = min(trafficLed, max(barCollapsedMin, iconLed))
        return min(barCollapsedMax, max(barCollapsedMin, compact))
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
        let minBarForLabels: CGFloat = 168
        return min(barExpandedWidth, max(minBarForLabels, availableForBar))
    }
}
