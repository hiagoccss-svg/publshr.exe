import SwiftUI

/// Shared channel actions menu — sidebar row and conversation toolbar.
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
            Button {
                chat.toggleStar(channel)
            } label: {
                Label(
                    chat.isStarred(channel) ? "Remove from favorites" : "Add to favorites",
                    systemImage: chat.isStarred(channel) ? "star.fill" : "star"
                )
            }
            Button {
                Task { await chat.setChannelMuted(channel, muted: !chat.isChannelMuted(channel)) }
            } label: {
                Label(
                    chat.isChannelMuted(channel) ? "Unmute notifications" : "Mute notifications",
                    systemImage: chat.isChannelMuted(channel) ? "bell" : "bell.slash"
                )
            }
            .disabled(chat.membershipByChannel[channel.id] == nil)
            Button {
                chat.markChannelRead(channel)
            } label: {
                Label("Mark as read", systemImage: "checkmark.message")
            }
            Divider()
            Button { chat.openWorkspaceSearch(scope: .channel) } label: {
                Label("Search in channel", systemImage: "magnifyingglass")
            }
            Button { chat.openWorkspaceSearch(scope: .workspace) } label: {
                Label("Search workspace", systemImage: "text.magnifyingglass")
            }
            Button {
                chat.showPinnedPanel.toggle()
            } label: {
                Label(
                    chat.showPinnedPanel ? "Hide pinned" : "Pinned messages",
                    systemImage: chat.showPinnedPanel ? "pin.fill" : "pin"
                )
            }
        }
    }
}
