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
        HStack(alignment: .center, spacing: CursorMacShellDesign.titlebarActionSpacing) {
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
        .padding(.leading, CursorMacShellDesign.editorHorizontalPadding)
        .padding(.trailing, 14)
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
            HStack(spacing: 8) {
                ChatChannelIconView(channel: channel, size: 18)
                Text(channel.displayTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LibraryGlassDesign.ink)
                    .lineLimit(1)
            }
            .help(channel.displayTitle)
        } else {
            Text("Chat")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(LibraryGlassDesign.inkSecondary)
        }
    }

    private var profileAvatarMenu: some View {
        Menu {
            if let profile = auth.profile {
                HStack(spacing: 10) {
                    ChatProfileAvatar(
                        profile: profile,
                        displayName: profile.displayName ?? profile.email,
                        size: 36,
                        presence: chat.myStatus
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.displayName ?? profile.email)
                            .font(.headline)
                        HStack(spacing: 4) {
                            ChatPresenceDot(status: chat.myStatus, size: 8)
                            Text(chat.myStatus.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            Divider()
            Button {
                showAvatarPicker = true
            } label: {
                Label(isUploadingAvatar ? "Uploading…" : "Upload photo", systemImage: "photo")
            }
            .disabled(isUploadingAvatar)
            Divider()
            Text("Set status")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(ChatPresenceStatus.allCases.filter { $0 != .invisible }, id: \.self) { status in
                Button {
                    Task { await chat.setStatus(status) }
                } label: {
                    Label(
                        status.label,
                        systemImage: status == chat.myStatus ? "checkmark.circle.fill" : "circle.fill"
                    )
                }
            }
            Divider()
            Button("Account & profile") {
                NotificationCenter.default.post(name: .publshrOpenSettings, object: SettingsSection.account.rawValue)
            }
            Button("Workspace settings") {
                NotificationCenter.default.post(name: .publshrOpenSettings, object: SettingsSection.workspace.rawValue)
            }
            Button("Chat permissions") {
                chat.showPermissionsSheet = true
            }
            Divider()
            Button("Sign out", role: .destructive) {
                Task { await auth.signOut() }
            }
        } label: {
            profileAvatarLabel
        }
        .menuStyle(.borderlessButton)
        .help("Profile & photo")
    }

    @ViewBuilder
    private var profileAvatarLabel: some View {
        if let profile = auth.profile {
            ChatProfileAvatar(
                profile: profile,
                displayName: profile.displayName ?? profile.email,
                size: AppWindowChromeMetrics.controlSize,
                presence: chat.myStatus
            )
        } else {
            Image(systemName: "person.circle.fill")
                .font(.system(size: AppWindowChromeMetrics.controlIconSize))
                .foregroundStyle(LibraryGlassDesign.inkSecondary)
                .frame(
                    width: AppWindowChromeMetrics.controlSize,
                    height: AppWindowChromeMetrics.controlSize
                )
        }
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
