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
        LibraryUniversalSubmenuContainer {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        sidebarSection("Favorites", items: chat.favoriteChannels, onAdd: nil)
                        LibraryUniversalSubmenu.sectionDivider()
                        sidebarSection("Channels", items: chat.filteredChannels, onAdd: { showNewChannel = true })
                        LibraryUniversalSubmenu.sectionDivider()
                        sidebarSection("Direct Messages", items: chat.filteredDMs, onAdd: { showNewDM = true })
                        LibraryUniversalSubmenu.sectionDivider()
                        projectsSection
                    }
                    .padding(.vertical, 8)
                    .padding(.top, 4)
                }
            }
        } footer: {
            HStack {
                Button {
                    chat.showSearchSheet = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundStyle(LibraryGlassDesign.inkSecondary)
                }
                .buttonStyle(.plain)
                .help("Search")

                Spacer()

                if chat.totalUnread > 0 {
                    Text("\(chat.totalUnread) unread")
                        .font(.system(size: 10))
                        .foregroundStyle(LibraryGlassDesign.inkMuted)
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private var projectsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            LibraryUniversalSubmenu.sectionHeader("Projects")

            if chat.filteredProjects.isEmpty {
                Text("No planner tasks")
                    .font(.system(size: 11))
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
            } else {
                ForEach(chat.filteredProjects) { task in
                    LibraryUniversalSubmenu.row(
                        title: task.title,
                        icon: "folder",
                        trailing: task.status,
                        selected: false
                    ) {
                        Task { await chat.sharePlannerTask(task) }
                    }
                }
            }
        }
    }

    private func sidebarSection(
        _ title: String,
        items: [ChatChannel],
        onAdd: (() -> Void)?
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            LibraryUniversalSubmenu.sectionHeader(title, onAdd: onAdd)

            if items.isEmpty {
                Text("None yet")
                    .font(.system(size: 11))
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
            } else {
                ForEach(items) { channel in
                    channelRow(channel)
                }
            }
        }
    }

    private func channelRow(_ channel: ChatChannel) -> some View {
        let selected = chat.selectedChannel?.id == channel.id
        let unread = chat.unreadByChannel[channel.id] ?? 0
        let trailing = LibraryRelativeTime.string(since: channel.lastMessageAt)

        return HStack(spacing: 0) {
            Button {
                tabStore.openFromChannel(channel)
                chat.selectChannel(channel)
            } label: {
                HStack(spacing: 8) {
                    ChatChannelIconView(channel: channel, size: SpacesClickUpDesign.sidebarIconWidth)
                    Text(channel.sidebarTitle)
                        .font(.system(size: 13, weight: selected ? .semibold : .regular))
                        .foregroundStyle(selected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    if let live = calls.liveCall(for: channel.id), !calls.isInCall(on: channel.id) {
                        LiveCallChannelBadge(summary: live)
                    } else if unread > 0 {
                        Text("\(unread)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(LibraryGlassDesign.primaryCTA)
                            .clipShape(Capsule())
                    } else if let trailing {
                        Text(trailing)
                            .font(.system(size: 11))
                            .foregroundStyle(LibraryGlassDesign.inkMuted)
                    }
                }
                .padding(.horizontal, LibraryGlassDesign.sidebarRowHorizontal)
                .padding(.vertical, LibraryGlassDesign.sidebarRowVertical + 1)
                .background(
                    RoundedRectangle(cornerRadius: LibraryGlassDesign.sidebarRowRadius, style: .continuous)
                        .fill(selected ? LibraryGlassDesign.sidebarSelection : Color.clear)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 6)

            channelRowMenu(channel)
        }
        .contextMenu {
            ChatChannelActionsMenu(chat: chat, channel: channel) {
                tabStore.openFromChannel(channel)
            }
        }
    }

    private func channelRowMenu(_ channel: ChatChannel) -> some View {
        Menu {
            ChatChannelActionsMenu(chat: chat, channel: channel) {
                tabStore.openFromChannel(channel)
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 11))
                .foregroundStyle(LibraryGlassDesign.inkMuted)
                .frame(width: 24, height: SpacesClickUpDesign.sidebarRowHeight)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }
}
