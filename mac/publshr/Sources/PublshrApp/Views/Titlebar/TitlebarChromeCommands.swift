import SwiftUI

/// Builds command palette rows and wires notification-based shortcuts.
enum TitlebarChromeCommands {
    @MainActor
    static func paletteItems(
        tabStore: WorkspaceTabStore,
        auth: AuthViewModel,
        chat: ChatViewModel,
        spaces: SpacesViewModel,
        module: Binding<AppModule>,
        showNewChannel: Binding<Bool>,
        showNewDM: Binding<Bool>,
        showCommandPalette: Binding<Bool>,
        showNotificationsPanel: Binding<Bool>
    ) -> [TitlebarCommandPaletteItem] {
        [
            TitlebarCommandPaletteItem(
                id: "sidebar",
                title: tabStore.sidebarExpanded ? "Hide submenu" : "Show submenu",
                subtitle: "Toggle the library sidebar",
                systemImage: "sidebar.left",
                shortcut: TitlebarShortcutHint.toggleSidebar,
                isEnabled: true
            ) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    tabStore.sidebarExpanded.toggle()
                }
            },
            TitlebarCommandPaletteItem(
                id: "new-channel",
                title: "New channel",
                subtitle: "Chat",
                systemImage: "number",
                shortcut: nil,
                isEnabled: module.wrappedValue == .chat
            ) {
                showNewChannel.wrappedValue = true
            },
            TitlebarCommandPaletteItem(
                id: "new-dm",
                title: "New message",
                subtitle: "Direct message",
                systemImage: "person.badge.plus",
                shortcut: nil,
                isEnabled: module.wrappedValue == .chat
            ) {
                showNewDM.wrappedValue = true
            },
            TitlebarCommandPaletteItem(
                id: "search",
                title: "Search",
                subtitle: "Find messages and channels",
                systemImage: "magnifyingglass",
                shortcut: TitlebarShortcutHint.search,
                isEnabled: module.wrappedValue == .chat
            ) {
                chat.openWorkspaceSearch()
            },
            TitlebarCommandPaletteItem(
                id: "ai",
                title: "Ask AI",
                subtitle: "Open assistant",
                systemImage: "sparkles",
                shortcut: nil,
                isEnabled: true
            ) {
                chat.showAISheet = true
            },
            TitlebarCommandPaletteItem(
                id: "notifications",
                title: "Notifications",
                subtitle: chat.totalUnread > 0 ? "\(chat.totalUnread) unread" : "No unread",
                systemImage: "bell",
                shortcut: nil,
                isEnabled: true
            ) {
                showNotificationsPanel.wrappedValue = true
            },
            TitlebarCommandPaletteItem(
                id: "settings",
                title: "Workspace settings",
                subtitle: nil,
                systemImage: "gearshape",
                shortcut: TitlebarShortcutHint.settings,
                isEnabled: true
            ) {
                NotificationCenter.default.post(
                    name: .publshrOpenSettings,
                    object: SettingsSection.workspace.rawValue
                )
            },
            TitlebarCommandPaletteItem(
                id: "whiteboard",
                title: "Open Whiteboard",
                subtitle: "Spaces canvas",
                systemImage: "scribble.variable",
                shortcut: nil,
                isEnabled: true
            ) {
                module.wrappedValue = .whiteboard
                tabStore.openFromModule(.whiteboard, activate: true)
                spaces.taskView = .whiteboard
            },
            TitlebarCommandPaletteItem(
                id: "media-monitoring",
                title: "Open Media Monitoring",
                subtitle: "Native coverage workspace",
                systemImage: "dot.radiowaves.left.and.right",
                shortcut: nil,
                isEnabled: true
            ) {
                module.wrappedValue = .mediaMonitoring
                tabStore.openFromModule(.mediaMonitoring, activate: true)
            },
            TitlebarCommandPaletteItem(
                id: "workspace",
                title: "Switch workspace",
                subtitle: auth.selectedWorkspace?.name,
                systemImage: "building.2",
                shortcut: nil,
                isEnabled: true
            ) {
                auth.flowState = .selectWorkspace
            },
            TitlebarCommandPaletteItem(
                id: "spaces",
                title: "Open Spaces",
                subtitle: nil,
                systemImage: "square.grid.2x2",
                shortcut: nil,
                isEnabled: true
            ) {
                module.wrappedValue = .spaces
                tabStore.openFromModule(.spaces, activate: true)
            },
            TitlebarCommandPaletteItem(
                id: "chat",
                title: "Open Chat",
                subtitle: nil,
                systemImage: "bubble.left.and.bubble.right",
                shortcut: nil,
                isEnabled: true
            ) {
                module.wrappedValue = .chat
                tabStore.openFromModule(.chat, activate: true)
            },
        ]
    }
}

/// Invisible shortcut bridge — keeps keyboard commands active while using custom titlebar UI.
struct TitlebarChromeShortcutBridge: View {
    var body: some View {
        Group {
            Button("") { NotificationCenter.default.post(name: .publshrTitlebarToggleSidebar, object: nil) }
                .keyboardShortcut("\\", modifiers: .command)
            Button("") { NotificationCenter.default.post(name: .publshrTitlebarNewChat, object: nil) }
                .keyboardShortcut("n", modifiers: .command)
            Button("") { NotificationCenter.default.post(name: .publshrTitlebarCommandPalette, object: nil) }
                .keyboardShortcut("p", modifiers: [.command, .shift])
            Button("") { NotificationCenter.default.post(name: .publshrTitlebarCommandPalette, object: nil) }
                .keyboardShortcut("k", modifiers: .command)
            Button("") { NotificationCenter.default.post(name: .publshrTitlebarSearch, object: nil) }
                .keyboardShortcut("f", modifiers: [.command, .shift])
            Button("") { NotificationCenter.default.post(name: .publshrTitlebarNavigateBack, object: nil) }
                .keyboardShortcut("[", modifiers: .command)
            Button("") { NotificationCenter.default.post(name: .publshrTitlebarNavigateForward, object: nil) }
                .keyboardShortcut("]", modifiers: .command)
            Button("") {
                NotificationCenter.default.post(
                    name: .publshrOpenSettings,
                    object: SettingsSection.workspace.rawValue
                )
            }
                .keyboardShortcut(",", modifiers: .command)
        }
        .frame(width: 0, height: 0)
        .opacity(0)
        .accessibilityHidden(true)
    }
}
