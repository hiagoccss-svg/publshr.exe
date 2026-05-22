import SwiftUI

/// Universal submenu column (channels, spaces tree) beside the bar menu.
struct AppSecondarySidebar: View {
    var module: AppModule
    @ObservedObject var chat: ChatViewModel
    @ObservedObject var spaces: SpacesViewModel
    @Binding var showNewChannel: Bool
    @Binding var showNewDM: Bool

    private var columnWidth: CGFloat {
        switch module {
        case .chat: ChatClickUpDesign.sidebarWidth
        case .spaces: SpacesClickUpDesign.sidebarWidth
        case .settings: LibraryGlassDesign.sidebarWidth
        }
    }

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
        .frame(width: columnWidth)
    }
}
