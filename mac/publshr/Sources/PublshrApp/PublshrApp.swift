import SwiftUI

@main
struct PublshrApp: App {
    @StateObject private var auth = AuthViewModel()
    @StateObject private var chat = ChatViewModel()
    @StateObject private var spaces = SpacesViewModel()
    @StateObject private var updates = AppUpdateViewModel()
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
                .onOpenURL { url in
                    auth.handleIncomingURL(url)
                }
                .task {
                    configureLifecycle()
                    updates.startAutomaticChecks()
                }
                .onChange(of: auth.flowState) { _, state in
                    if state == .signedIn {
                        Task { await updates.syncLiveBuildIfNeeded() }
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1280, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    Task { await updates.checkForUpdates(silent: false) }
                }
                Button("Install Update and Restart") {
                    Task { await updates.updateNow() }
                }
                .disabled({
                    switch updates.phase {
                    case .checking, .downloading, .installing:
                        return true
                    default:
                        return false
                    }
                }())
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
            Task { await chat.refreshAfterReconnect() }
        }
        AppLifecycleService.shared.onNetworkRestored = {
            Task { await chat.refreshAfterReconnect() }
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
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let window = NSApp.mainWindow ?? NSApp.windows.first {
            AppWindowStateStore.saveMainWindowFrame(window.frame)
        }
        ChatWindowManager.shared.closeAll()
        AppLifecycleService.shared.stop()
    }
}
