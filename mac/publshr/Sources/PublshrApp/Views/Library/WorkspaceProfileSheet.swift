import SwiftUI
import UniformTypeIdentifiers

/// Workspace profile — edit your photo/name or view teammates and start a DM.
struct WorkspaceProfileSheet: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @Binding var presentation: WorkspaceProfilePresentation?
    @Binding var module: AppModule

    @State private var editedName = ""
    @State private var isSavingName = false
    @State private var isUploadingAvatar = false
    @State private var errorMessage: String?

    private var isOwnProfile: Bool {
        guard case .currentUser = presentation else { return false }
        return true
    }

    private var memberProfile: Profile? {
        guard case .member(let userId) = presentation else { return nil }
        return chat.profile(for: userId)
    }

    private var viewedProfile: Profile? {
        if isOwnProfile { return auth.profile }
        return memberProfile
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    profileHeader
                    if isOwnProfile {
                        editProfileSection
                        statusSection
                        accountActionsSection
                    } else if let member = memberProfile {
                        teammateActions(member)
                    }
                    teamSection
                }
                .padding(20)
            }
            .navigationTitle(isOwnProfile ? "Your profile" : "Team member")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { presentation = nil }
                }
            }
        }
        .frame(minWidth: 420, minHeight: 480)
        .onAppear(perform: loadEditorState)
        .onChange(of: presentation) { _, _ in loadEditorState() }
    }

    @ViewBuilder
    private var profileHeader: some View {
        if let profile = viewedProfile {
            HStack(alignment: .top, spacing: 16) {
                ChatProfileAvatar(
                    profile: profile,
                    displayName: profile.displayName ?? profile.email,
                    size: 72,
                    presence: isOwnProfile ? chat.myStatus : chat.presence(for: profile.id)
                )
                VStack(alignment: .leading, spacing: 6) {
                    Text(profile.displayName ?? "No name yet")
                        .font(.system(size: 18, weight: .semibold))
                    Text(profile.email)
                        .font(.system(size: 13))
                        .foregroundStyle(LibraryGlassDesign.inkSecondary)
                    if !isOwnProfile {
                        HStack(spacing: 4) {
                            ChatPresenceDot(status: chat.presence(for: profile.id), size: 8)
                            Text(chat.presence(for: profile.id).label)
                                .font(.system(size: 12))
                                .foregroundStyle(LibraryGlassDesign.inkMuted)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        } else if case .member(let userId) = presentation {
            Text("Profile not loaded")
                .font(.headline)
            Text(userId.uuidString)
                .font(.caption)
                .foregroundStyle(LibraryGlassDesign.inkMuted)
        }
    }

    private var editProfileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Profile")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(LibraryGlassDesign.inkMuted)
                .tracking(0.5)

            TextField("Display name", text: $editedName)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 12) {
                Button(isUploadingAvatar ? "Uploading…" : "Change photo") {
                    Task { await pickAndUploadAvatar() }
                }
                .disabled(isUploadingAvatar)

                Button(isSavingName ? "Saving…" : "Save name") {
                    Task { await saveDisplayName() }
                }
                .disabled(isSavingName || editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var accountActionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("Account in Settings") {
                presentation = nil
                NotificationCenter.default.post(
                    name: .publshrOpenSettings,
                    object: SettingsSection.account.rawValue
                )
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(LibraryGlassDesign.inkSecondary)

            Button("Sign out", role: .destructive) {
                presentation = nil
                Task { await auth.signOut() }
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .medium))
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(LibraryGlassDesign.inkMuted)
                .tracking(0.5)
            ForEach(ChatPresenceStatus.allCases.filter { $0 != .invisible }, id: \.self) { status in
                Button {
                    Task { await chat.setStatus(status) }
                } label: {
                    HStack {
                        ChatPresenceDot(status: status, size: 8)
                        Text(status.label)
                        Spacer()
                        if chat.myStatus == status {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .semibold))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func teammateActions(_ profile: Profile) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if chat.permissions.canDM {
                Button {
                    Task { await messageTeammate(profile) }
                } label: {
                    Label("Message", systemImage: "bubble.left.and.bubble.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Text("Direct messages are disabled for your role in this workspace.")
                    .font(.caption)
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
            }
        }
    }

    private var teamSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Workspace team")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(LibraryGlassDesign.inkMuted)
                .tracking(0.5)

            let teammates = sortedTeammates
            if teammates.isEmpty {
                Text("No teammates loaded yet.")
                    .font(.system(size: 12))
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
            } else {
                ForEach(teammates) { profile in
                    teammateRow(profile)
                }
            }
        }
    }

    private var sortedTeammates: [Profile] {
        Array(chat.profiles.values)
            .sorted { ($0.displayName ?? $0.email).localizedCaseInsensitiveCompare($1.displayName ?? $1.email) == .orderedAscending }
    }

    private func teammateRow(_ profile: Profile) -> some View {
        let isSelf = profile.id == chat.currentUserId
        let isViewing = {
            if case .member(let id) = presentation { return id == profile.id }
            return isOwnProfile && isSelf
        }()

        return HStack(spacing: 8) {
            Button {
                if isSelf {
                    presentation = .currentUser
                } else {
                    presentation = .member(profile.id)
                }
            } label: {
                HStack(spacing: 10) {
                    ChatProfileAvatar(
                        profile: profile,
                        displayName: profile.displayName ?? profile.email,
                        size: 36,
                        presence: isSelf ? chat.myStatus : chat.presence(for: profile.id)
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(profile.displayName ?? profile.email)
                                .font(.system(size: 13, weight: isViewing ? .semibold : .regular))
                                .foregroundStyle(LibraryGlassDesign.ink)
                            if isSelf {
                                Text("You")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(LibraryGlassDesign.inkMuted)
                            }
                        }
                        Text(profile.email)
                            .font(.system(size: 11))
                            .foregroundStyle(LibraryGlassDesign.inkMuted)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    if isViewing {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(LibraryGlassDesign.inkSecondary)
                    }
                }
            }
            .buttonStyle(.plain)

            if !isSelf, chat.permissions.canDM {
                Button {
                    Task { await messageTeammate(profile) }
                } label: {
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(LibraryGlassDesign.inkSecondary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .help("Message")
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isViewing ? LibraryGlassDesign.sidebarSelection.opacity(0.5) : Color.clear)
        )
    }

    private func loadEditorState() {
        editedName = auth.profile?.displayName ?? ""
        errorMessage = nil
    }

    private func saveDisplayName() async {
        isSavingName = true
        errorMessage = nil
        defer { isSavingName = false }
        do {
            try await auth.updateDisplayName(editedName)
            if let profile = auth.profile {
                chat.upsertProfile(profile)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func pickAndUploadAvatar() async {
        guard let url = await ProfileImagePicker.pickImage() else { return }
        isUploadingAvatar = true
        errorMessage = nil
        defer { isUploadingAvatar = false }
        do {
            let (data, mime) = try ProfileImagePicker.loadImageData(from: url)
            try await auth.uploadAvatar(data: data, mimeType: mime)
            if let profile = auth.profile {
                chat.upsertProfile(profile)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func messageTeammate(_ profile: Profile) async {
        module = .chat
        tabStore.openFromModule(.chat, activate: true)
        tabStore.sidebarExpanded = true
        await chat.openDM(with: profile)
        presentation = nil
    }
}
