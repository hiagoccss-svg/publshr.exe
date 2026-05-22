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
            Button {
                chat.toggleSidebarPin(for: channel)
            } label: {
                Label(
                    chat.isSidebarPinned(channel) ? "Unpin from sidebar" : "Pin to sidebar",
                    systemImage: chat.isSidebarPinned(channel) ? "pin.slash" : "pin"
                )
            }
            Button {
                chat.markChannelRead(channel)
            } label: {
                Label("Mark as read", systemImage: "checkmark.circle")
            }
            Button {
                chat.markChannelUnread(channel)
            } label: {
                Label("Mark as unread", systemImage: "envelope.badge")
            }
            Button {
                chat.copyChannelLink(channel)
            } label: {
                Label("Copy link", systemImage: "link")
            }
            Button {
                Task { await chat.muteChannel(channel) }
            } label: {
                Label("Mute notifications", systemImage: "bell.slash")
            }
            Divider()
            Button {
                chat.showAISheet = true
            } label: {
                Label("Script recap (date range)", systemImage: "doc.text.magnifyingglass")
            }
            Button { chat.openChannelSearch() } label: {
                Label("Search in channel", systemImage: "magnifyingglass")
            }
            if chat.permissions.canExportChats {
                Button {
                    Task { await chat.exportSelectedChannel() }
                } label: {
                    Label("Export transcript", systemImage: "square.and.arrow.up")
                }
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
