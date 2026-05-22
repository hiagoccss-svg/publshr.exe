import SwiftUI

/// Cursor-style titlebar actions — channel tools, command palette, and profile (far right).
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
        HStack(alignment: .center, spacing: AppWindowChromeMetrics.trailingClusterSpacing) {
            if module == .chat, let channel = chat.selectedChannel {
                channelActionGroup(channel)
                TitlebarChromeDivider()
            }

            TitlebarChromeIconButton(
                systemName: "magnifyingglass",
                help: searchHelp,
                isEnabled: module == .chat
            ) {
                guard module == .chat else { return }
                let scope: ChatSearchScope = chat.selectedChannel != nil ? .channel : .workspace
                chat.openWorkspaceSearch(scope: scope)
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

    private var searchHelp: String {
        if chat.selectedChannel != nil {
            return TitlebarShortcutHint.tooltip("Search in channel", shortcut: TitlebarShortcutHint.search)
        }
        return TitlebarShortcutHint.tooltip("Search workspace", shortcut: TitlebarShortcutHint.search)
    }

    private func channelActionGroup(_ channel: ChatChannel) -> some View {
        HStack(alignment: .center, spacing: CursorMacShellDesign.titlebarActionSpacing) {
            TitlebarChromeIconButton(
                systemName: chat.showPinnedPanel ? "pin.fill" : "pin",
                help: "Pinned messages",
                isActive: chat.showPinnedPanel
            ) {
                chat.showPinnedPanel.toggle()
            }

            Menu {
                ChatChannelActionsMenu(chat: chat, channel: channel)
            } label: {
                TitlebarChromeIconButtonLabel(systemName: "ellipsis")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .help("Channel options")
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
            ChatProfileAvatar(
                profile: auth.profile,
                displayName: auth.profile?.displayName ?? auth.profile?.email ?? "Account",
                size: AppWindowChromeMetrics.controlSize,
                presence: module == .chat ? chat.myStatus : nil
            )
            .overlay(
                Circle()
                    .strokeBorder(CursorMacShellDesign.borderSubtle, lineWidth: 0.5)
            )
        }
        .menuStyle(.borderlessButton)
        .help("Account")
    }
}

/// Icon-only label for menus that wrap `TitlebarChromeIconButton` styling.
private struct TitlebarChromeIconButtonLabel: View {
    let systemName: String
    @State private var isHovered = false

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: AppWindowChromeMetrics.controlIconSize, weight: .medium))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(isHovered ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary)
            .frame(
                width: AppWindowChromeMetrics.controlSize,
                height: AppWindowChromeMetrics.controlSize
            )
            .background(
                RoundedRectangle(cornerRadius: AppWindowChromeMetrics.controlCornerRadius, style: .continuous)
                    .fill(isHovered ? Color.white.opacity(0.55) : Color.white.opacity(0.32))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppWindowChromeMetrics.controlCornerRadius, style: .continuous)
                    .strokeBorder(CursorMacShellDesign.borderSubtle, lineWidth: 0.5)
            )
            .onHover { isHovered = $0 }
    }
}

private extension String {
    var nonEmptyOrNil: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
