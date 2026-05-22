import SwiftUI

/// Unified window chrome — traffic lights, tabs, pane title, Ask AI, and pane actions share one bottom-aligned titlebar row.
struct LibraryShellHeaderView: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var subscription: SubscriptionService
    @EnvironmentObject private var calls: CallSignalingService
    @ObservedObject var spaces: SpacesViewModel
    @Binding var module: AppModule
    var safeAreaTop: CGFloat

    private var titlebarHeight: CGFloat {
        AppWindowChromeMetrics.titlebarHeight(safeAreaTop: safeAreaTop)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: AppWindowChromeMetrics.rowSpacing) {
            Color.clear
                .frame(width: AppWindowChromeMetrics.trafficLightLeadingInset)

            ToolbarIconButton(
                systemName: tabStore.sidebarExpanded ? "sidebar.left" : "sidebar.right",
                help: "Toggle sidebar"
            ) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    tabStore.sidebarExpanded.toggle()
                }
            }

            ToolbarIconButton(systemName: "chevron.left", enabled: canGoBack, help: "Back") {
                navigateBack()
            }
            ToolbarIconButton(systemName: "chevron.right", enabled: canGoForward, help: "Forward") {
                navigateForward()
            }
            ToolbarIconButton(systemName: "house", help: "Home") {
                tabStore.openFromModule(module, activate: true)
            }

            tabStrip

            paneTitleCluster

            moduleUtilityIcons

            Spacer(minLength: 8)

            trailingChromeCluster
        }
        .padding(.trailing, 12)
        .padding(.bottom, AppWindowChromeMetrics.trafficLightBaselineInset)
        .frame(height: titlebarHeight, alignment: .bottom)
        .frame(maxWidth: .infinity)
        .background { AppWindowChromeBackground() }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(LibraryGlassDesign.hairline)
                .frame(height: 1)
        }
    }

    // MARK: - Module utilities (from main — list/filter/search without top tab strip)

    private var moduleUtilityIcons: some View {
        HStack(spacing: 2) {
            ToolbarIconButton(systemName: "square.grid.2x2", help: "Spaces") {
                module = .spaces
                tabStore.openFromModule(.spaces, activate: true)
            }
            ToolbarIconButton(systemName: "list.bullet", help: "List") {
                if module == .chat { chat.setSidebarLayout(.organized) }
            }
            ToolbarIconButton(systemName: "line.3.horizontal.decrease", help: "Filter") {
                if module == .chat { chat.showSearchSheet = true }
            }
            ToolbarIconButton(systemName: "magnifyingglass", help: "Search") {
                if module == .chat { chat.showSearchSheet = true }
            }
        }
    }

    // MARK: - Tabs

    private var tabStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(tabStore.tabs) { tab in
                    ChromeDocumentTab(
                        title: tab.title,
                        iconSystemName: tab.iconSystemName,
                        isSelected: tabStore.selectedTabId == tab.id,
                        canClose: tabStore.tabs.count > 1,
                        onSelect: { selectTab(tab) },
                        onClose: { closeTab(tab) }
                    )
                }
                addTabButton
            }
        }
        .frame(maxWidth: 420)
    }

    private var addTabButton: some View {
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
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(LibraryGlassDesign.inkMuted)
                .frame(
                    width: AppWindowChromeMetrics.controlSize,
                    height: AppWindowChromeMetrics.documentTabHeight
                )
        }
        .menuStyle(.borderlessButton)
        .help("New tab")
    }

    // MARK: - Pane title (same baseline as Ask AI)

    @ViewBuilder
    private var paneTitleCluster: some View {
        switch module {
        case .chat:
            if let channel = chat.selectedChannel {
                Menu {
                    Button("Search in channel") { chat.showSearchSheet = true }
                    if subscription.canUseCalls(workspace: auth.selectedWorkspace) {
                        Divider()
                        Button("Start call") {
                            startCall(video: false, scope: .meeting)
                        }
                    }
                } label: {
                    paneTitleLabel(channel.displayTitle)
                }
                .menuStyle(.borderlessButton)
            } else {
                paneTitleLabel("New AI Chat")
            }
        case .spaces:
            paneTitleLabel(spaces.selectedSpace?.name ?? "Spaces")
        case .settings:
            EmptyView()
        }
    }

    private func paneTitleLabel(_ title: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(LibraryGlassDesign.ink)
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(LibraryGlassDesign.inkMuted)
        }
        .frame(height: AppWindowChromeMetrics.controlSize)
    }

    // MARK: - Trailing (Ask AI + pane actions — bottom aligned with traffic-light close)

    private var trailingChromeCluster: some View {
        HStack(alignment: .bottom, spacing: AppWindowChromeMetrics.trailingClusterSpacing) {
            AskAIChromeButton {
                chat.showAISheet = true
            }

            if module == .chat, let tab = tabStore.selectedTab, tab.kind.isChatChannelOrDM {
                ChromeSquareButton(systemName: "pencil", help: "Channel options") {
                    chat.showPermissionsSheet = true
                }
                ChromeSquareButton(systemName: "arrow.up.forward.square", help: "Open in new window") {
                    detachTab(tab)
                }
                ChromeSquareButton(systemName: "xmark", help: "Close tab") {
                    closeTab(tab)
                }
            } else if module == .spaces, let tab = tabStore.selectedTab, tab.kind.isSpaceTab {
                ChromeSquareButton(systemName: "arrow.up.forward.square", help: "Open in new window") {
                    detachTab(tab)
                }
                ChromeSquareButton(systemName: "xmark", help: "Close tab") {
                    closeTab(tab)
                }
            }

            ChromeSquareButton(systemName: "gearshape", help: "Settings") {
                NotificationCenter.default.post(name: .publshrOpenSettings, object: nil)
            }
        }
    }

    // MARK: - Navigation

    private var canGoBack: Bool {
        module == .chat ? chat.canNavigateBack : spaces.canNavigateBack
    }

    private var canGoForward: Bool {
        module == .chat ? chat.canNavigateForward : spaces.canNavigateForward
    }

    private func navigateBack() {
        if module == .chat { chat.navigateBack() }
        else { Task { await spaces.navigateBack() } }
    }

    private func navigateForward() {
        if module == .chat { chat.navigateForward() }
        else { Task { await spaces.navigateForward() } }
    }

    // MARK: - Tab actions

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

// MARK: - Tab kind helpers

private extension WorkspaceTabKind {
    var isChatChannelOrDM: Bool {
        switch self {
        case .chatChannel, .chatDirectMessage: return true
        default: return false
        }
    }

    var isSpaceTab: Bool {
        if case .space = self { return true }
        return false
    }
}
