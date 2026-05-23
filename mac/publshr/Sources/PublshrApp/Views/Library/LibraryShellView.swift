import SwiftUI

/// Cursor Mac 3-column shell — single unified titlebar row, then icon rail + submenu + editor.
struct LibraryShellView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var spaces: SpacesViewModel
    @EnvironmentObject private var subscription: SubscriptionService
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @ObservedObject private var trafficLayout = TrafficLightLayoutStore.shared
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
        .ignoresSafeArea(.container, edges: .top)
        .background(Color.clear)
        .onAppear {
            tabStore.sidebarExpanded = true
            tabStore.barMenuExpanded = true
            syncModulesIfNeeded()
        }
        .onChange(of: tabStore.sidebarExpanded) { _, _ in
            withAnimation(.easeInOut(duration: 0.2)) {}
        }
        .onChange(of: tabStore.barMenuExpanded) { _, _ in
            withAnimation(.easeInOut(duration: 0.15)) {}
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
            expanded: tabStore.barMenuExpanded,
            windowWidth: windowWidth,
            trafficInset: trafficLayout.leadingInset,
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

        return VStack(spacing: 0) {
            ShellUnifiedTitlebar(
                module: $module,
                showCommandPalette: $showCommandPalette,
                showNotificationsPanel: $showNotificationsPanel,
                barColumnWidth: barW,
                submenuColumnWidth: subW,
                submenuHidden: submenuHidden
            )

            HStack(alignment: .top, spacing: 0) {
                ShellColumnChromeStack(
                    showsTitlebar: false,
                    columnWidth: barW,
                    appliesPrimaryBarGlass: true
                ) {
                    Group {
                        if tabStore.barMenuExpanded {
                            LibraryBarMenuColumn(
                                barWidth: barW,
                                module: $module,
                                profilePresentation: $profilePresentation
                            )
                        } else {
                            LibraryBarMenuIconRail(
                                barWidth: barW,
                                module: $module,
                                profilePresentation: $profilePresentation
                            )
                        }
                    }
                }
                .layoutPriority(3)
                .transition(.move(edge: .leading).combined(with: .opacity))

                ShellColumnVerticalRule()

                if !submenuHidden {
                    ShellColumnChromeStack(
                        showsTitlebar: false,
                        columnWidth: subW,
                        appliesSidebarChrome: true
                    ) {
                        AppSecondarySidebar(
                            submenuWidth: subW,
                            module: module,
                            chat: chat,
                            spaces: spaces,
                            showNewChannel: $showNewChannel,
                            showNewDM: $showNewDM
                        )
                    }
                    .layoutPriority(3)
                    .transition(.move(edge: .leading).combined(with: .opacity))

                    ShellColumnVerticalRule()
                }

                editorColumn
                    .frame(
                        minWidth: ShellColumnLayout.editorMinWidth,
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                    .layoutPriority(0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.15), value: submenuHidden)
        .animation(.easeInOut(duration: 0.15), value: tabStore.barMenuExpanded)
    }

    /// Chat, Spaces, Whiteboard, and Media Monitoring use a flat, full-bleed editor column (no rounded “card” box).
    private var usesFlatEditorColumn: Bool {
        module == .chat || module.usesSpacesSubmenu || module == .mediaMonitoring
    }

    private var editorColumn: some View {
        ShellColumnChromeStack(showsTitlebar: false) {
            Group {
                if usesFlatEditorColumn {
                    moduleContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    moduleContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .cursorEditorColumnBox()
                        .padding(CursorMacShellDesign.editorBoxPadding)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            usesFlatEditorColumn
                ? CursorMacShellDesign.editorColumnBackground
                : CursorMacShellDesign.workspaceBackground
        )
    }

    @ViewBuilder
    private var moduleContent: some View {
        switch module {
        case .chat:
            if subscription.canUseChat(workspace: auth.selectedWorkspace) {
                EnterpriseChatView(chat: chat, topInset: 0, onNewMessage: { showNewDM = true })
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
