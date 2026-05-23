import SwiftUI
import UniformTypeIdentifiers

// MARK: - Updates

struct SettingsUpdatesPane: View {
    @EnvironmentObject private var updates: AppUpdateViewModel
    @EnvironmentObject private var cloudHealth: CloudPlatformHealth

    var body: some View {
        Form {
            Section("Cloud platform (required)") {
                LabeledContent("GitHub live", value: cloudHealth.isGitHubReachable ? "Reachable" : "Unreachable")
                LabeledContent("Supabase API", value: cloudHealth.isSupabaseReachable ? "Reachable" : "Unreachable")
                if let live = cloudHealth.liveVersionLine {
                    LabeledContent("Remote build", value: live)
                }
                if let err = cloudHealth.lastErrorLine {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Text("Publshr runs on GitHub (app updates) and Supabase (your data). Nothing on this Mac is required except the installed app binary and your sign-in session.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Check GitHub + Supabase now") {
                    Task { await cloudHealth.refresh() }
                }
            }
            Section("GitHub live channel") {
                LabeledContent("Status", value: updates.githubStatusLine)
                LabeledContent("Update phase", value: updates.statusLine)
                LabeledContent("Installed", value: AppReleaseConfig.installedLabel)
                LabeledContent("Installed build", value: "\(AppReleaseConfig.buildNumber)")
                LabeledContent("Installed shell", value: AppReleaseConfig.liveShellTag)
                LabeledContent("Installed commit", value: commitLabel(AppReleaseConfig.liveCommit))
                LabeledContent("Package digest", value: digestLabel(AppReleaseConfig.livePackageDigest))
                LabeledContent("Remote (live)", value: remoteDetailLabel)
                Toggle("Auto-check every 30 seconds", isOn: $updates.autoCheckEnabled)
                    .onChange(of: updates.autoCheckEnabled) { _, on in
                        if on {
                            updates.startAutomaticChecks()
                        } else {
                            updates.stopAutomaticChecks()
                        }
                    }
                Toggle("Install updates automatically", isOn: $updates.autoInstallEnabled)
            }
            Section("Supabase (cloud data)") {
                LabeledContent("Cloud sync", value: updates.cloudSyncLine)
                Text("GitHub updates the app shell only. Supabase holds Chat, Spaces, and enterprise data — refreshed in parallel every 30 seconds (or Sync now).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section {
                Button(updates.settingsActionTitle) {
                    NotificationCenter.default.post(name: .publshrPerformLiveSync, object: nil)
                }
                .disabled(updates.isActivelyUpdating)
                if let err = updates.settingsErrorMessage {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("App updates")
        .onAppear {
            NotificationCenter.default.post(name: .publshrPerformLiveSync, object: nil)
        }
    }

    private var remoteDetailLabel: String {
        if let remote = updates.remoteManifest {
            return remote.detailLabel
        }
        return "— (check live channel)"
    }

    private func commitLabel(_ commit: String) -> String {
        if commit.isEmpty { return "—" }
        return String(commit.prefix(7))
    }

    private func digestLabel(_ digest: String) -> String {
        if digest.isEmpty { return "— (recorded after next live install)" }
        return String(digest.prefix(12)) + "…"
    }
}

// MARK: - Storage

struct SettingsStoragePane: View {
    var body: some View {
        Form {
            Section("GitHub (app delivery)") {
                LabeledContent("Channel", value: AppReleaseConfig.liveTag)
                LabeledContent("Installed build", value: "\(AppReleaseConfig.buildNumber)")
                Text("Downloads and installs only Publshr.app. Never touches your chat or spaces cache.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("This Mac (optional speed cache)") {
                LabeledContent("Root", value: LocalDataLayout.applicationSupportRoot.path)
                LabeledContent("Chat cache", value: LocalDataLayout.chatDatabase.lastPathComponent)
                LabeledContent("Spaces cache", value: LocalDataLayout.spacesDatabase.lastPathComponent)
                LabeledContent("Auth snapshot", value: LocalDataLayout.authOfflineSnapshot.lastPathComponent)
                Text("Not required when online. Supabase is always the source of truth; local SQLite only speeds up the UI and allows brief offline reading.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Supabase (source of truth)") {
                Text("Profiles, workspaces, messages, spaces, tasks, devices, and billing live in your Supabase project. The Mac keeps a cache for offline read and fast UI.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section {
                Button("Reveal Application Support in Finder") {
                    LocalDataLayout.ensureRootExists()
                    NSWorkspace.shared.activateFileViewerSelecting([LocalDataLayout.applicationSupportRoot])
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Storage")
    }
}

// MARK: - Account

struct SettingsAccountPane: View {
    @EnvironmentObject private var auth: AuthViewModel
    @State private var isUploadingAvatar = false
    @State private var avatarError: String?

    var body: some View {
        Form {
            Section("Profile photo") {
                HStack(spacing: 14) {
                    ChatProfileAvatar(
                        profile: auth.profile,
                        displayName: auth.profile?.displayName ?? auth.profile?.email ?? "You",
                        size: 56,
                        presence: nil
                    )
                    VStack(alignment: .leading, spacing: 6) {
                        Button(isUploadingAvatar ? "Uploading…" : "Upload photo") {
                            Task { await pickAndUploadAvatar() }
                        }
                        .disabled(isUploadingAvatar)
                        Text("Shown in chat and spaces.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let avatarError {
                            Text(avatarError)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            Section("Profile") {
                if let p = auth.profile {
                    LabeledContent("Name", value: p.displayName ?? "—")
                    LabeledContent("Email", value: p.email)
                }
            }
            Section {
                Button("Sign out", role: .destructive) { Task { await auth.signOut() } }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Account")
    }

    private func pickAndUploadAvatar() async {
        guard let url = await ProfileImagePicker.pickImage() else { return }
        isUploadingAvatar = true
        avatarError = nil
        defer { isUploadingAvatar = false }
        do {
            let (data, mime) = try ProfileImagePicker.loadImageData(from: url)
            try await auth.uploadAvatar(data: data, mimeType: mime)
        } catch {
            avatarError = error.localizedDescription
        }
    }
}

// MARK: - Workspace

struct SettingsWorkspacePane: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var enterprise: EnterpriseWorkspaceService

    var body: some View {
        Form {
            Section("Current workspace") {
                if let ws = auth.selectedWorkspace {
                    LabeledContent("Name", value: ws.name)
                    LabeledContent("Plan", value: ws.planId)
                }
                if !auth.workspaceMemberships.isEmpty {
                    Picker("Switch workspace", selection: Binding(
                        get: { auth.selectedMembership?.id ?? UUID() },
                        set: { id in
                            if let m = auth.workspaceMemberships.first(where: { $0.id == id }) {
                                auth.switchWorkspace(m)
                            }
                        }
                    )) {
                        ForEach(auth.workspaceMemberships) { m in
                            Text(m.workspace.name).tag(m.id)
                        }
                    }
                }
            }
            if auth.selectedMembership?.role == .owner || auth.selectedMembership?.role == .admin {
                Section("Invite member") {
                    TextField("Email address", text: $enterprise.inviteEmail)
                    Button("Send invite") {
                        guard let ws = auth.selectedWorkspace?.id else { return }
                        Task {
                            await enterprise.inviteMember(client: auth.client, workspaceId: ws, email: enterprise.inviteEmail)
                        }
                    }
                    if let err = enterprise.errorMessage {
                        Text(err).font(.caption).foregroundStyle(.red)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Workspace")
    }
}

// MARK: - Billing

struct SettingsBillingPane: View {
    @EnvironmentObject private var subscription: SubscriptionService
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        Form {
            Section("Current plan") {
                LabeledContent("Plan", value: subscription.features.planName)
                LabeledContent("Price", value: subscription.features.priceLabel)
                LabeledContent("Seats", value: "\(subscription.memberCount) / \(subscription.features.seatLimit)")
            }
            Section("Included") {
                Toggle("Chat", isOn: .constant(subscription.features.chatEnabled)).disabled(true)
                Toggle("Spaces", isOn: .constant(subscription.features.spacesEnabled)).disabled(true)
            }
            if let msg = subscription.billingMessage {
                Section {
                    Text(msg).foregroundStyle(.orange)
                }
            }
            Section {
                Text("Subscription billing is managed per workspace. Contact your administrator to upgrade from Trial to Team or Enterprise.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Link("Manage subscription (web)", destination: URL(string: "https://publshr.com/billing")!)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Subscription")
        .task {
            await subscription.refresh(client: auth.client, workspace: auth.selectedWorkspace)
        }
    }
}

// MARK: - Privacy

struct SettingsPrivacyPane: View {
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        Form {
            Section("Legal") {
                LabeledContent("Privacy policy", value: PrivacyConsentStore.hasAcceptedPrivacyPolicy ? "Accepted" : "Required")
                if let date = PrivacyConsentStore.acceptedAt {
                    LabeledContent("Accepted", value: date.formatted(date: .abbreviated, time: .shortened))
                }
                Link("Privacy policy", destination: PrivacyConsentStore.privacyPolicyURL)
                Link("Terms of service", destination: PrivacyConsentStore.termsURL)
            }
            Section("Data on this Mac") {
                Text("GitHub delivers the app. Supabase holds your workspace data. This Mac caches chat and spaces under Application Support for offline read. See Settings → Storage for paths.")
                    .font(.caption)
                Text("Sign out clears your session (Keychain) and offline auth snapshot. Chat/Spaces SQLite caches remain until you clear them manually.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section {
                Button("Re-accept privacy policy") {
                    PrivacyConsentStore.reset()
                    if let uid = auth.profile?.id {
                        Task { await PrivacyConsentStore.logAcceptance(client: auth.client, userId: uid, workspaceId: auth.selectedWorkspace?.id) }
                    }
                    PrivacyConsentStore.accept()
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Privacy")
    }
}

// MARK: - Devices

struct SettingsDevicesPane: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var enterprise: EnterpriseWorkspaceService

    var body: some View {
        Form {
            Section("This Mac") {
                let info = DeviceIdentityService.current
                LabeledContent("Name", value: info.deviceName)
                LabeledContent("Model", value: info.modelIdentifier)
                LabeledContent("App", value: info.appVersion)
                LabeledContent("Device ID", value: String(info.deviceKey.prefix(12)) + "…")
            }
            Section("Registered devices") {
                if enterprise.devices.isEmpty {
                    Text("No devices registered yet.")
                } else {
                    ForEach(enterprise.devices) { d in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(d.deviceName).font(.headline)
                                Text("\(d.platform) · \(d.appVersion)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if d.isThisDevice {
                                Text("This Mac")
                                    .font(.caption.weight(.semibold))
                            }
                        }
                    }
                }
                Button("Refresh") {
                    guard let uid = auth.profile?.id else { return }
                    Task { await enterprise.loadDevices(client: auth.client, userId: uid) }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Devices")
        .task {
            guard let uid = auth.profile?.id else { return }
            await enterprise.loadDevices(client: auth.client, userId: uid)
            await DeviceIdentityService.register(client: auth.client, userId: uid, workspaceId: auth.selectedWorkspace?.id)
        }
    }
}

// MARK: - Files

struct SettingsFilesPane: View {
    @State private var exportFolder: String = "Not set"

    var body: some View {
        Form {
            Section("Local file access") {
                Text("Publshr uses the native macOS open panel when you attach files in Chat or Spaces. Selected files are read with security-scoped access when required.")
                    .font(.caption)
                Button("Test file picker") {
                    let urls = FileAccessService.pickFiles()
                    if let first = urls.first?.lastPathComponent {
                        exportFolder = "Last: \(first)"
                    }
                }
                LabeledContent("Last selection", value: exportFolder)
                Button("Choose export folder") {
                    if let url = FileAccessService.pickFolder() {
                        FileAccessService.saveBookmark(for: url, key: "export")
                        exportFolder = url.path
                    }
                }
            }
            Section("Cache") {
                Text("~/Library/Application Support/Publshr/")
                    .font(.system(.caption, design: .monospaced))
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Files")
        .onAppear {
            if let url = FileAccessService.resolveBookmark(key: "export") {
                exportFolder = url.path
            }
        }
    }
}

// MARK: - Security

struct SettingsSecurityPane: View {
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        Form {
            Section("Session") {
                Text("Sessions are stored in the macOS Keychain (accessible only when unlocked).")
                    .font(.caption)
                if auth.isAuthenticated, !auth.isCloudValidated {
                    Text("Offline unlock is active. Permissions refresh automatically when Supabase reconnects.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if BiometricAuthService.isAvailable {
                Section(BiometricAuthService.biometricLabel) {
                    Toggle(isOn: Binding(
                        get: { auth.biometricUnlockEnabled },
                        set: { auth.setBiometricUnlockEnabled($0) }
                    )) {
                        Text("Quick unlock with \(BiometricAuthService.biometricLabel)")
                    }
                    if auth.prefersBiometricUnlock {
                        Text("You will be asked for \(BiometricAuthService.biometricLabel) when opening Publshr.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Security")
    }
}

// MARK: - Chat

struct SettingsChatPane: View {
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var enterprise: EnterpriseWorkspaceService

    var body: some View {
        Form {
            Section("Workspace permissions") {
                Button("Edit chat permissions…") { chat.showPermissionsSheet = true }
                Button("Save permissions to cloud") {
                    Task {
                        guard var ws = chat.workspace else { return }
                        do {
                            try await enterprise.persistChatPermissions(
                                client: auth.client,
                                workspace: &ws,
                                permissions: chat.permissions
                            )
                            chat.workspace = ws
                        } catch {
                            chat.errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Chat")
        .sheet(isPresented: $chat.showPermissionsSheet) {
            ChatPermissionsSheet(chat: chat)
        }
    }
}
