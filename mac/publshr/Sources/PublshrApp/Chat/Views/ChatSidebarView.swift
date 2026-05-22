import SwiftUI

struct ChatSidebarView: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var calls: CallSignalingService
    @EnvironmentObject private var subscription: SubscriptionService
    @ObservedObject var chat: ChatViewModel
    @Binding var showNewChannel: Bool
    @Binding var showNewDM: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    sidebarSection("Favorites", items: chat.favoriteChannels, onAdd: nil)
                    sidebarSection("Channels", items: chat.filteredChannels, onAdd: { showNewChannel = true })
                    sidebarSection("Direct Messages", items: chat.filteredDMs, onAdd: { showNewDM = true })
                    projectsSection
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 2)
            }
        }
        .frame(maxHeight: .infinity)
        .preferredColorScheme(.light)
    }

    private var projectsSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            sectionHeader("Projects", onAdd: nil)

            if chat.filteredProjects.isEmpty {
                Text("No planner tasks")
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundDim)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
            } else {
                ForEach(chat.filteredProjects) { task in
                    Button {
                        Task { await chat.sharePlannerTask(task) }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "folder")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(CursorTheme.foregroundMuted)
                                .frame(width: 14)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(task.title)
                                    .font(.system(size: 12))
                                    .foregroundStyle(CursorTheme.foregroundMuted)
                                    .lineLimit(1)
                                Text(task.status)
                                    .font(.system(size: 10))
                                    .foregroundStyle(CursorTheme.foregroundDim)
                            }
                            Spacer(minLength: 0)
                        }
                        .frame(height: 28)
                        .padding(.horizontal, 10)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 6)
                }
            }
        }
    }

    private func sidebarSection(
        _ title: String,
        items: [ChatChannel],
        onAdd: (() -> Void)?
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            sectionHeader(title, onAdd: onAdd)

            if items.isEmpty {
                Text("None yet")
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundDim)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
            } else {
                ForEach(items) { channel in
                    channelRow(channel)
                }
            }
        }
    }

    private func sectionHeader(_ title: String, onAdd: (() -> Void)?) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(CursorTheme.foregroundDim)
                .tracking(0.45)
            Spacer()
            if let onAdd {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(CursorTheme.foregroundMuted)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 3)
    }

    private func channelRow(_ channel: ChatChannel) -> some View {
        let selected = chat.selectedChannel?.id == channel.id
        let unread = chat.unreadByChannel[channel.id] ?? 0
        return HStack(spacing: 0) {
            Button {
                tabStore.openFromChannel(channel)
                chat.selectChannel(channel)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: channel.sidebarIcon)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(selected ? CursorTheme.accent : CursorTheme.foregroundMuted)
                        .frame(width: 14)
                    Text(dmTitle(channel))
                        .font(.system(size: 12, weight: unread > 0 ? .semibold : .regular))
                        .foregroundStyle(selected ? CursorTheme.foreground : CursorTheme.foregroundMuted)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    if unread > 0 {
                        Text("\(unread)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(CursorTheme.accent)
                            .clipShape(Capsule())
                    }
                }
                .frame(height: 30)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(selected ? Color.white : Color.clear)
                        .shadow(color: selected ? Color.black.opacity(0.04) : .clear, radius: 4, y: 1)
                )
            }
            .buttonStyle(.plain)

            channelRowMenu(channel)
        }
        .padding(.horizontal, 6)
        .contextMenu { channelContextMenu(channel) }
    }

    private func channelRowMenu(_ channel: ChatChannel) -> some View {
        Menu {
            channelContextMenu(channel)
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 11))
                .foregroundStyle(CursorTheme.foregroundDim)
                .frame(width: 24, height: 30)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }

    @ViewBuilder
    private func channelContextMenu(_ channel: ChatChannel) -> some View {
        Button {
            tabStore.openFromChannel(channel)
            chat.selectChannel(channel)
        } label: {
            Label("Open", systemImage: "bubble.left.and.bubble.right")
        }
        Button {
            ChatWindowManager.shared.openChannel(channel, chat: chat, auth: auth)
        } label: {
            Label("Open in new window", systemImage: "arrow.up.forward.square")
        }
        if subscription.canUseCalls(workspace: auth.selectedWorkspace) {
            Divider()
            Menu("Voice call") {
                Button("Private") { startCall(channel: channel, video: false, scope: .private) }
                Button("Meeting") { startCall(channel: channel, video: false, scope: .meeting) }
            }
            Menu("Video call") {
                Button("Private") { startCall(channel: channel, video: true, scope: .private) }
                Button("Meeting") { startCall(channel: channel, video: true, scope: .meeting) }
            }
        }
        Divider()
        Button { chat.showPermissionsSheet = true } label: {
            Label("Channel settings", systemImage: "gearshape")
        }
        Button { chat.showSearchSheet = true } label: {
            Label("Search", systemImage: "magnifyingglass")
        }
    }

    private func startCall(channel: ChatChannel, video: Bool, scope: CallScope) {
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

    private func dmTitle(_ channel: ChatChannel) -> String {
        if channel.kind == .dm {
            return channel.description?.replacingOccurrences(of: "Direct message with ", with: "") ?? "Direct Message"
        }
        return channel.displayTitle
    }
}
