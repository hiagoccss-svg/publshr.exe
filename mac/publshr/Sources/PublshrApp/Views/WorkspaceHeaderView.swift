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
    var topInset: CGFloat

    @State private var hoveredTabId: String?
    @State private var tabDragOffsets: [String: CGSize] = [:]

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: topInset)

            HStack(spacing: 0) {
                leadingControls
                    .padding(.leading, 12)

                tabStrip
                    .frame(maxWidth: .infinity)

                trailingActions
                    .padding(.trailing, 12)
            }
            .frame(height: CursorTheme.workspaceHeaderHeight)
            .background(CursorTheme.titleBar)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(CursorTheme.border.opacity(0.55))
                    .frame(height: 1)
            }
        }
    }

    // MARK: - Leading

    private var leadingControls: some View {
        HStack(spacing: 6) {
            sidebarToggleButton

            HStack(spacing: 2) {
                headerIconButton(
                    "chevron.left",
                    enabled: navigationBackEnabled,
                    help: "Back"
                ) { performNavigateBack() }
                headerIconButton(
                    "chevron.right",
                    enabled: navigationForwardEnabled,
                    help: "Forward"
                ) { performNavigateForward() }
            }
        }
    }

    private var sidebarToggleButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                tabStore.sidebarExpanded.toggle()
            }
        } label: {
            Image(systemName: tabStore.sidebarExpanded ? "sidebar.left" : "sidebar.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(CursorTheme.foregroundMuted)
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(tabStore.sidebarExpanded ? CursorTheme.panelBackground : CursorTheme.tabInactiveBackground)
                )
        }
        .buttonStyle(.plain)
        .help(tabStore.sidebarExpanded ? "Collapse main menu" : "Expand main menu")
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
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
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
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(CursorTheme.foregroundDim)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(CursorTheme.border, lineWidth: 1)
                )
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
            Text("Settings")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(CursorTheme.foregroundMuted)
        }
    }

    private var activeModule: AppModule {
        if let tab = tabStore.selectedTab, case .app(let m) = tab.kind { return m }
        if tabStore.selectedTab?.kind.isChat == true { return .chat }
        if tabStore.selectedTab?.kind.isSpace == true { return .spaces }
        return module
    }

    private var chatTrailingActions: some View {
        HStack(spacing: 6) {
            compactSearchField(
                placeholder: "Search in channel",
                text: $chat.searchQuery
            )
            .frame(maxWidth: 200)

            if chat.selectedChannel != nil, subscription.canUseCalls(workspace: auth.selectedWorkspace) {
                callMenu
            }

            if chat.selectedChannel != nil {
                headerIconButton(chat.showPinnedPanel ? "pin.fill" : "pin", enabled: true, help: "Pinned") {
                    chat.showPinnedPanel.toggle()
                }
            }

            headerIconButton(
                chat.chatFocusMode ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right",
                enabled: true,
                help: chat.chatFocusMode ? "Show sidebars" : "Focus"
            ) {
                withAnimation(.easeInOut(duration: 0.2)) { chat.chatFocusMode.toggle() }
            }

            if let tab = tabStore.selectedTab, tab.kind.isChat {
                headerIconButton("arrow.up.forward.square", enabled: true, help: "Open in new window") {
                    detachTab(tab)
                }
            }

            headerIconButton("sparkles", enabled: true, help: "AI") { chat.showAISheet = true }
            profileMenuChip
            workspaceMenuChip
        }
    }

    private var spacesTrailingActions: some View {
        HStack(spacing: 6) {
            compactSearchField(
                placeholder: "Search spaces",
                text: $spaces.searchQuery
            )
            .frame(maxWidth: 200)

            if spaces.selectedSpace != nil {
                viewModePicker
                headerIconButton(
                    spaces.selectedSpace?.isPinned == true ? "pin.fill" : "pin",
                    enabled: true,
                    help: "Pin"
                ) {
                    Task { await spaces.togglePinSelectedSpace() }
                }
            }

            headerIconButton(
                spaces.spacesFocusMode ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right",
                enabled: true,
                help: "Focus"
            ) {
                withAnimation(.easeInOut(duration: 0.2)) { spaces.spacesFocusMode.toggle() }
            }

            if let tab = tabStore.selectedTab, tab.kind.isSpace {
                headerIconButton("arrow.up.forward.square", enabled: true, help: "Open in new window") {
                    detachTab(tab)
                }
            }

            workspaceMenuChip
        }
    }

    private var viewModePicker: some View {
        HStack(spacing: 2) {
            ForEach(SpacesViewModel.TaskViewMode.allCases) { mode in
                Button { spaces.taskView = mode } label: {
                    Image(systemName: mode.icon)
                        .font(.system(size: 11))
                        .foregroundStyle(spaces.taskView == mode ? CursorTheme.accent : CursorTheme.foregroundMuted)
                        .frame(width: 26, height: 26)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(spaces.taskView == mode ? CursorTheme.accent.opacity(0.1) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var callMenu: some View {
        Menu {
            Section("Voice") {
                Button { startCall(video: false, scope: .private) } label: {
                    Label("Private call", systemImage: "person.2.fill")
                }
                Button { startCall(video: false, scope: .meeting) } label: {
                    Label("Meeting call", systemImage: "person.3.fill")
                }
            }
            Section("Video") {
                Button { startCall(video: true, scope: .private) } label: {
                    Label("Private video", systemImage: "video")
                }
                Button { startCall(video: true, scope: .meeting) } label: {
                    Label("Meeting video", systemImage: "video.fill")
                }
            }
        } label: {
            Image(systemName: "phone")
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundMuted)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.white))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(CursorTheme.border, lineWidth: 1))
        }
        .menuStyle(.borderlessButton)
        .help("Start a call")
    }

    private var profileMenuChip: some View {
        Menu {
            Button { chat.showPermissionsSheet = true } label: {
                Label("Chat & profile settings", systemImage: "person.crop.circle")
            }
            Divider()
            ForEach(ChatPresenceStatus.allCases.filter { $0 != .invisible }, id: \.self) { status in
                Button { Task { await chat.setStatus(status) } } label: {
                    Label(status.label, systemImage: status == chat.myStatus ? "checkmark" : "circle.fill")
                }
            }
        } label: {
            ChatProfileAvatar(
                profile: auth.profile,
                displayName: auth.profile?.displayName ?? auth.displayName,
                size: 26
            )
            .overlay(alignment: .bottomTrailing) {
                ChatPresenceDot(status: chat.myStatus, size: 8)
                    .offset(x: 2, y: 2)
            }
        }
        .menuStyle(.borderlessButton)
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
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .background(CursorTheme.panelBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .menuStyle(.borderlessButton)
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
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(CursorTheme.panelBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .menuStyle(.borderlessButton)
    }

    private func compactSearchField(placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundStyle(CursorTheme.foregroundDim)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(CursorTheme.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func headerIconButton(
        _ symbol: String,
        enabled: Bool,
        help: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(enabled ? CursorTheme.foregroundMuted : CursorTheme.foregroundDim.opacity(0.35))
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(enabled ? CursorTheme.panelBackground : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .help(help)
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

    private func startCall(video: Bool, scope: CallScope) {
        guard let ws = auth.selectedWorkspace?.id,
              let channel = chat.selectedChannel else { return }
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
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isSelected ? CursorTheme.accent : CursorTheme.foregroundMuted)
                .frame(width: 14)

            VStack(alignment: .leading, spacing: 0) {
                Text(tab.title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
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
        .padding(.horizontal, CursorTheme.workspaceTabHorizontalPadding)
        .padding(.vertical, 6)
        .frame(minWidth: 88, maxWidth: 200)
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
                CursorTheme.tabActiveBackground
            } else if isHovered {
                CursorTheme.tabInactiveBackground.opacity(0.9)
            } else {
                CursorTheme.tabInactiveBackground
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
