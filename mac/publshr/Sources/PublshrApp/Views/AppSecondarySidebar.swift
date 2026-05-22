import SwiftUI

/// Universal submenu column (channels, spaces tree) beside the bar menu.
/// Width is owned by `LibraryUniversalSubmenuContainer` inside each module sidebar.
struct AppSecondarySidebar: View {
    var module: AppModule
    @ObservedObject var chat: ChatViewModel
    @ObservedObject var spaces: SpacesViewModel
    @Binding var showNewChannel: Bool
    @Binding var showNewDM: Bool

    var body: some View {
        Group {
            switch module {
            case .chat:
                ChatSidebarView(
                    chat: chat,
                    showNewChannel: $showNewChannel,
                    showNewDM: $showNewDM
                )
            case .spaces:
                SpacesNavSidebar(spaces: spaces)
            case .mediaMonitoring, .planner:
                EmptyView()
            case .settings:
                EmptyView()
            }
        }
        .frame(minHeight: 0, maxHeight: .infinity)
    }
}
