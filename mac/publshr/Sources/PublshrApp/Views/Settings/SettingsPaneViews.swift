import SwiftUI
import UniformTypeIdentifiers

// MARK: - Updates

struct SettingsUpdatesPane: View {
    @EnvironmentObject private var updates: AppUpdateViewModel

    var body: some View {
        Form {
            Section("Live channel") {
                LabeledContent("Status", value: updates.statusLine)
                LabeledContent("Last sync", value: updates.lastSyncLine)
                LabeledContent("Installed build", value: "\(AppReleaseConfig.buildNumber)")
                LabeledContent("Shell", value: AppShellIdentity.distributionTag)
                Toggle("Auto-check every minute", isOn: $updates.autoCheckEnabled)
                    .onChange(of: updates.autoCheckEnabled) { _, on in
                        if on {
                            updates.startAutomaticChecks()
                        } else {
                            updates.stopAutomaticChecks()
                        }
                    }
                Toggle("Install updates automatically", isOn: $updates.autoInstallEnabled)
                Button("Sync now") {
                    Task { await updates.installLiveUpdateNow() }
                }
                .disabled(updates.isActivelyUpdating)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("App updates")
        .onAppear {
            if updates.autoCheckEnabled {
                updates.startAutomaticChecks()
            }
            Task { await updates.performLiveSync() }
        }
    }
}

// MARK: - Account

struct SettingsAccountPane: View {
    @EnvironmentObject private var auth: AuthViewModel
    @State private var showAvatarPicker = false
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
                            showAvatarPicker = true
                        }
                        .disabled(isUploadingAvatar)
                        Text("Shown in chat, calls, and spaces.")
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
        .fileImporter(
            isPresented: $showAvatarPicker,
            allowedContentTypes: [.jpeg, .png],
            allowsMultipleSelection: false
        ) { result in
            guard case .success(let urls) = result, let url = urls.first else { return }
            Task { await uploadAvatar(from: url) }
        }
    }

    private func uploadAvatar(from url: URL) async {
        isUploadingAvatar = true
        avatarError = nil
        defer { isUploadingAvatar = false }
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            let mime = url.pathExtension.lowercased() == "png" ? "image/png" : "image/jpeg"
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
                Toggle("Voice & video calls", isOn: .constant(subscription.features.callsEnabled)).disabled(true)
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
                Text("Chat and Spaces cache locally under ~/Library/Application Support/Publshr/ for offline access. Sign out removes your session from the Keychain.")
                    .font(.caption)
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
