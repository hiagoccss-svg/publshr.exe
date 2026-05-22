import SwiftUI

/// White secondary column (channels, spaces) — aligned below the workspace header.
struct AppSecondarySidebar: View {
    var module: AppModule
    @ObservedObject var chat: ChatViewModel
    @ObservedObject var spaces: SpacesViewModel
    @Binding var showNewChannel: Bool
    @Binding var showNewDM: Bool
    var topInset: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: topInset)

            Color.clear
                .frame(height: CursorTheme.workspaceHeaderHeight)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(CursorTheme.hairline)
                        .frame(height: 1)
                }

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
        }
        .frame(width: module == .spaces ? SpacesClickUpDesign.sidebarWidth : CursorTheme.navSidebarWidth)
        .frame(maxHeight: .infinity)
        .background(CursorTheme.navSidebar)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(CursorTheme.hairline)
                .frame(width: 1)
        }
    }
}
