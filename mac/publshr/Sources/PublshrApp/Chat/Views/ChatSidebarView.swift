import SwiftUI

/// Universal submenu for chat — search, filters, channels/DMs/recents (ClickUp) in library glass chrome.
struct ChatSidebarView: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @ObservedObject var chat: ChatViewModel
    @Binding var showNewChannel: Bool
    @Binding var showNewDM: Bool
    var submenuWidth: CGFloat = LibraryUniversalSubmenu.width

    var body: some View {
        LibraryUniversalSubmenuContainer(width: submenuWidth) {
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
                        }
                    }
                    .padding(.bottom, chat.sidebarHub == .channels ? 6 : 4)
                }
                .frame(minHeight: 0, maxHeight: .infinity)
            }
            .frame(minHeight: 0, maxHeight: .infinity)
        } footer: {
            if chat.sidebarHub == .channels {
                layoutFooter
            }
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
        HStack(spacing: 6) {
            filterPickerMenu
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(quickSidebarFilters) { filter in
                        filterPill(filter)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.horizontal, LibraryGlassDesign.sidebarRowHorizontal)
        .padding(.top, 2)
        .frame(height: ChatClickUpDesign.filterBarHeight, alignment: .center)
    }

    /// ClickUp primary filters — All lives in the dropdown; chips are quick toggles.
    private var quickSidebarFilters: [ChatSidebarFilter] {
        [.unread, .mentions, .pinned, .dms, .channels]
    }

    private var filterPickerMenu: some View {
        Menu {
            ForEach(ChatSidebarFilter.allCases) { filter in
                Button {
                    if chat.sidebarFilter == filter, filter != .all {
                        chat.setSidebarFilter(.all)
                    } else {
                        chat.setSidebarFilter(filter)
                    }
                } label: {
                    if chat.sidebarFilter == filter {
                        Label(filter.label, systemImage: "checkmark")
                    } else {
                        Text(filter.label)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(chat.sidebarFilter.label)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(LibraryGlassDesign.ink)
            .padding(.horizontal, ChatClickUpDesign.filterPillHPadding)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(LibraryGlassDesign.sidebarSelection)
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(LibraryGlassDesign.sidebarSelectionStroke, lineWidth: 1)
            )
            .fixedSize(horizontal: true, vertical: false)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .help("Filter conversations")
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
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, ChatClickUpDesign.filterPillHPadding)
                .padding(.vertical, 5)
                .background(
                    Capsule(style: .continuous)
                        .fill(selected ? LibraryGlassDesign.sidebarSelection : LibraryGlassDesign.filterPillInactiveFill)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(
                            selected ? LibraryGlassDesign.sidebarSelectionStroke : LibraryGlassDesign.filterPillInactiveStroke,
                            lineWidth: 1
                        )
                )
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
                collapsibleChannelSection(
                    .favorites,
                    items: chat.filteredChannels + chat.filteredDMs,
                    onAdd: nil
                )
            } else {
                projectsSection
                if chat.sidebarFilter == .all, !chat.pinnedSidebarChannels.isEmpty {
                    collapsibleChannelSection(.favorites, items: chat.pinnedSidebarChannels, onAdd: nil)
                }
                if chat.sidebarFilter != .dms {
                    collapsibleChannelSection(
                        .channels,
                        items: chat.filteredChannels.filter { !chat.isSidebarPinned($0) },
                        onAdd: { showNewChannel = true }
                    )
                }
                if chat.sidebarFilter != .channels {
                    collapsibleChannelSection(
                        .directMessages,
                        items: chat.filteredDMs.filter { !chat.isSidebarPinned($0) },
                        onAdd: { showNewDM = true }
                    )
                }
            }
        }
    }

    private var recentsContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            collapsibleSectionHeader(.recents, onAdd: nil)
            if chat.isSidebarSectionExpanded(.recents) {
                if chat.sidebarRecentsList.isEmpty {
                    emptyHint
                } else {
                    ForEach(chat.sidebarRecentsList) { channel in
                        channelRow(channel)
                    }
                }
            }
        }
    }

    private var projectsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            collapsibleSectionHeader(.projects, onAdd: nil)
            if chat.isSidebarSectionExpanded(.projects) {
                if chat.filteredProjects.isEmpty {
                    Text("No projects yet")
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
                                Image(systemName: "folder")
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

    /// ClickUp lower-left — icon layout toggles + compose + settings (no wrapping labels).
    private var layoutFooter: some View {
        HStack(alignment: .center, spacing: 6) {
            layoutSegment(.organized, icon: "list.bullet.rectangle", label: "Organized")
            layoutSegment(.recents, icon: "clock", label: "Recents")
            Spacer(minLength: 4)
            composeMenu
            sidebarSettingsMenu
        }
        .padding(.horizontal, 10)
        .frame(height: ChatClickUpDesign.footerHeight, alignment: .center)
    }

    private var composeMenu: some View {
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
                .foregroundStyle(LibraryGlassDesign.ink)
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(LibraryGlassDesign.filterPillInactiveFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(LibraryGlassDesign.filterPillInactiveStroke, lineWidth: 1)
                )
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .help("New channel or message")
    }

    private func layoutSegment(_ layout: ChatSidebarLayout, icon: String, label: String) -> some View {
        let selected = chat.sidebarLayout == layout
        return Button {
            chat.setSidebarLayout(layout)
        } label: {
            Image(systemName: icon)
                .font(.system(size: 13, weight: selected ? .semibold : .medium))
                .foregroundStyle(selected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkMuted)
                .frame(width: AppWindowChromeMetrics.controlSize, height: AppWindowChromeMetrics.controlSize)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(selected ? LibraryGlassDesign.sidebarSelection : LibraryGlassDesign.filterPillInactiveFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(
                            selected ? LibraryGlassDesign.sidebarSelectionStroke : LibraryGlassDesign.filterPillInactiveStroke,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .help(label)
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

    // MARK: - Collapsible sections & rows

    private func collapsibleChannelSection(
        _ section: ChatSidebarSection,
        items: [ChatChannel],
        onAdd: (() -> Void)?
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            collapsibleSectionHeader(section, onAdd: onAdd)
            if chat.isSidebarSectionExpanded(section) {
                if items.isEmpty {
                    sectionEmptyHint(section)
                } else {
                    ForEach(items) { channel in
                        channelRow(channel)
                    }
                }
            }
        }
    }

    private func collapsibleSectionHeader(
        _ section: ChatSidebarSection,
        titleOverride: String? = nil,
        onAdd: (() -> Void)?
    ) -> some View {
        let expanded = chat.isSidebarSectionExpanded(section)
        let title = titleOverride ?? section.title
        return HStack(spacing: 4) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    chat.toggleSidebarSection(section)
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: expanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(LibraryGlassDesign.inkMuted)
                        .frame(width: 12)
                    Text(title.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(LibraryGlassDesign.inkMuted)
                        .tracking(0.6)
                        .lineLimit(1)
                }
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
            if expanded, let onAdd {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(LibraryGlassDesign.inkSecondary)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, LibraryGlassDesign.sidebarRowHorizontal)
        .padding(.top, LibraryGlassDesign.sectionLabelTop)
        .padding(.bottom, LibraryGlassDesign.sectionLabelBottom)
    }

    private func sectionEmptyHint(_ section: ChatSidebarSection) -> some View {
        let message: String = {
            switch section {
            case .projects: "No projects yet"
            case .favorites: "None pinned yet"
            case .channels: "No channels yet"
            case .directMessages: "No messages yet"
            case .recents: "No recent conversations"
            }
        }()
        return Text(message)
            .font(.system(size: 11))
            .foregroundStyle(LibraryGlassDesign.inkMuted)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
    }

    private func channelRow(_ channel: ChatChannel) -> some View {
        let selected = chat.selectedChannel?.id == channel.id
        let unread = chat.unreadCount(for: channel.id)
        let bold = chat.isSidebarRowBold(channel)
        let threadUnread = chat.hasUnreadThreadReplies(for: channel.id)
        let trailing = LibraryRelativeTime.string(since: channel.lastMessageAt)

        return HStack(spacing: 0) {
            Button {
                chat.selectChannel(channel)
                tabStore.openFromChannel(channel)
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
                .padding(.horizontal, LibraryGlassDesign.sidebarRowHorizontal - 2)
                .background(
                    RoundedRectangle(cornerRadius: LibraryGlassDesign.sidebarRowRadius, style: .continuous)
                        .fill(selected ? LibraryGlassDesign.sidebarSelection : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LibraryGlassDesign.sidebarRowRadius, style: .continuous)
                        .strokeBorder(selected ? LibraryGlassDesign.sidebarSelectionStroke : Color.clear, lineWidth: 1)
                )
                .overlay(alignment: .leading) {
                    if selected {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(LibraryGlassDesign.ink.opacity(0.35))
                            .frame(width: 3)
                            .padding(.leading, 4)
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
