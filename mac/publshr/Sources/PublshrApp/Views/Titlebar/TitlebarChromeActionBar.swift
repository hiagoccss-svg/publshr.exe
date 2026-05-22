import SwiftUI

/// Cursor-style titlebar actions — search, command palette, and profile only.
struct TitlebarChromeActionBar: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @Binding var module: AppModule
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
            EmptyView()
        case .trailing:
            trailingCluster
        }
    }

    private var trailingCluster: some View {
        HStack(alignment: .center, spacing: CursorMacShellDesign.titlebarActionSpacing) {
            TitlebarChromeIconButton(
                systemName: "magnifyingglass",
                help: TitlebarShortcutHint.tooltip("Search", shortcut: TitlebarShortcutHint.search),
                isEnabled: module == .chat
            ) {
                if module == .chat { chat.showSearchSheet = true }
            }

            TitlebarChromeIconButton(
                systemName: "command",
                help: TitlebarShortcutHint.tooltip("Command palette", shortcut: TitlebarShortcutHint.commandPalette)
            ) {
                showCommandPalette = true
            }

            profileMenu
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
            TitlebarChromeMenuLabel(title: profileShortTitle)
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
}

private extension String {
    var nonEmptyOrNil: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
