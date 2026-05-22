import SwiftUI

/// Unified window chrome — one fixed-height row shared with macOS traffic lights (Cursor / VS Code style).
struct LibraryShellHeaderView: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var subscription: SubscriptionService
    @EnvironmentObject private var calls: CallSignalingService
    @ObservedObject var spaces: SpacesViewModel
    @Binding var module: AppModule
    @Binding var showNewChannel: Bool
    @Binding var showNewDM: Bool
    @Binding var showCommandPalette: Bool
    @Binding var showNotificationsPanel: Bool
    /// When hosted in `NSTitlebarAccessoryViewController`, AppKit already offsets for traffic lights.
    var reservesTrafficLightLeadingInset: Bool = true

    /// Nudge row content to the traffic-light vertical center (tune per macOS release).
    private var titlebarVerticalPadding: CGFloat {
        reservesTrafficLightLeadingInset
            ? AppWindowChromeMetrics.trafficLightVerticalAlignPadding
            : 0
    }

    private var rowHeight: CGFloat {
        AppWindowChromeMetrics.unifiedTitlebarRowHeight
    }

    var body: some View {
        titlebarRow
            .padding(.top, titlebarVerticalPadding)
            .frame(height: rowHeight, alignment: .center)
            .frame(maxWidth: .infinity)
            .background { AppWindowChromeBackground() }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(LibraryGlassDesign.hairline)
                    .frame(height: 1)
            }
    }

    private var titlebarRow: some View {
        HStack(alignment: .center, spacing: AppWindowChromeMetrics.rowSpacing) {
            if reservesTrafficLightLeadingInset {
                Color.clear
                    .frame(width: AppWindowChromeMetrics.trafficLightLeadingInset)
            }

            TitlebarChromeActionBar(
                spaces: spaces,
                module: $module,
                showNewChannel: $showNewChannel,
                showNewDM: $showNewDM,
                showCommandPalette: $showCommandPalette,
                showNotificationsPanel: $showNotificationsPanel,
                placement: .leading
            )

            tabStrip

            paneTitleCluster

            Spacer(minLength: 8)

            TitlebarChromeActionBar(
                spaces: spaces,
                module: $module,
                showNewChannel: $showNewChannel,
                showNewDM: $showNewDM,
                showCommandPalette: $showCommandPalette,
                showNotificationsPanel: $showNotificationsPanel,
                placement: .trailing
            )

            trailingPaneCluster
        }
        .padding(.trailing, 12)
    }

    // MARK: - Tabs

    private var tabStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: 6) {
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

    // MARK: - Pane title

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

    // MARK: - Trailing pane actions (Ask AI + tab chrome)

    private var trailingPaneCluster: some View {
        HStack(alignment: .center, spacing: AppWindowChromeMetrics.trailingClusterSpacing) {
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
        }
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
