import SwiftUI

/// First-column title band — sidebar toggle under traffic lights; module icons in the rail below.
struct PrimaryBarTrafficHeader: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore

    var body: some View {
        TitlebarToolbarRow(leadingPadding: 10, trailingPadding: 6) {
            TitlebarChromeIconButton(
                systemName: tabStore.sidebarExpanded ? "sidebar.left" : "sidebar.right",
                help: tabStore.sidebarExpanded
                    ? "Hide chat/spaces submenu"
                    : "Show chat/spaces submenu",
                isActive: !tabStore.sidebarExpanded
            ) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    tabStore.sidebarExpanded.toggle()
                }
            }
        }
        .trafficToolbarAligned()
        .frame(width: CursorMacShellDesign.barMenuIconRailWidth)
    }
}
