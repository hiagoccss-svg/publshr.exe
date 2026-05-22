import SwiftUI

/// Shared channel actions menu — same items in sidebar row menu and conversation toolbar.
struct ChatChannelActionsMenu: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var subscription: SubscriptionService
    @EnvironmentObject private var calls: CallSignalingService
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
            if let live = calls.liveCall(for: channel.id), !calls.isInCall(on: channel.id) {
                Button {
                    Task { await calls.joinActiveCall(for: channel.id) }
                } label: {
                    Label("Join live call (\(live.participantCount))", systemImage: "phone.badge.plus")
                }
                Divider()
            }
            if subscription.canUseCalls(workspace: auth.selectedWorkspace) {
                Menu("Voice call") {
                    Button("Private") { startCall(video: false, scope: .private) }
                    Button("Meeting") { startCall(video: false, scope: .meeting) }
                }
                Menu("Video call") {
                    Button("Private") { startCall(video: true, scope: .private) }
                    Button("Meeting") { startCall(video: true, scope: .meeting) }
                }
                Divider()
            }
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
        }
    }

    private func startCall(video: Bool, scope: CallScope) {
        guard let ws = auth.selectedWorkspace?.id else { return }
        chat.selectChannel(channel)
        Task {
            await calls.startChannelCall(
                workspaceId: ws,
                channelId: channel.id,
                title: channel.displayTitle,
                video: video,
                scope: scope,
                workspaceSettings: auth.selectedWorkspace?.settings,
                userDisplayName: auth.profile?.displayName ?? auth.displayName
            )
        }
    }
}
