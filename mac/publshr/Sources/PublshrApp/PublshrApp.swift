import SwiftUI

@main
struct PublshrApp: App {
    @StateObject private var auth = AuthViewModel()
    @StateObject private var chat = ChatViewModel()
    @StateObject private var updates = AppUpdateViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
                .environmentObject(chat)
                .environmentObject(updates)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    auth.handleIncomingURL(url)
                }
                .task {
                    updates.startAutomaticChecks()
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
                    Task { await updates.installAndRestart() }
                }
                .disabled(!updates.hasPendingUpdate)
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
}
