import SwiftUI

/// Aligns bar-column body content with the unified titlebar row (traffic lights in column 1 title band).
enum ShellBarColumnInset {
    /// Width reserved for the traffic-light cluster inside column 1 titlebar.
    static func trafficReserve(barWidth: CGFloat, trafficLeadingInset: CGFloat) -> CGFloat {
        min(trafficLeadingInset, max(0, barWidth - AppWindowChromeMetrics.controlSize))
    }
}
