import SwiftUI

/// Editor-column toolbar (embedded in `ShellUnifiedTitlebar`): channel title left, actions right.
struct ChatEditorToolbarContent: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @Binding var showCommandPalette: Bool
    @Binding var showNotificationsPanel: Bool

    var body: some View {
        HStack(alignment: .center, spacing: AppWindowChromeMetrics.toolbarItemSpacing) {
            channelTitle
            Spacer(minLength: 8)
            trailingActions
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var channelTitle: some View {
        if let channel = chat.selectedChannel {
            TitlebarToolbarChannelTitle(
                channel: channel,
                detail: channelSubtitle(channel)
            )
            .help(channel.displayTitle)
        } else {
            Text("Chat")
                .font(.system(size: AppWindowChromeMetrics.toolbarTitleFontSize, weight: .semibold))
                .foregroundStyle(LibraryGlassDesign.inkSecondary)
                .frame(height: AppWindowChromeMetrics.controlSize, alignment: .leading)
        }
    }

    @ViewBuilder
    private var trailingActions: some View {
        if chat.selectedChannel != nil {
            TitlebarChromeIconButton(systemName: "arrow.up.forward.square", help: "Open in new window") {
                if let channel = chat.selectedChannel {
                    ChatWindowManager.shared.openChannel(channel, chat: chat, auth: auth)
                }
            }

            TitlebarChromeIconButton(
                systemName: chat.chatFocusMode ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right",
                help: chat.chatFocusMode ? "Show sidebars" : "Focus on chat",
                isActive: chat.chatFocusMode
            ) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    chat.chatFocusMode.toggle()
                }
            }

            TitlebarChromeIconButton(systemName: "sparkles", help: "Chat recap & AI") {
                chat.showAISheet = true
            }

            TitlebarChromeIconButton(systemName: "magnifyingglass", help: "Search in channel") {
                chat.showSearchSheet = true
            }

            TitlebarChromeIconButton(
                systemName: chat.showPinnedPanel ? "pin.fill" : "pin",
                help: "Pinned messages",
                isActive: chat.showPinnedPanel
            ) {
                chat.showPinnedPanel.toggle()
            }

            if let channel = chat.selectedChannel,
               channel.kind == .dm || channel.kind == .group {
                TitlebarChromeIconButton(
                    systemName: "info.circle",
                    help: "Conversation details",
                    isActive: chat.showDMInspector
                ) {
                    chat.showDMInspector.toggle()
                }
            }

            if let channel = chat.selectedChannel {
                channelMoreMenu(channel)
            }
        }

        TitlebarChromeIconButton(
            systemName: "bell",
            help: "Notifications",
            badgeCount: min(max(chat.totalUnread, chat.unreadInAppNotificationCount), 99)
        ) {
            showNotificationsPanel = true
        }

        TitlebarChromeIconButton(
            systemName: "command",
            help: TitlebarShortcutHint.tooltip("Command palette", shortcut: TitlebarShortcutHint.commandPalette)
        ) {
            showCommandPalette = true
        }

        TitlebarChromeIconButton(systemName: "gearshape", help: "Channel settings") {
            chat.showChannelSettings = true
        }
        .disabled(chat.selectedChannel == nil)
    }

    private func channelMoreMenu(_ channel: ChatChannel) -> some View {
        Menu {
            ChatChannelActionsMenu(chat: chat, channel: channel)
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: AppWindowChromeMetrics.controlIconSize, weight: .regular))
                .foregroundStyle(LibraryGlassDesign.inkSecondary)
                .frame(
                    width: AppWindowChromeMetrics.controlSize,
                    height: AppWindowChromeMetrics.controlSize
                )
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .help("More")
    }

    private func channelSubtitle(_ channel: ChatChannel) -> String? {
        if let desc = channel.description, !desc.isEmpty { return desc }
        let count = chat.channelMemberCount(for: channel)
        return count == 1 ? "1 member" : "\(count) members"
    }
}

/// Channel title cluster aligned to the shared titlebar row.
struct TitlebarToolbarChannelTitle: View {
    let channel: ChatChannel
    /// Optional member count or topic — kept on one line for titlebar alignment.
    var detail: String?

    var body: some View {
        HStack(spacing: 6) {
            TitlebarToolbarSlot {
                ChatChannelIconView(channel: channel, size: AppWindowChromeMetrics.channelIconSize)
            }
            Text(titleLine)
                .font(.system(size: AppWindowChromeMetrics.toolbarTitleFontSize, weight: .semibold))
                .foregroundStyle(LibraryGlassDesign.ink)
                .lineLimit(1)
        }
        .frame(height: AppWindowChromeMetrics.controlSize, alignment: .leading)
    }

    private var titleLine: String {
        guard let detail, !detail.isEmpty else { return channel.displayTitle }
        return "\(channel.displayTitle) · \(detail)"
    }
}
