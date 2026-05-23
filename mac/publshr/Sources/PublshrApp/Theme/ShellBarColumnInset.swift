import SwiftUI

/// Aligns bar-column body content with the unified titlebar row (traffic lights + optional back/forward).
enum ShellBarColumnInset {
    /// Width reserved for the traffic-light cluster inside column 1 (matches `ShellUnifiedTitlebar.leadingBand`).
    static func trafficReserve(barWidth: CGFloat, trafficLeadingInset: CGFloat) -> CGFloat {
        min(trafficLeadingInset, max(0, barWidth - AppWindowChromeMetrics.controlSize))
    }

    /// Leading padding for expanded bar-menu rows so labels sit under back/forward, not under traffic lights.
    static func bodyLeadingPadding(
        barWidth: CGFloat,
        expanded: Bool,
        trafficLeadingInset: CGFloat
    ) -> CGFloat {
        let reserve = trafficReserve(barWidth: barWidth, trafficLeadingInset: trafficLeadingInset)
        guard expanded else { return reserve }
        let navigationChrome =
            AppWindowChromeMetrics.controlSize * 2
            + AppWindowChromeMetrics.toolbarItemSpacing
        return min(barWidth - LibraryGlassDesign.barMenuRowHorizontal, reserve + navigationChrome)
    }
}
