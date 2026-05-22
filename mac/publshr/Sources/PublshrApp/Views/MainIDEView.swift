import AppKit
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

    @ObservedObject private var titlebar = TitlebarChromeBridge.shared

    var body: some View {
        LibraryShellView(
            module: $module,
            showNewChannel: $titlebar.showNewChannel,
            showNewDM: $titlebar.showNewDM,
            showCommandPalette: $titlebar.showCommandPalette,
            showNotificationsPanel: $titlebar.showNotificationsPanel
        )
        .background(WindowChromeConfigurator())
        .background { TitlebarChromeShortcutBridge() }
        .onAppear(perform: onShellAppear)
        .onChange(of: module) { _, newModule in
            titlebar.syncModule(newModule)
            onModuleChange(newModule)
        }
        .onChange(of: titlebar.module) { _, newModule in
            guard module != newModule else { return }
            module = newModule
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
            if module == .spaces { spaces.attach(auth: auth) }
            if module == .chat { chat.attach(auth: auth) }
        }
        .sheet(isPresented: $titlebar.showNewChannel) { newChannelSheet }
        .sheet(isPresented: $titlebar.showNewDM) { newDMSheet }
        .sheet(isPresented: $titlebar.showCommandPalette) {
            TitlebarCommandPaletteView(
                items: TitlebarChromeCommands.paletteItems(
                    tabStore: tabStore,
                    auth: auth,
                    chat: chat,
                    spaces: spaces,
                    module: $module,
                    showNewChannel: $titlebar.showNewChannel,
                    showNewDM: $titlebar.showNewDM,
                    showCommandPalette: $titlebar.showCommandPalette,
                    showNotificationsPanel: $titlebar.showNotificationsPanel
                ),
                isPresented: $titlebar.showCommandPalette
            )
        }
        .sheet(isPresented: $titlebar.showNotificationsPanel) {
            TitlebarNotificationsPanelView(chat: chat, isPresented: $titlebar.showNotificationsPanel)
        }
        .onReceive(NotificationCenter.default.publisher(for: .publshrTitlebarToggleSidebar)) { _ in
            withAnimation(.easeInOut(duration: 0.15)) { tabStore.sidebarExpanded.toggle() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .publshrTitlebarNewChat)) { _ in
            module = .chat
            tabStore.openFromModule(.chat, activate: true)
            if chat.selectedChannel != nil {
                titlebar.showNewChannel = true
            } else {
                chat.selectedChannel = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .publshrTitlebarCommandPalette)) { _ in
            titlebar.showCommandPalette = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .publshrTitlebarSearch)) { _ in
            if module == .chat { chat.openWorkspaceSearch(scope: .workspace) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .publshrTitlebarNotifications)) { _ in
            titlebar.showNotificationsPanel = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .publshrTitlebarNavigateBack)) { _ in
            if module == .chat { chat.navigateBack() }
            else { Task { await spaces.navigateBack() } }
        }
        .onReceive(NotificationCenter.default.publisher(for: .publshrTitlebarNavigateForward)) { _ in
            if module == .chat { chat.navigateForward() }
            else { Task { await spaces.navigateForward() } }
        }
        .onReceive(NotificationCenter.default.publisher(for: .publshrOpenSettings)) { _ in
            WorkspaceModuleWindowManager.shared.openSettings(
                auth: auth,
                chat: chat,
                spaces: spaces,
                updates: updates,
                subscription: subscription,
                enterprise: enterprise
            )
        }
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
        chat.attach(auth: auth)
        chat.applyWorkspaceContext(
            workspace: auth.selectedWorkspace,
            permissions: auth.workspaceChatPermissions,
            auth: auth
        )
        spaces.attach(auth: auth)
        titlebar.register(
            tabStore: tabStore,
            auth: auth,
            chat: chat,
            spaces: spaces,
            subscription: subscription,
            module: module
        )
        if let window = NSApp.keyWindow ?? NSApp.windows.first(where: { $0.isVisible }) {
            MainWindowChrome.applyWithRetries(to: window)
        }
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
            if newModule != .spaces { spaces.spacesFocusMode = false }
        }
        if newModule == .chat { chat.attach(auth: auth) }
        if newModule == .spaces { spaces.attach(auth: auth) }
        tabStore.openFromModule(newModule, activate: true)
    }

    private var newChannelSheet: some View {
        NewChannelSheet(chat: chat, isPresented: $titlebar.showNewChannel)
    }

    private var newDMSheet: some View {
        NewDMSheet(chat: chat, isPresented: $titlebar.showNewDM)
    }
}

// MARK: - Sheets

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
