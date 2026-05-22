import SwiftUI

/// ClickUp-style chat sidebar: search, filters (All / Unread / DMs / Channels), Organized vs Recents.
struct ChatSidebarView: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @EnvironmentObject private var calls: CallSignalingService
    @ObservedObject var chat: ChatViewModel
    @Binding var showNewChannel: Bool
    @Binding var showNewDM: Bool

    var body: some View {
        VStack(spacing: 0) {
            sidebarHeader
            sidebarSearch
            filterBar
            Divider().overlay(CursorTheme.hairline)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if chat.sidebarLayout == .recents {
                        recentsContent
                    } else {
                        organizedContent
                    }
                    if !chat.filteredProjects.isEmpty || chat.sidebarSearchQuery.isEmpty {
                        plannerSection
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 4)
            }

            Divider().overlay(CursorTheme.hairline)
            layoutFooter
        }
        .frame(maxHeight: .infinity)
        .preferredColorScheme(.light)
    }

    // MARK: - Header

    private var sidebarHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(CursorTheme.accent)
            Text("Chat")
                .font(ChatClickUpDesign.sidebarTitleFont)
                .foregroundStyle(CursorTheme.foreground)
            Spacer()
            Menu {
                Button {
                    showNewChannel = true
                } label: {
                    Label("New channel", systemImage: "number")
                }
                Button {
                    showNewDM = true
                } label: {
                    Label("New message", systemImage: "person.badge.plus")
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(CursorTheme.accent)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
        }
        .padding(.horizontal, ChatClickUpDesign.horizontalPadding)
        .frame(height: ChatClickUpDesign.headerHeight)
    }

    // MARK: - Search

    private var sidebarSearch: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(CursorTheme.foregroundDim)
            TextField("Search channels and people", text: $chat.sidebarSearchQuery)
                .textFieldStyle(.plain)
                .font(ChatClickUpDesign.searchFont)
                .foregroundStyle(CursorTheme.foreground)
            if !chat.sidebarSearchQuery.isEmpty {
                Button {
                    chat.sidebarSearchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(CursorTheme.foregroundDim)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: ChatClickUpDesign.searchHeight)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(CursorTheme.panelBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(CursorTheme.borderSubtle, lineWidth: 1)
        )
        .padding(.horizontal, ChatClickUpDesign.horizontalPadding)
        .padding(.bottom, 8)
    }

    // MARK: - Filters

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ChatSidebarFilter.allCases) { filter in
                    filterPill(filter)
                }
            }
            .padding(.horizontal, ChatClickUpDesign.horizontalPadding)
        }
        .frame(height: ChatClickUpDesign.filterBarHeight)
        .padding(.bottom, 4)
    }

    private func filterPill(_ filter: ChatSidebarFilter) -> some View {
        let selected = chat.sidebarFilter == filter
        return Button {
            if selected, filter != .all {
                chat.setSidebarFilter(.all)
            } else {
                chat.setSidebarFilter(filter)
            }
        } label: {
            Text(filter.label)
                .font(ChatClickUpDesign.filterFont)
                .foregroundStyle(selected ? Color.white : CursorTheme.foregroundMuted)
                .padding(.horizontal, ChatClickUpDesign.filterPillHPadding)
                .frame(height: ChatClickUpDesign.filterPillHeight)
                .background(
                    Capsule(style: .continuous)
                        .fill(selected ? CursorTheme.accent : CursorTheme.panelBackground)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(selected ? Color.clear : CursorTheme.borderSubtle, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content

    private var organizedContent: some View {
        Group {
            if chat.sidebarFilter != .dms {
                sidebarSection("Channels", items: chat.filteredChannels, onAdd: { showNewChannel = true })
                NavSidebarDivider()
            }
            if chat.sidebarFilter != .channels {
                sidebarSection("Direct Messages", items: chat.filteredDMs, onAdd: { showNewDM = true })
            }
        }
    }

    private var recentsContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            sectionHeader("Recent", onAdd: nil)
            if chat.sidebarRecentsList.isEmpty {
                emptyHint
            } else {
                ForEach(chat.sidebarRecentsList) { channel in
                    channelRow(channel)
                }
            }
        }
    }

    private var plannerSection: some View {
        Group {
            NavSidebarDivider()
            VStack(alignment: .leading, spacing: 2) {
                sectionHeader("Planner", onAdd: nil)
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
                                Image(systemName: "checklist")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(CursorTheme.foregroundMuted)
                                    .frame(width: ChatClickUpDesign.rowIconSize)
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
                            .frame(height: ChatClickUpDesign.rowHeight)
                            .padding(.horizontal, 10)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 6)
                    }
                }
            }
        }
    }

    private var emptyHint: some View {
        Text("No conversations match this filter")
            .font(.system(size: 11))
            .foregroundStyle(CursorTheme.foregroundDim)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
    }

    // MARK: - Layout footer (Organized / Recents)

    private var layoutFooter: some View {
        HStack(spacing: 0) {
            layoutToggle(.organized, icon: "list.bullet.rectangle")
            layoutToggle(.recents, icon: "clock")
            Spacer()
            Text(chat.sidebarLayout.label)
                .font(ChatClickUpDesign.footerFont)
                .foregroundStyle(CursorTheme.foregroundDim)
        }
        .padding(.horizontal, ChatClickUpDesign.horizontalPadding)
        .frame(height: ChatClickUpDesign.footerHeight)
        .background(CursorTheme.panelBackground.opacity(0.5))
    }

    private func layoutToggle(_ layout: ChatSidebarLayout, icon: String) -> some View {
        let selected = chat.sidebarLayout == layout
        return Button {
            chat.setSidebarLayout(layout)
        } label: {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(selected ? CursorTheme.accent : CursorTheme.foregroundDim)
                .frame(width: 36, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(selected ? CursorTheme.accent.opacity(0.1) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .help(layout == .organized ? "Group channels and DMs" : "Sort by recent activity")
    }

    // MARK: - Sections & rows

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
        .padding(.top, ChatClickUpDesign.sectionTop)
        .padding(.bottom, ChatClickUpDesign.sectionBottom)
    }

    private func channelRow(_ channel: ChatChannel) -> some View {
        let selected = chat.selectedChannel?.id == channel.id
        let unread = chat.unreadCount(for: channel.id)
        let bold = chat.isSidebarRowBold(channel)
        let threadUnread = chat.hasUnreadThreadReplies(for: channel.id)

        return HStack(spacing: 0) {
            Button {
                tabStore.openFromChannel(channel)
                chat.selectChannel(channel)
            } label: {
                HStack(spacing: 8) {
                    ChatChannelIconView(channel: channel, size: ChatClickUpDesign.rowIconSize)
                    Text(channel.sidebarTitle)
                        .font(bold || selected ? SpacesClickUpDesign.treeRowSelectedFont : SpacesClickUpDesign.treeRowFont)
                        .foregroundStyle(selected ? CursorTheme.foreground : CursorTheme.foregroundMuted)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    HStack(spacing: 4) {
                        if threadUnread {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(CursorTheme.accent)
                                .help("Unread thread replies")
                        }
                        if let live = calls.liveCall(for: channel.id), !calls.isInCall(on: channel.id) {
                            LiveCallChannelBadge(summary: live)
                        } else if unread > 0 {
                            Text(unread > 99 ? "99+" : "\(unread)")
                                .font(ChatClickUpDesign.unreadBadgeFont)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(CursorTheme.accent)
                                .clipShape(Capsule())
                        }
                    }
                }
                .frame(height: ChatClickUpDesign.rowHeight)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: ChatClickUpDesign.rowRadius, style: .continuous)
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
                .frame(width: 24, height: ChatClickUpDesign.rowHeight)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }
}
