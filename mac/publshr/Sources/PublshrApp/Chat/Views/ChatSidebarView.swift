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
                VStack(alignment: .leading, spacing: 0) {
                    sidebarSection("Favorites", items: chat.favoriteChannels, onAdd: nil)
                    NavSidebarDivider()
                    sidebarSection("Channels", items: chat.filteredChannels, onAdd: { showNewChannel = true })
                    NavSidebarDivider()
                    sidebarSection("Direct Messages", items: chat.filteredDMs, onAdd: { showNewDM = true })
                    NavSidebarDivider()
                    projectsSection
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
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
                                .frame(width: SpacesClickUpDesign.sidebarIconWidth)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(task.title)
                                    .font(SpacesClickUpDesign.treeRowFont)
                                    .foregroundStyle(CursorTheme.foregroundMuted)
                                    .lineLimit(1)
                                Text(task.status)
                                    .font(.system(size: 10))
                                    .foregroundStyle(CursorTheme.foregroundDim)
                            }
                            Spacer(minLength: 0)
                        }
                        .frame(height: SpacesClickUpDesign.sidebarRowHeight)
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
                .font(SpacesClickUpDesign.sectionLabelFont)
                .foregroundStyle(CursorTheme.foregroundDim)
                .tracking(0.5)
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
        .padding(.horizontal, SpacesClickUpDesign.sidebarHorizontalPadding + 2)
        .padding(.top, SpacesClickUpDesign.sidebarSectionTop)
        .padding(.bottom, SpacesClickUpDesign.sidebarSectionBottom)
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
                    ChatChannelIconView(channel: channel, size: SpacesClickUpDesign.sidebarIconWidth)
                    Text(channel.sidebarTitle)
                        .font(selected ? SpacesClickUpDesign.treeRowSelectedFont : SpacesClickUpDesign.treeRowFont)
                        .foregroundStyle(selected ? CursorTheme.foreground : CursorTheme.foregroundMuted)
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
                            .background(CursorTheme.accent)
                            .clipShape(Capsule())
                    }
                }
                .frame(height: SpacesClickUpDesign.sidebarRowHeight)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: SpacesClickUpDesign.sidebarRowRadius, style: .continuous)
                        .fill(selected ? CursorTheme.accent.opacity(0.08) : Color.clear)
                )
            }
            .buttonStyle(.plain)

            channelRowMenu(channel)
        }
        .padding(.horizontal, 6)
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
                .foregroundStyle(CursorTheme.foregroundDim)
                .frame(width: 24, height: SpacesClickUpDesign.sidebarRowHeight)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }
}
