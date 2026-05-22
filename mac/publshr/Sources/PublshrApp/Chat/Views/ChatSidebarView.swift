import SwiftUI

/// Universal submenu for chat — search, filters, channels/DMs/recents (ClickUp) in library glass chrome.
struct ChatSidebarView: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @ObservedObject var chat: ChatViewModel
    @Binding var showNewChannel: Bool
    @Binding var showNewDM: Bool

    var body: some View {
        LibraryUniversalSubmenuContainer(width: LibraryUniversalSubmenu.width) {
            VStack(spacing: 0) {
                if chat.sidebarHub == .channels {
                    filterBar
                    submenuSoftRule
                }

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ChatSidebarHubStrip(chat: chat)
                        hubContent
                        if chat.sidebarHub == .channels {
                            if chat.sidebarLayout == .recents {
                                recentsContent
                            } else {
                                organizedContent
                            }
                            if !chat.filteredProjects.isEmpty || chat.sidebarSearchQuery.isEmpty {
                                plannerSection
                            }
                        }
                    }
                    .padding(.bottom, 4)
                }
                .frame(minHeight: 0, maxHeight: .infinity)
            }
            .frame(minHeight: 0, maxHeight: .infinity)
        } footer: {
            layoutFooter
        }
        .preferredColorScheme(.light)
        .onAppear { normalizeSidebarFilterIfNeeded() }
    }

    private var submenuSoftRule: some View {
        Rectangle()
            .fill(LibraryGlassDesign.contentDivider.opacity(0.55))
            .frame(height: 1)
            .padding(.horizontal, 12)
    }

    private func normalizeSidebarFilterIfNeeded() {
        let hasData = !chat.channels.isEmpty || !chat.directMessages.isEmpty
        let filteredEmpty = chat.filteredChannels.isEmpty && chat.filteredDMs.isEmpty
        if hasData, filteredEmpty, chat.sidebarFilter != .all {
            chat.setSidebarFilter(.all)
        }
    }

    // MARK: - Filters (ClickUp: tap again to clear; flat on chrome)

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(ChatSidebarFilter.allCases) { filter in
                    filterPill(filter)
                }
            }
            .padding(.horizontal, 12)
        }
        .frame(height: ChatClickUpDesign.filterBarHeight)
        .clipped()
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
                .font(.system(size: 11, weight: selected ? .semibold : .medium))
                .foregroundStyle(selected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkMuted)
                .overlay(alignment: .bottom) {
                    if selected {
                        Rectangle()
                            .fill(LibraryGlassDesign.ink.opacity(0.35))
                            .frame(height: 1)
                            .offset(y: 5)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content

    @ViewBuilder
    private var hubContent: some View {
        switch chat.sidebarHub {
        case .channels:
            EmptyView()
        case .activity:
            ChatActivityHubView(chat: chat)
        case .drafts:
            ChatDraftsHubView(chat: chat)
        case .sent:
            ChatSentHubView(chat: chat)
        }
    }

    private var organizedContent: some View {
        Group {
            if chat.sidebarFilter == .pinned {
                sidebarSection("Pinned", items: chat.filteredChannels + chat.filteredDMs, onAdd: nil)
            } else {
                if chat.sidebarFilter == .all, !chat.pinnedSidebarChannels.isEmpty {
                    sidebarSection("Pinned", items: chat.pinnedSidebarChannels, onAdd: nil)
                    LibraryUniversalSubmenu.sectionDivider()
                }
                if chat.sidebarFilter != .dms {
                    sidebarSection(
                        "Channels",
                        items: chat.filteredChannels.filter { !chat.isSidebarPinned($0) },
                        onAdd: { showNewChannel = true }
                    )
                    LibraryUniversalSubmenu.sectionDivider()
                }
                if chat.sidebarFilter != .channels {
                    sidebarSection(
                        "Direct Messages",
                        items: chat.filteredDMs.filter { !chat.isSidebarPinned($0) },
                        onAdd: { showNewDM = true }
                    )
                }
            }
        }
    }

    private var recentsContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            LibraryUniversalSubmenu.sectionHeader("Recent")
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
            LibraryUniversalSubmenu.sectionDivider()
            VStack(alignment: .leading, spacing: 0) {
                LibraryUniversalSubmenu.sectionHeader("Planner")
                if chat.filteredProjects.isEmpty {
                    Text("No planner tasks")
                        .font(.system(size: 11))
                        .foregroundStyle(LibraryGlassDesign.inkMuted)
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
                                    .foregroundStyle(LibraryGlassDesign.inkSecondary)
                                    .frame(width: ChatClickUpDesign.rowIconSize)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(task.title)
                                        .font(.system(size: 12))
                                        .foregroundStyle(LibraryGlassDesign.inkSecondary)
                                        .lineLimit(1)
                                    Text(task.status)
                                        .font(.system(size: 10))
                                        .foregroundStyle(LibraryGlassDesign.inkMuted)
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
            .foregroundStyle(LibraryGlassDesign.inkMuted)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
    }

    /// ClickUp: Organized / Recents lower-left; plus + settings gear; flat compose rows.
    private var layoutFooter: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                layoutToggle(.organized, icon: "list.bullet.rectangle", label: "Organized")
                layoutToggle(.recents, icon: "clock", label: "Recents")
                Spacer(minLength: 0)
                Menu {
                    if chat.permissions.canCreateChannels {
                        Button { showNewChannel = true } label: {
                            Label("New channel", systemImage: "number")
                        }
                    }
                    if chat.permissions.canDM {
                        Button { showNewDM = true } label: {
                            Label("New message", systemImage: "person.badge.plus")
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(LibraryGlassDesign.inkSecondary)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .help("New channel or message")

                sidebarSettingsMenu
            }

            if chat.permissions.canCreateChannels {
                Button { showNewChannel = true } label: {
                    Label("Create channel", systemImage: "number")
                }
                .buttonStyle(LibrarySubmenuTextButtonStyle())
            }
            if chat.permissions.canDM {
                Button { showNewDM = true } label: {
                    Label("New message", systemImage: "person.badge.plus")
                }
                .buttonStyle(LibrarySubmenuTextButtonStyle())
            }
        }
    }

    private var sidebarSettingsMenu: some View {
        Menu {
            Button {
                chat.showNotificationSettings = true
            } label: {
                Label("Notification settings", systemImage: "bell.badge")
            }
            Button {
                chat.markAllChannelsRead()
            } label: {
                Label("Mark all as read", systemImage: "checkmark.circle")
            }
            Button {
                chat.openWorkspaceSearch()
            } label: {
                Label("Search workspace", systemImage: "magnifyingglass")
            }
            Divider()
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    chat.chatFocusMode.toggle()
                }
            } label: {
                Label(
                    chat.chatFocusMode ? "Exit focus mode" : "Focus on chat",
                    systemImage: chat.chatFocusMode ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
                )
            }
            Divider()
            Button {
                chat.showPermissionsSheet = true
            } label: {
                Label("Workspace chat permissions", systemImage: "lock.shield")
            }
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(LibraryGlassDesign.inkSecondary)
                .frame(width: 28, height: 28)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .help("Chat settings")
    }

    private func layoutToggle(_ layout: ChatSidebarLayout, icon: String, label: String) -> some View {
        let selected = chat.sidebarLayout == layout
        return Button {
            chat.setSidebarLayout(layout)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(label)
                    .font(.system(size: 11, weight: selected ? .semibold : .regular))
                    .lineLimit(1)
            }
            .foregroundStyle(selected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkMuted)
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
        let unread = chat.unreadCount(for: channel.id)
        let bold = chat.isSidebarRowBold(channel)
        let threadUnread = chat.hasUnreadThreadReplies(for: channel.id)
        let trailing = LibraryRelativeTime.string(since: channel.lastMessageAt)

        return HStack(spacing: 0) {
            Button {
                tabStore.openFromChannel(channel)
                chat.selectChannel(channel)
            } label: {
                HStack(spacing: 8) {
                    ChatChannelIconView(channel: channel, size: ChatClickUpDesign.rowIconSize)
                    Text(channel.sidebarTitle)
                        .font(.system(size: 13, weight: bold || selected ? .semibold : .regular))
                        .foregroundStyle(selected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    HStack(spacing: 4) {
                        if threadUnread {
                            Button {
                                Task { await chat.openUnreadThreadFromSidebar(for: channel) }
                            } label: {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(LibraryGlassDesign.primaryCTA)
                            }
                            .buttonStyle(.plain)
                            .help("Open unread thread")
                        }
                        if unread > 0 {
                            Text(unread > 99 ? "99+" : "\(unread)")
                                .font(ChatClickUpDesign.unreadBadgeFont)
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
                    .frame(minWidth: 40, alignment: .trailing)
                }
                .frame(height: ChatClickUpDesign.rowHeight)
                .padding(.horizontal, 10)
                .background(
                    selected
                        ? LibraryGlassDesign.sidebarSelection.opacity(0.55)
                        : Color.clear
                )
                .overlay(alignment: .leading) {
                    if selected {
                        Rectangle()
                            .fill(LibraryGlassDesign.ink.opacity(0.22))
                            .frame(width: 2)
                    }
                }
            }
            .buttonStyle(.plain)

            channelRowMenu(channel)
                .frame(width: 28)
        }
        .padding(.horizontal, 4)
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
                .frame(width: 24, height: ChatClickUpDesign.rowHeight)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }
}
