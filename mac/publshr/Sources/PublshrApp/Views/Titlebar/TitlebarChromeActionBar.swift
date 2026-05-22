import SwiftUI

/// Leading + trailing interactive actions for the unified native titlebar.
struct TitlebarChromeActionBar: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var subscription: SubscriptionService
    @ObservedObject var spaces: SpacesViewModel
    @Binding var module: AppModule
    @Binding var showNewChannel: Bool
    @Binding var showNewDM: Bool
    @Binding var showCommandPalette: Bool
    @Binding var showNotificationsPanel: Bool

    let placement: Placement

    enum Placement {
        case leading
        case trailing
    }

    var body: some View {
        switch placement {
        case .leading:
            leadingCluster
        case .trailing:
            EmptyView()
        }
    }

    // MARK: - Leading

    private var leadingCluster: some View {
        HStack(alignment: .center, spacing: AppWindowChromeMetrics.titlebarActionSpacing) {
            TitlebarChromeIconButton(
                systemName: tabStore.sidebarExpanded ? "sidebar.left" : "sidebar.right",
                help: TitlebarShortcutHint.tooltip("Toggle submenu", shortcut: TitlebarShortcutHint.toggleSidebar),
                isActive: tabStore.sidebarExpanded
            ) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    tabStore.sidebarExpanded.toggle()
                }
            }

            newChatControl

            TitlebarChromeIconButton(
                systemName: "chevron.left",
                help: TitlebarShortcutHint.tooltip("Back", shortcut: TitlebarShortcutHint.navigateBack),
                isEnabled: canGoBack
            ) {
                navigateBack()
            }

            TitlebarChromeIconButton(
                systemName: "chevron.right",
                help: TitlebarShortcutHint.tooltip("Forward", shortcut: TitlebarShortcutHint.navigateForward),
                isEnabled: canGoForward
            ) {
                navigateForward()
            }

            workspaceSwitcher
        }
    }

    @ViewBuilder
    private var newChatControl: some View {
        if module == .chat {
            Menu {
                Button("New AI chat") {
                    chat.selectedChannel = nil
                    tabStore.openFromModule(.chat, activate: true)
                }
                Button("New channel…") { showNewChannel = true }
                Button("New message…") { showNewDM = true }
            } label: {
                TitlebarChromeMenuLabel(title: "New")
            }
            .menuStyle(.borderlessButton)
            .help(TitlebarShortcutHint.tooltip("New chat", shortcut: TitlebarShortcutHint.newChat))
        } else {
            Button {
                module = .chat
                tabStore.openFromModule(.chat, activate: true)
                chat.selectedChannel = nil
            } label: {
                TitlebarChromeMenuLabel(title: "New")
            }
            .buttonStyle(.plain)
            .disabled(module == .settings)
        }
    }

    private var workspaceSwitcher: some View {
        Menu {
            if auth.workspaceMemberships.isEmpty {
                Text("No workspaces")
            } else {
                ForEach(auth.workspaceMemberships) { membership in
                    Button {
                        auth.switchWorkspace(membership)
                    } label: {
                        HStack {
                            Text(membership.workspace.name)
                            if auth.selectedMembership?.id == membership.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            Divider()
            Button("Manage workspaces…") {
                Task {
                    await auth.loadWorkspaces()
                    auth.flowState = .selectWorkspace
                }
            }
        } label: {
            TitlebarChromeMenuLabel(
                title: auth.selectedWorkspace?.name ?? "Workspace",
                isActive: auth.selectedWorkspace != nil
            )
        }
        .menuStyle(.borderlessButton)
        .help("Switch workspace")
    }

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
}

private extension String {
    var nonEmptyOrNil: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
