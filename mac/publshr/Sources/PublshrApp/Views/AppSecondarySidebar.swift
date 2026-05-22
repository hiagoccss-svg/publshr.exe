import SwiftUI

/// Secondary nav column (channels, spaces) — starts directly under the unified title bar.
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
            case .settings:
                EmptyView()
            }
        }
        .frame(maxHeight: .infinity)
        .frame(width: module == .spaces ? SpacesClickUpDesign.sidebarWidth : ChatClickUpDesign.sidebarWidth)
        .glassSidebar()
    }
}
