import SwiftUI

@main
struct PublshrApp: App {
    @StateObject private var auth = AuthViewModel()
    @StateObject private var chat = ChatViewModel()
    @StateObject private var spaces = SpacesViewModel()
    @StateObject private var updates = AppUpdateViewModel()
    @StateObject private var subscription = SubscriptionService()
    @StateObject private var enterprise = EnterpriseWorkspaceService()
    @StateObject private var mediaMonitoring = MediaMonitoringViewModel()
    @StateObject private var tabStore = WorkspaceTabStore()
    @ObservedObject private var cloudHealth = CloudPlatformHealth.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        AppCrashReporter.install()
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(auth)
                .environmentObject(chat)
                .environmentObject(spaces)
                .environmentObject(updates)
                .environmentObject(subscription)
                .environmentObject(enterprise)
                .environmentObject(mediaMonitoring)
                .environmentObject(tabStore)
                .environmentObject(cloudHealth)
                .onOpenURL { url in
                    auth.handleIncomingURL(url)
                }
                .task {
                    configureLifecycle()
                    cloudHealth.startPolling(intervalSeconds: AppReleaseConfig.livePollIntervalSeconds)
                    updates.startAutomaticChecks()
                }
                .onChange(of: auth.flowState) { _, state in
                    if state == .signedIn {
                        Task { await performFullSync() }
                    }
                }
                .onChange(of: auth.selectedMembership?.workspace.id) { _, _ in
                    Task { await performCloudSync() }
                }
                .onReceive(NotificationCenter.default.publisher(for: .publshrPerformLiveSync)) { _ in
                    Task { await performFullSync() }
                }
                .onReceive(NotificationCenter.default.publisher(for: .publshrPerformCloudSync)) { _ in
                    Task { await performCloudSync() }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1280, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Button("Sync now") {
                    NotificationCenter.default.post(name: .publshrPerformLiveSync, object: nil)
                }
                .keyboardShortcut("u", modifiers: [.command, .shift])
                Button("Download and Install Latest") {
                    Task { await updates.installLiveUpdateNow() }
                }
                .keyboardShortcut("u", modifiers: [.command, .option])
            }
            CommandMenu("Spaces") {
                Button("New Space…") {
                    spaces.showNewSpaceSheet = true
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                Button("New Task") {
                    if spaces.newTaskTitle.isEmpty { spaces.newTaskTitle = "New task" }
                    Task { await spaces.createTask() }
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
                Divider()
                Button("Board") { spaces.taskView = .board }
                Button("List") { spaces.taskView = .list }
                Button("Overview") { spaces.taskView = .overview }
                Divider()
                Button("Refresh") { Task { await spaces.reload() } }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                Button(spaces.spacesFocusMode ? "Exit Focus" : "Focus on Space") {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        spaces.spacesFocusMode.toggle()
                    }
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
            }
            CommandMenu("View") {
                Button("Command Palette…") {
                    NotificationCenter.default.post(name: .publshrTitlebarCommandPalette, object: nil)
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
                Button("Command Palette…") {
                    NotificationCenter.default.post(name: .publshrTitlebarCommandPalette, object: nil)
                }
                .keyboardShortcut("k", modifiers: .command)
                Divider()
                Button(tabStore.sidebarExpanded ? "Hide Submenu" : "Show Submenu") {
                    NotificationCenter.default.post(name: .publshrTitlebarToggleSidebar, object: nil)
                }
                .keyboardShortcut("\\", modifiers: .command)
                Button("Notifications") {
                    NotificationCenter.default.post(name: .publshrTitlebarNotifications, object: nil)
                }
                Divider()
                Button("Settings…") {
                    NotificationCenter.default.post(name: .publshrOpenSettings, object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            CommandMenu("Chat") {
                Button("New Chat") {
                    NotificationCenter.default.post(name: .publshrTitlebarNewChat, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
                Button(tabStore.sidebarExpanded ? "Hide Chat Sidebar" : "Show Chat Sidebar") {
                    NotificationCenter.default.post(name: .publshrTitlebarToggleSidebar, object: nil)
                }
                .keyboardShortcut("\\", modifiers: .command)
                Divider()
                Button("Search…") {
                    NotificationCenter.default.post(name: .publshrTitlebarSearch, object: nil)
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])
                Button("AI Assistant") {
                    chat.showAISheet = true
                }
                Button("Pop Out Channel") {
                    if auth.isAuthenticated {
                        chat.popOutCurrentChannel(auth: auth)
                    }
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
                Divider()
                Button("Paste from Clipboard") {
                    Task { await chat.pasteFromClipboard() }
                }
                .keyboardShortcut("v", modifiers: [.command, .shift])
                Button("Notification Settings…") {
                    chat.showNotificationSettings = true
                }
            }
        }
    }

    @MainActor
    private func performFullSync() async {
        await updates.performLiveSync(forceGitHub: true)
        await performCloudSync()
    }

    @MainActor
    private func performCloudSync() async {
        guard !CloudSyncGate.inFlight else { return }
        CloudSyncGate.inFlight = true
        defer { CloudSyncGate.inFlight = false }

        guard auth.flowState == .signedIn else {
            updates.recordCloudSync(summary: "Not signed in")
            return
        }
        if !auth.isCloudValidated {
            await auth.reconcileCloudSession(unlockMethod: nil)
        }
        await auth.refreshSupabaseConnection()
        async let chatSync = chat.refreshAfterReconnect()
        async let spacesSync = spaces.reload()
        async let enterpriseSync = syncEnterpriseServices()
        await chatSync
        await spacesSync
        await enterpriseSync
        updates.recordCloudSync(summary: auth.supabaseStatusLine)
    }

    @MainActor
    private func syncEnterpriseServices() async {
        guard auth.flowState == .signedIn else { return }
        await subscription.refresh(client: auth.client, workspace: auth.selectedWorkspace)
        if let uid = auth.profile?.id {
            await DeviceIdentityService.register(
                client: auth.client,
                userId: uid,
                workspaceId: auth.selectedWorkspace?.id
            )
            await enterprise.loadDevices(client: auth.client, userId: uid)
        }
    }

    private func configureLifecycle() {
        Task {
            await ChatNotificationService.shared.requestAuthorizationIfNeeded()
        }
        ChatNotificationService.shared.onNotificationTap = { channelId in
            guard auth.isAuthenticated else { return }
            chat.selectChannelById(channelId)
            NSApp.activate(ignoringOtherApps: true)
            if let channel = chat.selectedChannel {
                ChatWindowManager.shared.openChannel(channel, chat: chat, auth: auth)
            }
        }
        ChatNotificationService.shared.onNotificationQuickReply = { channelId, text in
            guard auth.isAuthenticated else { return }
            NSApp.activate(ignoringOtherApps: true)
            Task {
                await chat.sendQuickReply(channelId: channelId, text: text)
            }
        }
        ChatWindowManager.shared.onSelectChannelInIDE = { channelId in
            chat.selectChannelById(channelId)
        }
        ChatIncomingMessagePopupManager.shared.onOpenChannel = { channelId in
            guard auth.isAuthenticated else { return }
            NSApp.activate(ignoringOtherApps: true)
            chat.selectChannelById(channelId)
            if ChatUserPreferences.popupOpensChannelWindow,
               let channel = (chat.channels + chat.directMessages).first(where: { $0.id == channelId }) {
                ChatWindowManager.shared.openChannel(channel, chat: chat, auth: auth)
            }
        }
        ChatIncomingMessagePopupManager.shared.onQuickReply = { channelId, text in
            guard auth.isAuthenticated else { return }
            NSApp.activate(ignoringOtherApps: true)
            Task { await chat.sendQuickReply(channelId: channelId, text: text) }
        }
        AppLifecycleService.shared.onWake = {
            Task { await performFullSync() }
        }
        AppLifecycleService.shared.onNetworkRestored = {
            Task { await performFullSync() }
        }
        AppLifecycleService.shared.start()
    }
}

@MainActor
private enum CloudSyncGate {
    static var inFlight = false
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            await ChatNotificationService.shared.requestAuthorizationIfNeeded()
        }
        if let frame = AppWindowStateStore.loadMainWindowFrame(),
           let window = NSApp.windows.first {
            window.setFrame(frame, display: true)
        }
        DispatchQueue.main.async {
            for window in NSApp.windows {
                MainWindowChrome.applyWithRetries(to: window)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            for window in NSApp.windows {
                MainWindowChrome.applyWithRetries(to: window)
            }
        }
        NotificationCenter.default.post(name: .publshrPerformLiveSync, object: nil)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        MainWindowPresenter.restoreMainWindow()
        return true
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        ChatNotificationFocusState.shared.setAppActive(true)
        if NSApp.windows.contains(where: { $0.isMiniaturized }) {
            MainWindowPresenter.restoreMainWindow()
        } else {
            MainWindowChrome.apply(to: NSApp.mainWindow ?? NSApp.windows.first)
        }
        NotificationCenter.default.post(name: .publshrPerformLiveSync, object: nil)
    }

    func applicationDidResignActive(_ notification: Notification) {
        ChatNotificationFocusState.shared.setAppActive(false)
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let window = NSApp.mainWindow ?? NSApp.windows.first {
            AppWindowStateStore.saveMainWindowFrame(window.frame)
        }
        ChatWindowManager.shared.closeAll()
        WorkspaceModuleWindowManager.shared.closeAll()
        AppLifecycleService.shared.stop()
    }
}
