import SwiftUI

/// White secondary column (channels, spaces, settings nav) — full window height, like Cursor.
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
                    SettingsNavSidebar()
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(width: module == .spaces ? SpacesClickUpDesign.sidebarWidth : CursorTheme.navSidebarWidth)
        .frame(maxHeight: .infinity)
        .background(CursorTheme.navSidebar)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(CursorTheme.border.opacity(0.35))
                .frame(width: 1)
        }
    }
}

/// Settings module — compact nav in the white column.
private struct SettingsNavSidebar: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sidebarHeader("Settings")
            VStack(alignment: .leading, spacing: 2) {
                navRow("App updates", icon: "arrow.down.circle")
                navRow("Account", icon: "person.circle")
                navRow("Workspace", icon: "building.2")
                navRow("Security", icon: "lock.shield")
                navRow("Chat", icon: "bubble.left.and.bubble.right")
            }
            .padding(.horizontal, 8)
            Spacer()
        }
    }

    private func sidebarHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(CursorTheme.foregroundDim)
            .tracking(0.6)
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 8)
    }

    private func navRow(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundMuted)
                .frame(width: 16)
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundMuted)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
}
