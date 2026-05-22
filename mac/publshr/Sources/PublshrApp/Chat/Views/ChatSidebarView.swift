import SwiftUI

/// ClickUp Chat Sidebar — header, search, filters (All/Unread/DMs/Channels), Favorites, sections, layout footer.
/// https://help.clickup.com/hc/en-us/articles/33491596671255-What-is-the-Chat-Sidebar
struct ChatSidebarView: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @ObservedObject var chat: ChatViewModel
    @Binding var showNewChannel: Bool
    @Binding var showNewDM: Bool
    @FocusState private var filterFieldFocused: Bool

    var body: some View {
        LibraryUniversalSubmenuContainer(width: LibraryUniversalSubmenu.width) {
            VStack(spacing: 0) {
                chatHeader
                sidebarSearch
                filterBar
                LibraryUniversalSubmenu.sectionDivider()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if chat.sidebarLayout == .recents {
                            recentsContent
                        } else {
                            organizedContent
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 4)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
        } footer: {
            layoutFooter
        }
        .preferredColorScheme(.light)
        .onAppear { normalizeSidebarFilterIfNeeded() }
    }

    private func normalizeSidebarFilterIfNeeded() {
        let hasData = !chat.channels.isEmpty || !chat.directMessages.isEmpty
        let filteredEmpty = chat.filteredChannels.isEmpty && chat.filteredDMs.isEmpty
        if hasData, filteredEmpty, chat.sidebarFilter != .all {
            chat.setSidebarFilter(.all)
        }
    }

    // MARK: - Header (ClickUp: Chat + create)

    private var chatHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(LibraryGlassDesign.primaryCTA)
            Text("Chat")
                .font(ChatClickUpDesign.sidebarTitleFont)
                .foregroundStyle(LibraryGlassDesign.ink)
            Spacer(minLength: 0)
            Menu {
                Button { showNewChannel = true } label: {
                    Label("New channel", systemImage: "number")
                }
                Button { showNewDM = true } label: {
                    Label("New message", systemImage: "person.badge.plus")
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LibraryGlassDesign.inkSecondary)
                    .frame(width: 24, height: 24)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
        }
        .padding(.horizontal, ChatClickUpDesign.horizontalPadding)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    // MARK: - Search (ClickUp: find channel or person)

    private var sidebarSearch: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(LibraryGlassDesign.inkMuted)
            TextField("Search channels and people", text: $chat.sidebarSearchQuery)
                .textFieldStyle(.plain)
                .font(ChatClickUpDesign.searchFont)
                .foregroundStyle(CursorTheme.foreground)
                .focused($filterFieldFocused)
            if !chat.sidebarSearchQuery.isEmpty {
                Button { chat.sidebarSearchQuery = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(LibraryGlassDesign.inkMuted)
                }
                .buttonStyle(.plain)
            }
            Button {
                chat.openWorkspaceSearch(scope: .workspace)
            } label: {
                Image(systemName: "text.magnifyingglass")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(LibraryGlassDesign.inkSecondary)
            }
            .buttonStyle(.plain)
            .help("Search messages in workspace (⌘⇧F)")
        }
        .padding(.horizontal, 10)
        .frame(height: ChatClickUpDesign.searchHeight)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(LibraryGlassDesign.cardGlassFill.opacity(0.65))
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(LibraryGlassDesign.hairline, lineWidth: 1)
        )
        .padding(.horizontal, ChatClickUpDesign.horizontalPadding)
        .padding(.bottom, 8)
    }

    // MARK: - Filters (ClickUp pills)

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
                .foregroundStyle(selected ? Color.white : LibraryGlassDesign.ink)
                .padding(.horizontal, ChatClickUpDesign.filterPillHPadding)
                .frame(height: ChatClickUpDesign.filterPillHeight)
                .background(
                    Capsule(style: .continuous)
                        .fill(selected ? LibraryGlassDesign.primaryCTA : LibraryGlassDesign.filterPillInactiveFill)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(
                            selected ? Color.clear : LibraryGlassDesign.filterPillInactiveStroke,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Organized (Favorites → Channels → DMs)

    private var organizedContent: some View {
        Group {
            if chat.sidebarFilter == .all, !chat.starredChannels.isEmpty {
                sidebarSection("Favorites", items: chat.starredChannels, onAdd: nil)
                LibraryUniversalSubmenu.sectionDivider()
            }
            if chat.sidebarFilter != .dms {
                sidebarSection("Channels", items: chat.filteredChannels, onAdd: { showNewChannel = true })
                LibraryUniversalSubmenu.sectionDivider()
            }
            if chat.sidebarFilter != .channels {
                sidebarSection("Direct Messages", items: chat.filteredDMs, onAdd: { showNewDM = true })
            }
        }
    }

    private var recentsContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            LibraryUniversalSubmenu.sectionHeader("Recents")
            if chat.sidebarRecentsList.isEmpty {
                emptyHint
            } else {
                ForEach(chat.sidebarRecentsList) { channel in
                    channelRow(channel)
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

    /// ClickUp: Organized vs Recents toggles (lower-left).
    private var layoutFooter: some View {
        HStack(spacing: 0) {
            layoutToggle(.organized, icon: "list.bullet.rectangle", label: "Organized")
            layoutToggle(.recents, icon: "clock", label: "Recents")
            Spacer()
            Text(chat.sidebarLayout.label)
                .font(ChatClickUpDesign.footerFont)
                .foregroundStyle(LibraryGlassDesign.inkMuted)
        }
    }

    private func layoutToggle(_ layout: ChatSidebarLayout, icon: String, label: String) -> some View {
        let selected = chat.sidebarLayout == layout
        return Button {
            chat.setSidebarLayout(layout)
        } label: {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(selected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkMuted)
                .frame(width: 36, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(selected ? LibraryGlassDesign.sidebarSelection : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .help(label)
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
                    if chat.isStarred(channel) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.yellow)
                    }
                    if chat.isChannelMuted(channel) {
                        Image(systemName: "bell.slash.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(LibraryGlassDesign.inkMuted)
                    }
                    Spacer(minLength: 0)
                    HStack(spacing: 4) {
                        if threadUnread {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(LibraryGlassDesign.primaryCTA)
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
                    RoundedRectangle(cornerRadius: ChatClickUpDesign.rowRadius, style: .continuous)
                        .fill(selected ? LibraryGlassDesign.sidebarSelection : Color.clear)
                )
            }
            .buttonStyle(.plain)

            channelRowMenu(channel)
                .frame(width: 28)
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
                .foregroundStyle(LibraryGlassDesign.inkMuted)
                .frame(width: 24, height: ChatClickUpDesign.rowHeight)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }
}
