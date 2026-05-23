import SwiftUI

/// Signed-in root — delegates to `LibraryShellView` (Pinterest / library glass reference).
struct MainIDEView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var spaces: SpacesViewModel
    @EnvironmentObject private var updates: AppUpdateViewModel
    @EnvironmentObject private var subscription: SubscriptionService
    @EnvironmentObject private var enterprise: EnterpriseWorkspaceService
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @AppStorage("publshr.selectedModule") private var storedModule = AppModule.chat.rawValue
    @State private var module: AppModule = .chat

    @State private var showNewChannel = false
    @State private var showNewDM = false
    @State private var showCommandPalette = false
    @State private var showNotificationsPanel = false
    @State private var profilePresentation: WorkspaceProfilePresentation?

    var body: some View {
        LibraryShellView(
            module: $module,
            showNewChannel: $showNewChannel,
            showNewDM: $showNewDM,
            showCommandPalette: $showCommandPalette,
            showNotificationsPanel: $showNotificationsPanel,
            profilePresentation: $profilePresentation
        )
        .environmentObject(TrafficLightLayoutStore.shared)
        .background(WindowChromeConfigurator())
        .background { TitlebarChromeShortcutBridge() }
        .onAppear(perform: onShellAppear)
        .onChange(of: module) { _, newModule in
            onModuleChange(newModule)
        }
        .onChange(of: tabStore.selectedTabId) { _, _ in
            tabStore.applySelection(module: &module, chat: chat, spaces: spaces)
            if let tab = tabStore.selectedTab, case .app(let m) = tab.kind {
                storedModule = m.rawValue
            }
        }
        .onChange(of: chat.selectedChannel?.id) { _, _ in
            tabStore.reflectChannelSelection(chat.selectedChannel)
            tabStore.syncTabMetadata(chat: chat, spaces: spaces)
        }
        .onChange(of: spaces.selectedSpaceId) { _, _ in
            tabStore.reflectSpaceSelection(spaces.selectedSpace)
            tabStore.syncTabMetadata(chat: chat, spaces: spaces)
        }
        .onChange(of: auth.selectedMembership?.workspace.id) { _, _ in
            if module.usesSpacesSubmenu { spaces.attach(auth: auth) }
            if module == .chat { chat.attach(auth: auth) }
        }
        .sheet(isPresented: $showNewChannel) { newChannelSheet }
        .sheet(isPresented: $showNewDM) { newDMSheet }
        .sheet(isPresented: $showCommandPalette) {
            TitlebarCommandPaletteView(
                items: TitlebarChromeCommands.paletteItems(
                    tabStore: tabStore,
                    auth: auth,
                    chat: chat,
                    spaces: spaces,
                    module: $module,
                    showNewChannel: $showNewChannel,
                    showNewDM: $showNewDM,
                    showCommandPalette: $showCommandPalette,
                    showNotificationsPanel: $showNotificationsPanel
                ),
                isPresented: $showCommandPalette
            )
        }
        .sheet(isPresented: $showNotificationsPanel) {
            TitlebarNotificationsPanelView(chat: chat, isPresented: $showNotificationsPanel)
        }
        .sheet(item: $profilePresentation) { _ in
            WorkspaceProfileSheet(
                presentation: $profilePresentation,
                module: $module
            )
        }
        .sheet(isPresented: $spaces.showNewSpaceSheet) {
            SpacesNewSpaceSheet(spaces: spaces)
        }
        .onReceive(NotificationCenter.default.publisher(for: .publshrTitlebarToggleSidebar)) { _ in
            withAnimation(.easeInOut(duration: 0.15)) { tabStore.sidebarExpanded.toggle() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .publshrTitlebarNewChat)) { _ in
            module = .chat
            tabStore.openFromModule(.chat, activate: true)
            if chat.selectedChannel != nil {
                showNewChannel = true
            } else {
                chat.selectedChannel = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .publshrTitlebarNewDM)) { _ in
            module = .chat
            tabStore.openFromModule(.chat, activate: true)
            showNewDM = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .publshrTitlebarCommandPalette)) { _ in
            showCommandPalette = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .publshrTitlebarSearch)) { _ in
            if module == .chat { chat.openWorkspaceSearch() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .publshrTitlebarNotifications)) { _ in
            showNotificationsPanel = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .publshrTitlebarNavigateBack)) { _ in
            if module == .chat { chat.navigateBack() }
            else { Task { await spaces.navigateBack() } }
        }
        .onReceive(NotificationCenter.default.publisher(for: .publshrTitlebarNavigateForward)) { _ in
            if module == .chat { chat.navigateForward() }
            else { Task { await spaces.navigateForward() } }
        }
        .onReceive(NotificationCenter.default.publisher(for: .publshrOpenSettings)) { output in
            let section = (output.object as? String).flatMap { SettingsSection(rawValue: $0) }
            WorkspaceModuleWindowManager.shared.openSettings(
                auth: auth,
                chat: chat,
                spaces: spaces,
                updates: updates,
                subscription: subscription,
                enterprise: enterprise,
                section: section
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func onShellAppear() {
        _ = AppShellIdentity.distributionTag
        if let restored = AppModule(rawValue: storedModule), restored != .settings {
            module = restored
        } else {
            module = .chat
            storedModule = AppModule.chat.rawValue
        }
        tabStore.removeSettingsTabs()
        tabStore.ensureDefaultTabs(module: module)
        tabStore.openFromModule(module, activate: true)
        tabStore.sidebarExpanded = true
        tabStore.barMenuExpanded = true
        chat.attach(auth: auth)
        chat.applyWorkspaceContext(
            workspace: auth.selectedWorkspace,
            permissions: auth.workspaceChatPermissions,
            auth: auth
        )
        spaces.attach(auth: auth)
        Task {
            await subscription.refresh(client: auth.client, workspace: auth.selectedWorkspace)
            if chat.channels.isEmpty, chat.directMessages.isEmpty {
                await chat.refreshAfterReconnect()
            }
            if spaces.spaces.isEmpty, auth.selectedWorkspace != nil {
                await spaces.reload()
            }
        }
    }

    private func onModuleChange(_ newModule: AppModule) {
        guard newModule != .settings else {
            module = .chat
            return
        }
        storedModule = newModule.rawValue
        withAnimation(.easeInOut(duration: 0.15)) {
            if newModule != .chat { chat.chatFocusMode = false }
            if !newModule.usesSpacesSubmenu { spaces.spacesFocusMode = false }
        }
        if newModule == .chat { chat.attach(auth: auth) }
        if newModule.usesSpacesSubmenu {
            spaces.attach(auth: auth)
            applySpacesModulePresentation(newModule)
        }
        tabStore.openFromModule(newModule, activate: true)
    }

    private func applySpacesModulePresentation(_ newModule: AppModule) {
        switch newModule {
        case .whiteboard:
            spaces.taskView = .whiteboard
            if spaces.selectedSpaceId == nil, let first = spaces.spaces.first {
                Task { await spaces.selectSpace(first.id) }
            } else if let id = spaces.selectedSpaceId {
                Task { await spaces.loadWhiteboards(for: id) }
            }
        case .spaces:
            if spaces.taskView == .whiteboard, let id = spaces.selectedSpaceId {
                spaces.taskView = spaces.defaultView(for: id)
            }
        default:
            break
        }
    }

    private var newChannelSheet: some View {
        NewChannelSheet(chat: chat, isPresented: $showNewChannel)
    }

    private var newDMSheet: some View {
        NewDMSheet(chat: chat, isPresented: $showNewDM)
    }
}

// MARK: - Sheets

private struct NewChannelSheet: View {
    @ObservedObject var chat: ChatViewModel
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var description = ""
    @State private var visibility: ChatChannelVisibility = .public

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create channel").font(.headline)
            TextField("Name (e.g. approvals)", text: $name)
                .textFieldStyle(.plain)
                .macInlineTextField()
            TextField("Topic / description (optional)", text: $description, axis: .vertical)
                .textFieldStyle(.plain)
                .macInlineTextField()
                .lineLimit(2...3)
            Picker("Who can access", selection: $visibility) {
                Text("Public").tag(ChatChannelVisibility.public)
                Text("Private").tag(ChatChannelVisibility.private)
                Text("Internal").tag(ChatChannelVisibility.internal)
                Text("Announcement").tag(ChatChannelVisibility.announcement)
                Text("Read-only").tag(ChatChannelVisibility.readOnly)
            }
            .pickerStyle(.menu)
            Text("Workspace permissions still apply to invites and posting.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("Cancel") { isPresented = false }
                Button("Create") {
                    Task {
                        await chat.createChannel(
                            name: name,
                            visibility: visibility,
                            description: description.isEmpty ? nil : description
                        )
                        isPresented = false
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(MacSystemChrome.sheetPadding)
        .frame(width: 400)
        .macNativeSheetPresentation()
    }
}

private struct NewDMSheet: View {
    @ObservedObject var chat: ChatViewModel
    @Binding var isPresented: Bool
    @State private var groupMode = false
    @State private var selectedIds: Set<UUID> = []

    private var sortedProfiles: [Profile] {
        Array(chat.profiles.values)
            .filter { $0.id != chat.currentUserId }
            .sorted { ($0.displayName ?? $0.email) < ($1.displayName ?? $1.email) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(groupMode ? "New group message" : "New message").font(.headline)
                Spacer()
                if chat.permissions.canCreateGroupChats {
                    Picker("", selection: $groupMode) {
                        Text("Direct").tag(false)
                        Text("Group").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }
            }

            if groupMode {
                Text("Select two or more people, then start the group.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            List(sortedProfiles) { profile in
                if groupMode {
                    Toggle(isOn: binding(for: profile.id)) {
                        profileRow(profile)
                    }
                } else {
                    Button {
                        Task {
                            await chat.openDM(with: profile)
                            isPresented = false
                        }
                    } label: {
                        profileRow(profile)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(minHeight: 200)

            HStack {
                Button("Close") { isPresented = false }
                Spacer()
                if groupMode {
                    Button("Start group") {
                        let picks = sortedProfiles.filter { selectedIds.contains($0.id) }
                        Task {
                            await chat.openGroupDM(with: picks)
                            isPresented = false
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(selectedIds.count < 2)
                }
            }
        }
        .padding(MacSystemChrome.sheetPadding)
        .frame(width: 360, height: 400)
        .macNativeSheetPresentation()
    }

    private func profileRow(_ profile: Profile) -> some View {
        HStack {
            ChatProfileAvatar(
                profile: profile,
                displayName: profile.displayName ?? profile.email,
                size: 28,
                presence: chat.presence(for: profile.id)
            )
            Text(profile.displayName ?? profile.email)
        }
    }

    private func binding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { selectedIds.contains(id) },
            set: { on in
                if on { selectedIds.insert(id) } else { selectedIds.remove(id) }
            }
        )
    }
}
