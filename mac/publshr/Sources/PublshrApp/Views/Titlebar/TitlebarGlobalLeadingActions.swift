import SwiftUI

/// Far-left titlebar cluster (after traffic lights): settings, command palette, notifications, menu.
struct TitlebarGlobalLeadingActions: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @Binding var module: AppModule
    @Binding var showCommandPalette: Bool
    @Binding var showNotificationsPanel: Bool

    var body: some View {
        HStack(alignment: .center, spacing: AppWindowChromeMetrics.toolbarLeadingClusterSpacing) {
            TitlebarChromeIconButton(systemName: "gearshape", help: "Settings (⌘,)") {
                NotificationCenter.default.post(name: .publshrOpenSettings, object: nil)
            }

            TitlebarChromeIconButton(
                systemName: "command",
                help: TitlebarShortcutHint.tooltip("Command palette", shortcut: TitlebarShortcutHint.commandPalette)
            ) {
                showCommandPalette = true
            }

            TitlebarChromeIconButton(
                systemName: "bell",
                help: "Notifications",
                badgeCount: module == .chat
                    ? min(max(chat.totalUnread, chat.unreadInAppNotificationCount), 99)
                    : 0
            ) {
                showNotificationsPanel = true
            }

            globalMenu
        }
    }

    @ViewBuilder
    private var globalMenu: some View {
        TitlebarToolbarSlot {
            Menu {
                if module == .chat, let channel = chat.selectedChannel {
                    ChatChannelActionsMenu(chat: chat, channel: channel)
                    Divider()
                }
                Button("Workspace settings") {
                    NotificationCenter.default.post(
                        name: .publshrOpenSettings,
                        object: SettingsSection.workspace.rawValue
                    )
                }
                Button("Account") {
                    NotificationCenter.default.post(
                        name: .publshrOpenSettings,
                        object: SettingsSection.account.rawValue
                    )
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: AppWindowChromeMetrics.controlIconSize, weight: .regular))
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(LibraryGlassDesign.inkSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .help("More")
        }
    }
}
