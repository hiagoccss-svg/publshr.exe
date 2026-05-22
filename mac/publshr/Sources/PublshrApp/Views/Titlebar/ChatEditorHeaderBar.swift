import SwiftUI

/// Editor-column toolbar content (embedded in `ShellUnifiedTitlebar`). Profile lives in the bar menu footer.
struct ChatEditorToolbarContent: View {
    @EnvironmentObject private var chat: ChatViewModel
    @Binding var showCommandPalette: Bool

    var body: some View {
        HStack(alignment: .center, spacing: AppWindowChromeMetrics.toolbarItemSpacing) {
            channelTitle
            Spacer(minLength: 8)
            TitlebarChromeIconButton(systemName: "magnifyingglass", help: "Search in channel") {
                chat.showSearchSheet = true
            }
            .disabled(chat.selectedChannel == nil)
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
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var channelTitle: some View {
        if let channel = chat.selectedChannel {
            TitlebarToolbarChannelTitle(channel: channel)
                .help(channel.displayTitle)
        } else {
            Text("Chat")
                .font(.system(size: AppWindowChromeMetrics.toolbarTitleFontSize, weight: .semibold))
                .foregroundStyle(LibraryGlassDesign.inkSecondary)
                .frame(height: AppWindowChromeMetrics.controlSize, alignment: .leading)
        }
    }

}

/// Channel title cluster aligned to the same row as icon buttons.
struct TitlebarToolbarChannelTitle: View {
    let channel: ChatChannel

    var body: some View {
        HStack(spacing: 6) {
            TitlebarToolbarSlot {
                ChatChannelIconView(channel: channel, size: AppWindowChromeMetrics.channelIconSize)
            }
            Text(channel.displayTitle)
                .font(.system(size: AppWindowChromeMetrics.toolbarTitleFontSize, weight: .semibold))
                .foregroundStyle(LibraryGlassDesign.ink)
                .lineLimit(1)
        }
        .frame(height: AppWindowChromeMetrics.controlSize, alignment: .leading)
    }
}
