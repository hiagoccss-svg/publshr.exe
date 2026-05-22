import SwiftUI

/// Cursor Mac 3-column shell — grey side columns, white boxed editor column, minimal titlebar.
struct LibraryShellView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var spaces: SpacesViewModel
    @EnvironmentObject private var subscription: SubscriptionService
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @Binding var module: AppModule
    @Binding var showNewChannel: Bool
    @Binding var showNewDM: Bool
    @Binding var showCommandPalette: Bool
    @Binding var showNotificationsPanel: Bool

    private var submenuHidden: Bool {
        !tabStore.sidebarExpanded
            || (module == .chat && chat.chatFocusMode)
            || (module == .spaces && spaces.spacesFocusMode)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                WorkspaceDesktopBackdrop()

                shellBody

                titlebarOverlay
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea(.container, edges: .top)
        .background(CursorMacShellDesign.columnChromeBackground)
        .onAppear {
            tabStore.sidebarExpanded = true
            syncModulesIfNeeded()
        }
        .onChange(of: tabStore.sidebarExpanded) { _, _ in
            withAnimation(.easeInOut(duration: 0.2)) {}
        }
        .onChange(of: chat.chatFocusMode) { _, _ in
            withAnimation(.easeInOut(duration: 0.2)) {}
        }
        .onChange(of: spaces.spacesFocusMode) { _, _ in
            withAnimation(.easeInOut(duration: 0.2)) {}
        }
        .onChange(of: auth.selectedMembership?.workspace.id) { _, _ in
            syncModulesIfNeeded()
        }
    }

    private var titlebarOverlay: some View {
        HStack(alignment: .top, spacing: 0) {
            Color.clear
                .frame(width: LibraryGlassDesign.barMenuWidth)
            if !submenuHidden {
                Color.clear
                    .frame(width: LibraryUniversalSubmenu.width)
            }
            LibraryShellHeaderView(
                spaces: spaces,
                module: $module,
                showNewChannel: $showNewChannel,
                showNewDM: $showNewDM,
                showCommandPalette: $showCommandPalette,
                showNotificationsPanel: $showNotificationsPanel,
                reservesTrafficLightLeadingInset: false
            )
            .frame(maxWidth: .infinity)
        }
        .frame(height: AppWindowChromeMetrics.unifiedTitlebarRowHeight)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var shellBody: some View {
        HStack(alignment: .top, spacing: 0) {
            LibraryBarMenuColumn(
                module: $module,
                showNewChannel: $showNewChannel
            )

            if !submenuHidden {
                AppSecondarySidebar(
                    module: module,
                    chat: chat,
                    spaces: spaces,
                    showNewChannel: $showNewChannel,
                    showNewDM: $showNewDM
                )
                .cursorColumnDividerTrailing()
                .transition(.move(edge: .leading).combined(with: .opacity))
            }

            VStack(spacing: 0) {
                Color.clear
                    .frame(height: AppWindowChromeMetrics.unifiedTitlebarRowHeight)
                    .accessibilityHidden(true)

                mainStage
                    .frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(0)
            }
            .frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.15), value: submenuHidden)
    }

    private var mainStage: some View {
        moduleContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cursorEditorColumnBox()
            .padding(CursorMacShellDesign.editorBoxPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(CursorMacShellDesign.workspaceBackground)
    }

    @ViewBuilder
    private var moduleContent: some View {
        switch module {
        case .chat:
            if subscription.canUseChat(workspace: auth.selectedWorkspace) {
                EnterpriseChatView(chat: chat, topInset: 0)
            } else {
                EnterpriseModuleGate(moduleName: "Chat", planName: subscription.features.planName)
            }
        case .spaces:
            if subscription.canUseSpaces(workspace: auth.selectedWorkspace) {
                SpacesRootView(spaces: spaces, topInset: 0)
            } else {
                EnterpriseModuleGate(moduleName: "Spaces", planName: subscription.features.planName)
            }
        case .settings:
            EnterpriseModuleGate(moduleName: "Settings", planName: subscription.features.planName)
        }
    }

    private func syncModulesIfNeeded() {
        guard auth.flowState == .signedIn else { return }
        chat.attach(auth: auth)
        chat.applyWorkspaceContext(
            workspace: auth.selectedWorkspace,
            permissions: auth.workspaceChatPermissions,
            auth: auth
        )
        spaces.attach(auth: auth)
        Task {
            await subscription.refresh(client: auth.client, workspace: auth.selectedWorkspace)
            if chat.channels.isEmpty, chat.directMessages.isEmpty {
                await chat.refreshAfterReconnect()
            }
            if spaces.spaces.isEmpty, auth.selectedWorkspace != nil {
                await spaces.reload()
            }
        }
    }
}
