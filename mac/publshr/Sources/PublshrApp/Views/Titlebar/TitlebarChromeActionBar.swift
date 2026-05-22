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
            trailingCluster
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
                TitlebarChromeMenuLabel(title: "New", systemImage: "square.and.pencil")
            }
            .menuStyle(.borderlessButton)
            .help(TitlebarShortcutHint.tooltip("New chat", shortcut: TitlebarShortcutHint.newChat))
        } else {
            TitlebarChromeIconButton(
                systemName: "square.and.pencil",
                help: TitlebarShortcutHint.tooltip("New chat", shortcut: TitlebarShortcutHint.newChat),
                isEnabled: module != .settings
            ) {
                module = .chat
                tabStore.openFromModule(.chat, activate: true)
                chat.selectedChannel = nil
            }
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
                systemImage: "building.2",
                isActive: auth.selectedWorkspace != nil
            )
        }
        .menuStyle(.borderlessButton)
        .help("Switch workspace")
    }

    // MARK: - Trailing

    private var trailingCluster: some View {
        HStack(alignment: .center, spacing: AppWindowChromeMetrics.titlebarActionSpacing) {
            contextModuleActions

            TitlebarChromeDivider()

            TitlebarChromeIconButton(
                systemName: "command",
                help: TitlebarShortcutHint.tooltip("Command palette", shortcut: TitlebarShortcutHint.commandPalette)
            ) {
                showCommandPalette = true
            }

            TitlebarChromeIconButton(
                systemName: "magnifyingglass",
                help: TitlebarShortcutHint.tooltip("Search", shortcut: TitlebarShortcutHint.search),
                isEnabled: module == .chat
            ) {
                if module == .chat { chat.showSearchSheet = true }
            }

            TitlebarChromeIconButton(
                systemName: "bell",
                help: "Notifications",
                badgeCount: totalUnreadBadge
            ) {
                showNotificationsPanel = true
            }

            profileMenu

            TitlebarChromeIconButton(
                systemName: "gearshape",
                help: TitlebarShortcutHint.tooltip("Settings", shortcut: TitlebarShortcutHint.settings)
            ) {
                NotificationCenter.default.post(name: .publshrOpenSettings, object: nil)
            }
        }
    }

    @ViewBuilder
    private var contextModuleActions: some View {
        switch module {
        case .chat:
            HStack(spacing: 2) {
                TitlebarChromeIconButton(systemName: "line.3.horizontal.decrease", help: "Filter channels") {
                    chat.showSearchSheet = true
                }
                if chat.isLoading {
                    TitlebarChromeIconButton(
                        systemName: "arrow.clockwise",
                        help: "Syncing chat",
                        isLoading: true
                    ) {}
                }
            }
        case .spaces:
            HStack(spacing: 2) {
                TitlebarChromeIconButton(systemName: "square.grid.2x2", help: "Board", isActive: spaces.taskView == .board) {
                    spaces.taskView = .board
                }
                TitlebarChromeIconButton(systemName: "list.bullet", help: "List", isActive: spaces.taskView == .list) {
                    spaces.taskView = .list
                }
                if spaces.isLoading {
                    TitlebarChromeIconButton(
                        systemName: "arrow.clockwise",
                        help: "Syncing spaces",
                        isLoading: true
                    ) {}
                }
            }
        case .settings:
            EmptyView()
        }
    }

    private var profileMenu: some View {
        Menu {
            if let name = auth.profile?.displayName?.nonEmptyOrNil {
                Text(name)
                    .font(.headline)
            }
            if let email = auth.profile?.email {
                Text(email)
            }
            Divider()
            Button("Account & profile") {
                NotificationCenter.default.post(name: .publshrOpenSettings, object: SettingsSection.account.rawValue)
            }
            Button("Workspace settings") {
                NotificationCenter.default.post(name: .publshrOpenSettings, object: SettingsSection.workspace.rawValue)
            }
            Divider()
            Button("Sign out", role: .destructive) {
                Task { await auth.signOut() }
            }
        } label: {
            TitlebarChromeMenuLabel(
                title: profileShortTitle,
                systemImage: "person.crop.circle",
                isActive: false
            )
        }
        .menuStyle(.borderlessButton)
        .help("Account")
    }

    private var profileShortTitle: String {
        if let name = auth.profile?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            let parts = name.split(separator: " ")
            if let first = parts.first {
                return String(first)
            }
        }
        if let email = auth.profile?.email.split(separator: "@").first {
            return String(email)
        }
        return "Account"
    }

    private var totalUnreadBadge: Int {
        chat.totalUnread
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
