import SwiftUI

/// Legacy per-column header — live shell uses `ShellUnifiedTitlebar` for all titlebar controls.
struct PrimaryBarTrafficHeader: View {
    var body: some View {
        Color.clear
            .frame(height: TrafficLightLayoutStore.shared.rowHeight)
            .frame(width: CursorMacShellDesign.barMenuIconRailWidth)
    }
}
