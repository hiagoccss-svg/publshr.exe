import SwiftUI

/// Traffic-header trailing actions — notifications and command palette (profile lives in bar menu).
struct TitlebarChromeActionBar: View {
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
        HStack(alignment: .center, spacing: AppWindowChromeMetrics.toolbarItemSpacing) {
            TitlebarChromeIconButton(
                systemName: "bell",
                help: "Notifications",
                badgeCount: module == .chat
                    ? min(max(chat.totalUnread, chat.unreadInAppNotificationCount), 99)
                    : 0
            ) {
                showNotificationsPanel = true
            }

            TitlebarChromeIconButton(
                systemName: "command",
                help: TitlebarShortcutHint.tooltip("Command palette", shortcut: TitlebarShortcutHint.commandPalette)
            ) {
                showCommandPalette = true
            }

            TitlebarWorkspaceSettingsButton()
        }
    }
}
