import SwiftUI

@main
struct PublshrApp: App {
    @StateObject private var auth = AuthViewModel()
    @StateObject private var chat = ChatViewModel()
    @StateObject private var spaces = SpacesViewModel()
    @StateObject private var updates = AppUpdateViewModel()
    @StateObject private var subscription = SubscriptionService()
    @StateObject private var enterprise = EnterpriseWorkspaceService()
    @StateObject private var calls = CallSignalingService()
    @StateObject private var tabStore = WorkspaceTabStore()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        AppCrashReporter.install()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
                .environmentObject(chat)
                .environmentObject(spaces)
                .environmentObject(updates)
                .environmentObject(subscription)
                .environmentObject(enterprise)
                .environmentObject(calls)
                .environmentObject(tabStore)
                .onOpenURL { url in
                    auth.handleIncomingURL(url)
                }
                .task {
                    configureLifecycle()
                    updates.startAutomaticChecks()
                }
                .onChange(of: auth.flowState) { _, state in
                    if state == .signedIn {
                        Task { await performFullSync() }
                    } else {
                        calls.detach()
                    }
                }
                .onChange(of: auth.selectedMembership?.workspace.id) { _, _ in
                    Task { await syncEnterpriseServices() }
                }
                .onReceive(NotificationCenter.default.publisher(for: .publshrPerformLiveSync)) { _ in
                    Task { await performFullSync() }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1280, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Button("Download and Install Latest") {
                    Task { await updates.installLiveUpdateNow() }
                }
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
                    spaces.spacesFocusMode.toggle()
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
            }
            CommandMenu("Chat") {
                Button("Search…") {
                    chat.showSearchSheet = true
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
            }
        }
    }

    @MainActor
    private func performFullSync() async {
        await updates.performLiveSync()
        guard auth.flowState == .signedIn else { return }
        await auth.refreshSupabaseConnection()
        await chat.refreshAfterReconnect()
        await spaces.reload()
        await chat.loadPlannerTasks()
        await syncEnterpriseServices()
    }

    @MainActor
    private func syncEnterpriseServices() async {
        guard auth.flowState == .signedIn else { return }
        await subscription.refresh(client: auth.client, workspace: auth.selectedWorkspace)
        if let uid = auth.profile?.id {
            calls.attach(client: auth.client, userId: uid)
            await DeviceIdentityService.register(
                client: auth.client,
                userId: uid,
                workspaceId: auth.selectedWorkspace?.id
            )
            await enterprise.loadDevices(client: auth.client, userId: uid)
        }
    }

    private func configureLifecycle() {
        ChatNotificationService.shared.onNotificationTap = { channelId in
            guard auth.isAuthenticated else { return }
            chat.selectChannelById(channelId)
            NSApp.activate(ignoringOtherApps: true)
            if let channel = chat.selectedChannel {
                ChatWindowManager.shared.openChannel(channel, chat: chat, auth: auth)
            }
        }
        ChatWindowManager.shared.onSelectChannelInIDE = { channelId in
            chat.selectChannelById(channelId)
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

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let frame = AppWindowStateStore.loadMainWindowFrame(),
           let window = NSApp.windows.first {
            window.setFrame(frame, display: true)
        }
        DispatchQueue.main.async {
            MainWindowChrome.apply(to: NSApp.mainWindow ?? NSApp.windows.first)
        }
        NotificationCenter.default.post(name: .publshrPerformLiveSync, object: nil)
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        NotificationCenter.default.post(name: .publshrPerformLiveSync, object: nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let window = NSApp.mainWindow ?? NSApp.windows.first {
            AppWindowStateStore.saveMainWindowFrame(window.frame)
        }
        ChatWindowManager.shared.closeAll()
        AppLifecycleService.shared.stop()
    }
}
