import SwiftUI

struct MainIDEView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var spaces: SpacesViewModel
    @EnvironmentObject private var updates: AppUpdateViewModel
    @EnvironmentObject private var subscription: SubscriptionService
    @EnvironmentObject private var enterprise: EnterpriseWorkspaceService
    @EnvironmentObject private var calls: CallSignalingService
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @AppStorage("publshr.selectedModule") private var storedModule = AppModule.chat.rawValue
    @State private var module: AppModule = .chat
    @State private var showNewChannel = false
    @State private var showNewDM = false

    private var sidebarHidden: Bool {
        !tabStore.sidebarExpanded
            || (module == .chat && chat.chatFocusMode)
            || (module == .spaces && spaces.spacesFocusMode)
    }

    var body: some View {
        GeometryReader { geometry in
            let topSafe = geometry.safeAreaInsets.top
            VStack(spacing: 0) {
                WorkspaceHeaderView(
                    spaces: spaces,
                    module: $module,
                    safeAreaTop: topSafe
                )

                HStack(alignment: .top, spacing: 0) {
                    if !sidebarHidden {
                        leftRail
                    }

                    mainColumn
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea(.container, edges: .top)
        .glassWorkspace()
        .background(WindowChromeConfigurator())
        .onAppear {
            _ = AppShellIdentity.distributionTag
            if let restored = AppModule(rawValue: storedModule), restored != .settings {
                module = restored
            } else if storedModule == AppModule.settings.rawValue {
                module = .chat
                storedModule = AppModule.chat.rawValue
            }
            tabStore.removeSettingsTabs()
            tabStore.ensureDefaultTabs(module: module)
            tabStore.openFromModule(module, activate: true)
            chat.attach(auth: auth)
            spaces.attach(auth: auth)
        }
        .onChange(of: module) { _, newModule in
            guard newModule != .settings else {
                module = .chat
                return
            }
            storedModule = newModule.rawValue
            if newModule != .chat { chat.chatFocusMode = false }
            if newModule != .spaces { spaces.spacesFocusMode = false }
            if newModule == .chat { chat.attach(auth: auth) }
            if newModule == .spaces { spaces.attach(auth: auth) }
            tabStore.openFromModule(newModule, activate: true)
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
            if module == .spaces {
                spaces.attach(auth: auth)
            }
            if module == .chat {
                chat.attach(auth: auth)
            }
        }
        .sheet(isPresented: $showNewChannel) { newChannelSheet }
        .sheet(isPresented: $showNewDM) { newDMSheet }
        .onReceive(NotificationCenter.default.publisher(for: .publshrOpenSettings)) { _ in
            WorkspaceModuleWindowManager.shared.openSettings(
                auth: auth,
                chat: chat,
                spaces: spaces,
                updates: updates,
                subscription: subscription,
                enterprise: enterprise,
                calls: calls
            )
        }
    }

    private var leftRail: some View {
        HStack(spacing: 0) {
            ActivityBarView(module: $module)

            AppSecondarySidebar(
                module: module,
                chat: chat,
                spaces: spaces,
                showNewChannel: $showNewChannel,
                showNewDM: $showNewDM
            )
        }
        .frame(maxHeight: .infinity)
    }

    private var mainColumn: some View {
        VStack(spacing: 0) {
            moduleMainContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            ContentStatusFooter(module: module)
                .frame(height: CursorTheme.statusBarHeight)
        }
        .frame(maxHeight: .infinity)
        .background(module == .chat ? CursorTheme.chatBackground : CursorTheme.editorBackground)
    }

    @ViewBuilder
    private var moduleMainContent: some View {
        switch module {
        case .chat:
            if subscription.canUseChat(workspace: auth.selectedWorkspace) {
                EnterpriseChatView(chat: chat, topInset: 0)
                    .onAppear { chat.attach(auth: auth) }
            } else {
                EnterpriseModuleGate(
                    moduleName: "Chat",
                    planName: subscription.features.planName
                )
            }
        case .spaces:
            if subscription.canUseSpaces(workspace: auth.selectedWorkspace) {
                SpacesRootView(spaces: spaces, topInset: 0)
            } else {
                EnterpriseModuleGate(
                    moduleName: "Spaces",
                    planName: subscription.features.planName
                )
            }
        case .settings:
            EnterpriseModuleGate(
                moduleName: "Settings",
                planName: subscription.features.planName
            )
        }
    }

    private var newChannelSheet: some View {
        NewChannelSheet(chat: chat, isPresented: $showNewChannel)
    }

    private var newDMSheet: some View {
        NewDMSheet(chat: chat, isPresented: $showNewDM)
    }
}

// MARK: - Sheets (shared with sidebar actions)

private struct NewChannelSheet: View {
    @ObservedObject var chat: ChatViewModel
    @Binding var isPresented: Bool
    @State private var name = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create Channel").font(.headline)
            TextField("Channel name", text: $name)
                .textFieldStyle(.roundedBorder)
            HStack {
                Spacer()
                Button("Cancel") { isPresented = false }
                Button("Create") {
                    Task {
                        await chat.createChannel(name: name)
                        isPresented = false
                    }
                }
            }
        }
        .padding(24)
        .frame(width: 360)
    }
}

private struct NewDMSheet: View {
    @ObservedObject var chat: ChatViewModel
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New Message").font(.headline)
            List(Array(chat.profiles.values).sorted { ($0.displayName ?? $0.email) < ($1.displayName ?? $1.email) }) { profile in
                if profile.id != chat.currentUserId {
                    Button {
                        Task {
                            await chat.openDM(with: profile)
                            isPresented = false
                        }
                    } label: {
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
                    .buttonStyle(.plain)
                }
            }
            .frame(minHeight: 200)
            Button("Close") { isPresented = false }
        }
        .padding(20)
        .frame(width: 320, height: 360)
    }
}
