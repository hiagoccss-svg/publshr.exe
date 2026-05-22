import SwiftUI

/// White secondary column (channels, spaces) — full window height, like Cursor.
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
        .frame(width: CursorTheme.navSidebarWidth)
        .frame(maxHeight: .infinity)
        .background(sidebarBackground)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(CursorTheme.border.opacity(0.4))
                .frame(width: 1)
        }
    }

    @ViewBuilder
    private var sidebarBackground: some View {
        if module == .chat {
            ChatNavSidebarBackground()
        } else {
            CursorTheme.navSidebar
        }
    }
}
