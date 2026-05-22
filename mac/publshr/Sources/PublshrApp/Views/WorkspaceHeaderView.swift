import SwiftUI
import UniformTypeIdentifiers

/// Unified workspace header: sidebar toggle, draggable tabs, contextual actions.
struct WorkspaceHeaderView: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var subscription: SubscriptionService
    @EnvironmentObject private var calls: CallSignalingService
    @ObservedObject var spaces: SpacesViewModel
    @Binding var module: AppModule
    /// Height of the macOS title-bar safe area (traffic lights live here).
    var safeAreaTop: CGFloat

    @State private var hoveredTabId: String?
    @State private var tabDragOffsets: [String: CGSize] = [:]

    private var chromeBarHeight: CGFloat {
        max(safeAreaTop, CursorTheme.windowChromeTopInset) + CursorTheme.workspaceHeaderHeight
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Color.clear
                .frame(width: CursorTheme.trafficLightLeadingPadding)

            HStack(spacing: 0) {
                leadingControls

                tabStrip
                    .frame(maxWidth: .infinity)

                trailingActions
                    .padding(.trailing, 4)
            }
            .padding(.leading, 4)
            .frame(height: CursorTheme.workspaceHeaderHeight)

            headerSettingsButton
                .padding(.trailing, 10)
        }
        .frame(height: chromeBarHeight, alignment: .bottom)
        .frame(maxWidth: .infinity)
        .background(CursorTheme.titleBar)
    }

    // MARK: - Leading

    private var leadingControls: some View {
        HStack(spacing: 4) {
            ToolbarIconButton(
                systemName: tabStore.sidebarExpanded ? "sidebar.left" : "sidebar.right",
                help: tabStore.sidebarExpanded ? "Collapse sidebar" : "Expand sidebar"
            ) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    tabStore.sidebarExpanded.toggle()
                }
            }

            ToolbarIconButton(systemName: "magnifyingglass", help: "Search") {
                if module == .chat {
                    chat.showSearchSheet = true
                }
            }

            HStack(spacing: 0) {
                ToolbarIconButton(
                    systemName: "chevron.left",
                    enabled: navigationBackEnabled,
                    help: "Back"
                ) { performNavigateBack() }
                ToolbarIconButton(
                    systemName: "chevron.right",
                    enabled: navigationForwardEnabled,
                    help: "Forward"
                ) { performNavigateForward() }
            }
        }
    }

    // MARK: - Tab strip

    private var tabStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: CursorTheme.workspaceTabSpacing) {
                ForEach(tabStore.tabs) { tab in
                    WorkspaceTabChip(
                        tab: tab,
                        isSelected: tabStore.selectedTabId == tab.id,
                        isHovered: hoveredTabId == tab.id,
                        dragOffset: tabDragOffsets[tab.id] ?? .zero,
                        canClose: tabStore.tabs.count > 1,
                        onSelect: { selectTab(tab) },
                        onClose: { closeTab(tab) },
                        onHover: { hovering in
                            hoveredTabId = hovering ? tab.id : (hoveredTabId == tab.id ? nil : hoveredTabId)
                        },
                        onDetachDrag: { offset in
                            tabDragOffsets[tab.id] = offset
                            if offset.height > 64 || abs(offset.width) > 220 {
                                detachTab(tab)
                                tabDragOffsets[tab.id] = .zero
                            }
                        },
                        onDetachDragEnd: {
                            tabDragOffsets[tab.id] = .zero
                        }
                    )
                    .draggable(tab.id)
                    .dropDestination(for: String.self) { items, _ in
                        guard let dragged = items.first else { return false }
                        tabStore.reorderTab(draggedId: dragged, before: tab.id)
                        return true
                    }
                }

                addTabMenu
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }

    private var addTabMenu: some View {
        Menu {
            Section("Applications") {
                ForEach(AppModule.mainStrip) { app in
                    Button {
                        tabStore.openFromModule(app)
                        module = app
                        tabStore.applySelection(module: &module, chat: chat, spaces: spaces)
                    } label: {
                        Label(app.label, systemImage: app.systemImage)
                    }
                }
            }
            if !chat.channels.isEmpty {
                Section("Channels") {
                    ForEach(chat.channels.prefix(12)) { channel in
                        Button {
                            tabStore.openFromChannel(channel)
                            module = .chat
                            chat.selectChannel(channel)
                        } label: {
                            Label(channel.displayTitle, systemImage: channel.sidebarIcon)
                        }
                    }
                }
            }
            if !spaces.spaces.isEmpty {
                Section("Spaces") {
                    ForEach(spaces.spaces.prefix(12)) { space in
                        Button {
                            tabStore.openFromSpace(space)
                            module = .spaces
                            Task { await spaces.selectSpace(space.id) }
                        } label: {
                            Label(space.name, systemImage: space.workspaceTabIcon)
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(CursorTheme.foregroundDim)
                .frame(width: CursorTheme.toolbarIconHitSize, height: CursorTheme.toolbarIconHitSize)
        }
        .menuStyle(.borderlessButton)
        .help("Open tab")
    }

    // MARK: - Trailing

    @ViewBuilder
    private var trailingActions: some View {
        switch activeModule {
        case .chat:
            chatTrailingActions
        case .spaces:
            spacesTrailingActions
        case .settings:
            EmptyView()
        }
    }

    private var headerSettingsButton: some View {
        Button {
            NotificationCenter.default.post(name: .publshrOpenSettings, object: nil)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "gearshape")
                    .font(.system(size: CursorTheme.toolbarIconSize, weight: .regular))
                Text("Settings")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(CursorTheme.toolbarIconForeground)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
        }
        .buttonStyle(.plain)
        .help("Enterprise settings, security, chat options, and updates")
    }

    private var activeModule: AppModule {
        if let tab = tabStore.selectedTab, case .app(let m) = tab.kind { return m }
        if tabStore.selectedTab?.kind.isChat == true { return .chat }
        if tabStore.selectedTab?.kind.isSpace == true { return .spaces }
        return module
    }

    private var chatTrailingActions: some View {
        HStack(spacing: 4) {
            compactSearchField(
                placeholder: "Search in channel",
                text: $chat.searchQuery
            )
            .frame(maxWidth: 180)

            HeaderActionDivider()

            if chat.selectedChannel != nil, subscription.canUseCalls(workspace: auth.selectedWorkspace) {
                ToolbarIconButton(systemName: "phone", help: "Voice call") { startCall(video: false) }
                ToolbarIconButton(systemName: "video", help: "Video call") { startCall(video: true) }
            }

            if chat.selectedChannel != nil {
                ToolbarIconButton(
                    systemName: chat.showPinnedPanel ? "pin.fill" : "pin",
                    help: "Pinned"
                ) { chat.showPinnedPanel.toggle() }
            }

            ToolbarIconButton(
                systemName: chat.chatFocusMode ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right",
                help: chat.chatFocusMode ? "Show sidebars" : "Focus"
            ) {
                withAnimation(.easeInOut(duration: 0.15)) { chat.chatFocusMode.toggle() }
            }

            if let tab = tabStore.selectedTab, tab.kind.isChat {
                ToolbarIconButton(systemName: "arrow.up.forward.square", help: "Open in new window") {
                    detachTab(tab)
                }
            }

            ToolbarIconButton(systemName: "sparkles", help: "AI") { chat.showAISheet = true }

            HeaderActionDivider()

            profileMenuChip
            presenceMenuChip

            HeaderActionDivider()

            workspaceMenuChip
        }
    }

    private var spacesTrailingActions: some View {
        HStack(spacing: 4) {
            compactSearchField(
                placeholder: "Search spaces",
                text: $spaces.searchQuery
            )
            .frame(maxWidth: 180)

            HeaderActionDivider()

            if spaces.selectedSpace != nil {
                viewModePicker
                ToolbarIconButton(
                    systemName: spaces.selectedSpace?.isPinned == true ? "pin.fill" : "pin",
                    help: "Pin"
                ) { Task { await spaces.togglePinSelectedSpace() } }
            }

            ToolbarIconButton(
                systemName: spaces.spacesFocusMode ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right",
                help: spaces.spacesFocusMode ? "Show sidebars" : "Focus"
            ) {
                withAnimation(.easeInOut(duration: 0.15)) { spaces.spacesFocusMode.toggle() }
            }

            if let tab = tabStore.selectedTab, tab.kind.isSpace {
                ToolbarIconButton(systemName: "arrow.up.forward.square", help: "Open in new window") {
                    detachTab(tab)
                }
            }

            HeaderActionDivider()

            workspaceMenuChip
        }
    }

    private var viewModePicker: some View {
        HStack(spacing: 0) {
            ForEach(SpacesViewModel.TaskViewMode.allCases) { mode in
                Button { spaces.taskView = mode } label: {
                    Image(systemName: mode.icon)
                        .font(.system(size: CursorTheme.toolbarIconSize))
                        .foregroundStyle(spaces.taskView == mode ? CursorTheme.accent : CursorTheme.foregroundMuted)
                        .frame(width: CursorTheme.toolbarIconHitSize, height: CursorTheme.toolbarIconHitSize)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var profileMenuChip: some View {
        Menu {
            if let profile = auth.profile {
                Text(profile.displayName ?? profile.email)
            }
            Divider()
            Button("Sign out", role: .destructive) {
                Task { await auth.signOut() }
            }
        } label: {
            ChatProfileAvatar(
                profile: auth.profile,
                displayName: auth.profile?.displayName ?? auth.profile?.email ?? "You",
                size: 26,
                presence: chat.myStatus
            )
        }
        .menuStyle(.borderlessButton)
        .help("Profile")
    }

    private var presenceMenuChip: some View {
        Menu {
            ForEach(ChatPresenceStatus.allCases.filter { $0 != .invisible }, id: \.self) { status in
                Button { Task { await chat.setStatus(status) } } label: {
                    Label(status.label, systemImage: status == chat.myStatus ? "checkmark" : "circle.fill")
                }
            }
        } label: {
            HStack(spacing: 4) {
                ChatPresenceDot(status: chat.myStatus, size: 8)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8))
                    .foregroundStyle(CursorTheme.foregroundDim)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
        .menuStyle(.borderlessButton)
        .help("Status")
    }

    private var workspaceMenuChip: some View {
        Menu {
            ForEach(auth.workspaceMemberships) { m in
                Button { auth.switchWorkspace(m) } label: {
                    Text("\(m.workspace.name) · \(m.role.label)")
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(auth.selectedMembership?.workspace.name ?? "Workspace")
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8))
            }
            .foregroundStyle(CursorTheme.foregroundMuted)
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
        .menuStyle(.borderlessButton)
    }

    private func compactSearchField(placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 10))
                .foregroundStyle(CursorTheme.foregroundDim)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 11))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(CursorTheme.editorBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .strokeBorder(CursorTheme.hairline, lineWidth: 1)
        )
    }

    // MARK: - Actions

    private func selectTab(_ tab: WorkspaceTab) {
        tabStore.selectTab(id: tab.id)
        tabStore.applySelection(module: &module, chat: chat, spaces: spaces)
    }

    private func closeTab(_ tab: WorkspaceTab) {
        tabStore.closeTab(id: tab.id)
        tabStore.applySelection(module: &module, chat: chat, spaces: spaces)
    }

    private func detachTab(_ tab: WorkspaceTab) {
        tabStore.detachTab(
            tab,
            chat: chat,
            spaces: spaces,
            auth: auth,
            subscription: subscription
        )
    }

    private var navigationBackEnabled: Bool {
        switch activeModule {
        case .chat: return chat.canNavigateBack
        case .spaces: return spaces.canNavigateBack
        case .settings: return false
        }
    }

    private var navigationForwardEnabled: Bool {
        switch activeModule {
        case .chat: return chat.canNavigateForward
        case .spaces: return spaces.canNavigateForward
        case .settings: return false
        }
    }

    private func performNavigateBack() {
        switch activeModule {
        case .chat: chat.navigateBack()
        case .spaces: Task { await spaces.navigateBack() }
        case .settings: break
        }
    }

    private func performNavigateForward() {
        switch activeModule {
        case .chat: chat.navigateForward()
        case .spaces: Task { await spaces.navigateForward() }
        case .settings: break
        }
    }

    private func startCall(video: Bool) {
        guard let ws = auth.selectedWorkspace?.id,
              let channel = chat.selectedChannel else { return }
        Task {
            await calls.startChannelCall(
                workspaceId: ws,
                channelId: channel.id,
                title: channel.displayTitle,
                video: video,
                workspaceSettings: auth.selectedWorkspace?.settings
            )
        }
    }
}

// MARK: - Tab chip

private struct WorkspaceTabChip: View {
    let tab: WorkspaceTab
    let isSelected: Bool
    let isHovered: Bool
    let dragOffset: CGSize
    let canClose: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    let onHover: (Bool) -> Void
    let onDetachDrag: (CGSize) -> Void
    let onDetachDragEnd: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: tab.iconSystemName)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(isSelected ? CursorTheme.accent : CursorTheme.foregroundMuted)
                .frame(width: 12)

            VStack(alignment: .leading, spacing: 0) {
                Text(tab.title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? CursorTheme.foreground : CursorTheme.foregroundMuted)
                    .lineLimit(1)
                if let subtitle = tab.subtitle, isSelected || isHovered {
                    Text(subtitle)
                        .font(.system(size: 9))
                        .foregroundStyle(CursorTheme.foregroundDim)
                        .lineLimit(1)
                }
            }

            if canClose, isHovered || isSelected {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(CursorTheme.foregroundDim)
                        .frame(width: 16, height: 16)
                        .background(Circle().fill(CursorTheme.border.opacity(0.35)))
                }
                .buttonStyle(.plain)
                .help("Close tab")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(minWidth: 80, maxWidth: 180)
        .background(chipBackground)
        .clipShape(RoundedRectangle(cornerRadius: CursorTheme.workspaceTabCornerRadius))
        .overlay(alignment: .bottom) {
            if isSelected {
                Rectangle()
                    .fill(CursorTheme.accent)
                    .frame(height: 2)
                    .padding(.horizontal, 6)
            }
        }
        .offset(dragOffset)
        .opacity(dragOffset.height > 40 ? 0.65 : 1)
        .scaleEffect(dragOffset.height > 40 ? 0.96 : 1)
        .onTapGesture(perform: onSelect)
        .onHover(perform: onHover)
        .contextMenu {
            Button("Close", action: onClose)
            Button("Open in New Window") {
                onDetachDrag(CGSize(width: 0, height: 80))
                onDetachDragEnd()
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 14)
                .onChanged { value in
                    onDetachDrag(value.translation)
                }
                .onEnded { _ in onDetachDragEnd() }
        )
        .help("Drag down or sideways to open in a new window")
    }

    private var chipBackground: some View {
        Group {
            if isSelected {
                Color.clear
            } else if isHovered {
                CursorTheme.tabInactiveBackground.opacity(0.65)
            } else {
                Color.clear
            }
        }
    }
}

private extension WorkspaceTabKind {
    var isChat: Bool {
        switch self {
        case .chatChannel, .chatDirectMessage: return true
        default: return false
        }
    }

    var isSpace: Bool {
        if case .space = self { return true }
        return false
    }
}
