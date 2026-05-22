import SwiftUI

/// Shared channel actions menu — same items in sidebar row menu and conversation toolbar.
struct ChatChannelActionsMenu: View {
    @EnvironmentObject private var auth: AuthViewModel
    @ObservedObject var chat: ChatViewModel
    let channel: ChatChannel
    var onOpen: (() -> Void)?

    var body: some View {
        Group {
            Button {
                onOpen?()
                chat.selectChannel(channel)
            } label: {
                Label("Open", systemImage: "bubble.left.and.bubble.right")
            }
            Button {
                ChatWindowManager.shared.openChannel(channel, chat: chat, auth: auth)
            } label: {
                Label("Open in new window", systemImage: "arrow.up.forward.square")
            }
            Divider()
            Button { chat.showSearchSheet = true } label: {
                Label("Search in channel", systemImage: "magnifyingglass")
            }
            Button {
                chat.showPinnedPanel.toggle()
            } label: {
                Label(
                    chat.showPinnedPanel ? "Hide pinned" : "Pinned messages",
                    systemImage: chat.showPinnedPanel ? "pin.fill" : "pin"
                )
            }
            Divider()
            Button {
                chat.selectChannel(channel)
                chat.showChannelSettings = true
            } label: {
                Label("Channel settings", systemImage: "gearshape")
            }
            if auth.selectedMembership?.role.canManageWorkspace == true {
                Button {
                    chat.showPermissionsSheet = true
                } label: {
                    Label("Workspace permissions", systemImage: "lock.shield")
                }
            }
        }
    }
}
