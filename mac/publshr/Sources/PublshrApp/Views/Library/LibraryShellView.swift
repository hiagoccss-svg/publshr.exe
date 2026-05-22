import SwiftUI

/// Cursor Mac 3-column shell — glass bar, traffic controls, borderless chat column.
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
        !tabStore.sidebarExpanded
            || (module == .chat && chat.chatFocusMode)
            || (module == .spaces && spaces.spacesFocusMode)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                WorkspaceDesktopBackdrop()
                shellBody
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea(.container, edges: .top)
        .background(Color.clear)
        .onAppear {
            tabStore.sidebarExpanded = true
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

    private var shellBody: some View {
        HStack(alignment: .top, spacing: 0) {
            ShellColumnChromeStack(
                headerKind: .trafficLeading(module: $module),
                appliesPrimaryBarGlass: true
            ) {
                Group {
                    if tabStore.barMenuExpanded {
                        LibraryBarMenuColumn(
                            module: $module,
                            profilePresentation: $profilePresentation
                        )
                    } else {
                        LibraryBarMenuIconRail(
                            module: $module,
                            profilePresentation: $profilePresentation
                        )
                    }
                }
            }
            .fixedSize(horizontal: true, vertical: false)
            .layoutPriority(2)

            if !submenuHidden {
                ShellColumnChromeStack(
                    headerKind: module == .chat ? .chatSubmenu : .secondaryChrome,
                    appliesSidebarChrome: true
                ) {
                    AppSecondarySidebar(
                        module: module,
                        chat: chat,
                        spaces: spaces,
                        showNewChannel: $showNewChannel,
                        showNewDM: $showNewDM
                    )
                }
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(2)
                .transition(.move(edge: .leading).combined(with: .opacity))
            }

            editorColumn
                .frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.15), value: submenuHidden)
        .animation(.easeInOut(duration: 0.15), value: tabStore.barMenuExpanded)
    }

    private var editorColumn: some View {
        ShellColumnChromeStack(
            headerKind: .editorTrailing(
                module: $module,
                showCommandPalette: $showCommandPalette,
                showNotificationsPanel: $showNotificationsPanel
            )
        ) {
            Group {
                if module == .chat {
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
        .background(module == .chat ? CursorMacShellDesign.editorColumnBackground : CursorMacShellDesign.workspaceBackground)
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
