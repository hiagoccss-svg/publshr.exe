import SwiftUI

/// First-column title band — traffic-light reserve only (shell toggles live in `ShellUnifiedTitlebar`).
struct PrimaryBarTrafficHeader: View {
    var body: some View {
        TitlebarToolbarRow(leadingPadding: 10, trailingPadding: 6) {
            Color.clear
                .frame(width: AppWindowChromeMetrics.trafficLightLeadingInset)
                .accessibilityHidden(true)
        }
        .trafficToolbarAligned()
        .frame(width: CursorMacShellDesign.barMenuIconRailWidth)
    }
}
