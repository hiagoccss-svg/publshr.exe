import SwiftUI

/// Traffic-header trailing actions — profile, notifications, command palette.
struct TitlebarChromeActionBar: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @Binding var module: AppModule
    @Binding var showCommandPalette: Bool
    @Binding var showNotificationsPanel: Bool

    @State private var isUploadingAvatar = false
    @State private var avatarUploadError: String?

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
            profileMenu

            TitlebarChromeIconButton(
                systemName: "bell",
                help: "Notifications",
                badgeCount: module == .chat ? min(chat.totalUnread, 99) : 0
            ) {
                showNotificationsPanel = true
            }

            TitlebarChromeIconButton(
                systemName: "command",
                help: TitlebarShortcutHint.tooltip("Command palette", shortcut: TitlebarShortcutHint.commandPalette)
            ) {
                showCommandPalette = true
            }
        }
    }

    private var profileMenu: some View {
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
            Button(isUploadingAvatar ? "Uploading photo…" : "Upload profile photo") {
                Task { await uploadProfilePhoto() }
            }
            .disabled(isUploadingAvatar)
            Button("Account & profile") {
                NotificationCenter.default.post(name: .publshrOpenSettings, object: SettingsSection.account.rawValue)
            }
            Button("Workspace settings") {
                NotificationCenter.default.post(name: .publshrOpenSettings, object: SettingsSection.workspace.rawValue)
            }
            if module == .chat {
                Button("Chat permissions") {
                    chat.showPermissionsSheet = true
                }
            }
            Divider()
            Button("Sign out", role: .destructive) {
                Task { await auth.signOut() }
            }
        } label: {
            if let profile = auth.profile {
                ChatProfileAvatar(
                    profile: profile,
                    displayName: profile.displayName ?? profile.email,
                    size: AppWindowChromeMetrics.controlSize,
                    presence: chat.myStatus
                )
            } else {
                TitlebarChromeMenuLabel(title: "Account", systemImage: "person.crop.circle")
            }
        }
        .menuStyle(.borderlessButton)
        .help("Profile, photo upload & presence")
    }

    private func uploadProfilePhoto() async {
        guard auth.session != nil else {
            avatarUploadError = "Sign in to upload a photo."
            return
        }
        guard let url = FileAccessService.pickImage() else { return }
        isUploadingAvatar = true
        avatarUploadError = nil
        defer { isUploadingAvatar = false }
        do {
            let data = try FileAccessService.readData(from: url)
            let mime = url.pathExtension.lowercased() == "png" ? "image/png" : "image/jpeg"
            try await auth.uploadAvatar(data: data, mimeType: mime)
            if let profile = auth.profile {
                chat.upsertProfile(profile)
            }
            avatarUploadError = nil
            auth.infoMessage = "Profile photo updated."
        } catch {
            avatarUploadError = error.localizedDescription
            auth.errorMessage = error.localizedDescription
        }
    }
}

private extension String {
    var nonEmptyOrNil: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
