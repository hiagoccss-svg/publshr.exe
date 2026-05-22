import SwiftUI
import UniformTypeIdentifiers

/// Editor-column header for chat: channel title, search, command, settings, profile (photo last).
struct ChatEditorHeaderBar: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @Binding var showCommandPalette: Bool

    @State private var showAvatarPicker = false
    @State private var isUploadingAvatar = false

    var body: some View {
        TitlebarToolbarRow(
            leadingPadding: CursorMacShellDesign.editorHorizontalPadding,
            trailingPadding: 14
        ) {
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
            profileAvatarMenu
        }
        .fileImporter(
            isPresented: $showAvatarPicker,
            allowedContentTypes: [.jpeg, .png],
            allowsMultipleSelection: false
        ) { result in
            guard case .success(let urls) = result, let url = urls.first else { return }
            Task { await uploadAvatar(from: url) }
        }
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

    private var profileAvatarMenu: some View {
        TitlebarToolbarProfileMenu(
            isUploadingAvatar: isUploadingAvatar,
            onUploadPhoto: { showAvatarPicker = true },
            onChatPermissions: { chat.showPermissionsSheet = true }
        )
    }

    private func uploadAvatar(from url: URL) async {
        isUploadingAvatar = true
        defer { isUploadingAvatar = false }
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            let mime = url.pathExtension.lowercased() == "png" ? "image/png" : "image/jpeg"
            try await auth.uploadAvatar(data: data, mimeType: mime)
        } catch {
            // Settings account pane shows errors; header stays minimal.
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
