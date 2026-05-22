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
                    chat.isStarred(channel) ? "Remove from pinned" : "Pin to sidebar",
                    systemImage: chat.isStarred(channel) ? "pin.fill" : "pin"
                )
            }
            if chat.isFollowing(channel) {
                Button {
                    chat.toggleFollow(channel)
                } label: {
                    Label("Unfollow", systemImage: "bell.badge")
                }
            } else {
                Button {
                    chat.toggleFollow(channel)
                } label: {
                    Label("Follow", systemImage: "bell")
                }
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
            Button {
                chat.markChannelUnread(channel)
            } label: {
                Label("Mark as unread", systemImage: "envelope.badge")
            }
            if channel.kind == .channel {
                Button {
                    chat.beginRenameChannel(channel)
                } label: {
                    Label("Rename channel…", systemImage: "pencil")
                }
            }
            if channel.kind == .dm || channel.kind == .group {
                Button(role: .destructive) {
                    chat.closeDirectMessage(channel)
                } label: {
                    Label("Close conversation", systemImage: "xmark.circle")
                }
            }
            Divider()
            Button {
                chat.copyChannelLink(channel)
            } label: {
                Label("Copy link", systemImage: "link")
            }
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
