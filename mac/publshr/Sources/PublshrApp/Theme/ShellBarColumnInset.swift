import SwiftUI

/// Aligns bar-column body content with the unified titlebar row (traffic lights + optional back/forward).
enum ShellBarColumnInset {
    /// Width reserved for the traffic-light cluster inside column 1 (matches `ShellUnifiedTitlebar.leadingBand`).
    static func trafficReserve(barWidth: CGFloat, trafficLeadingInset: CGFloat) -> CGFloat {
        min(trafficLeadingInset, max(0, barWidth - AppWindowChromeMetrics.controlSize))
    }

    /// Leading padding for bar-menu body rows — clear the traffic-light cluster only.
    /// Back/forward live in the unified titlebar row above; double-reserving their width crushed module labels.
    static func bodyLeadingPadding(
        barWidth: CGFloat,
        expanded: Bool,
        trafficLeadingInset: CGFloat
    ) -> CGFloat {
        let reserve = trafficReserve(barWidth: barWidth, trafficLeadingInset: trafficLeadingInset)
        let minimum = LibraryGlassDesign.barMenuRowHorizontal
        if expanded {
            return min(barWidth - minimum, max(minimum, reserve))
        }
        return max(minimum, reserve)
    }
}
