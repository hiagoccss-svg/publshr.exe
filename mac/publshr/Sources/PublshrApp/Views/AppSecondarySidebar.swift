import SwiftUI

/// Universal submenu column (channels, spaces tree) beside the bar menu.
/// Width is owned by `LibraryUniversalSubmenuContainer` inside each module sidebar.
struct AppSecondarySidebar: View {
    var submenuWidth: CGFloat
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
                    showNewDM: $showNewDM,
                    submenuWidth: submenuWidth
                )
            case .spaces:
                SpacesNavSidebar(spaces: spaces, submenuWidth: submenuWidth)
            case .settings:
                EmptyView()
            }
        }
        .frame(width: submenuWidth, alignment: .leading)
        .frame(minHeight: 0, maxHeight: .infinity)
    }
}
