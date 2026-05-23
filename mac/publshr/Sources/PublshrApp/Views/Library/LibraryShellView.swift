import SwiftUI

/// Cursor Mac 3-column shell — each column owns titlebar + body (traffic lights in column 1).
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
    @Binding var profilePresentation: WorkspaceProfilePresentation?

    private var submenuHidden: Bool {
        module == .settings
            || !tabStore.sidebarExpanded
            || (module == .chat && chat.chatFocusMode)
            || (module.usesSpacesSubmenu && spaces.spacesFocusMode)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                WorkspaceDesktopBackdrop()
                shellBody(windowWidth: geometry.size.width)
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height,
                        alignment: .top
                    )
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.clear)
        .background { TrafficLightLayoutRefreshView().frame(width: 0, height: 0) }
        .onAppear {
            tabStore.sidebarExpanded = true
            tabStore.barMenuExpanded = true
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

    private func shellColumnWidths(windowWidth: CGFloat) -> (bar: CGFloat, submenu: CGFloat) {
        let subVisible = !submenuHidden
        let bar = LibraryGlassDesign.barMenuColumnWidth(
            windowWidth: windowWidth,
            submenuVisible: subVisible
        )
        let sub = LibraryGlassDesign.submenuColumnWidth(
            for: windowWidth,
            barWidth: bar,
            submenuVisible: subVisible
        )
        return (bar, sub)
    }

    private func shellBody(windowWidth: CGFloat) -> some View {
        let (barW, subW) = shellColumnWidths(windowWidth: windowWidth)

        return HStack(alignment: .top, spacing: 0) {
            LibraryShellBarColumn(
                width: barW,
                submenuHidden: submenuHidden,
                module: $module,
                profilePresentation: $profilePresentation
            )
            .layoutPriority(3)

            ShellColumnFullHeightRule()

            if !submenuHidden {
                LibraryShellSubmenuColumn(
                    width: subW,
                    module: module,
                    chat: chat,
                    spaces: spaces,
                    showNewChannel: $showNewChannel,
                    showNewDM: $showNewDM
                )
                .layoutPriority(3)
                .transition(.move(edge: .leading).combined(with: .opacity))

                ShellColumnFullHeightRule()
            }

            LibraryShellEditorColumn(
                module: $module,
                showCommandPalette: $showCommandPalette,
                showNotificationsPanel: $showNotificationsPanel
            ) {
                editorBody
            }
            .frame(
                minWidth: ShellColumnLayout.editorMinWidth,
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .layoutPriority(0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .animation(.easeInOut(duration: 0.15), value: submenuHidden)
    }

    @ViewBuilder
    private var editorBody: some View {
        if usesFlatEditorColumn {
            moduleContent
        } else {
            moduleContent
                .cursorEditorColumnBox()
                .padding(CursorMacShellDesign.editorBoxPadding)
        }
    }

    private var usesFlatEditorColumn: Bool {
        module == .chat || module.usesSpacesSubmenu || module == .mediaMonitoring
    }

    @ViewBuilder
    private var moduleContent: some View {
        switch module {
        case .chat:
            if subscription.canUseChat(workspace: auth.selectedWorkspace) {
                EnterpriseChatView(
                    chat: chat,
                    topInset: 0,
                    onNewMessage: { showNewDM = true },
                    onCreateChannel: { showNewChannel = true }
                )
            } else {
                EnterpriseModuleGate(moduleName: "Chat", planName: subscription.features.planName)
            }
        case .spaces, .whiteboard:
            if subscription.canUseSpaces(workspace: auth.selectedWorkspace) {
                SpacesRootView(spaces: spaces, topInset: 0)
            } else {
                EnterpriseModuleGate(moduleName: module.label, planName: subscription.features.planName)
            }
        case .mediaMonitoring:
            MediaMonitoringModuleView()
        case .settings:
            SettingsModuleRedirectView(module: $module)
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
            await chat.loadWorkspaceProjects()
            await chat.loadPlannerTasks()
            if chat.channels.isEmpty, chat.directMessages.isEmpty {
                await chat.refreshAfterReconnect()
            }
            if spaces.spaces.isEmpty, auth.selectedWorkspace != nil {
                await spaces.reload()
            }
        }
    }
}

/// Settings opens in a dedicated window (⌘,). If the main shell ever lands on `.settings`, route there immediately.
private struct SettingsModuleRedirectView: View {
    @Binding var module: AppModule

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                NotificationCenter.default.post(name: .publshrOpenSettings, object: nil)
                if module == .settings {
                    module = .chat
                }
            }
    }
}
