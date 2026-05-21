import SwiftUI

@main
struct PublshrApplication: App {
    @NSApplicationDelegateAdaptor(MacAppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("Publshr") {
            AppShellView()
                .environmentObject(model)
        }
        .defaultSize(width: 1280, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New channel") { model.createChannel() }
                    .keyboardShortcut("n", modifiers: .command)
                Button("New space") { model.createSpace() }
                    .keyboardShortcut("n", modifiers: [.command, .shift])
            }
            CommandGroup(after: .sidebar) {
                Button("Chat") { model.section = .chat }
                    .keyboardShortcut("1", modifiers: .command)
                Button("Spaces") { model.section = .spaces }
                    .keyboardShortcut("2", modifiers: .command)
            }
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    Task { await model.checkForUpdatesFromMenu() }
                }
            }
        }

        Settings {
            SettingsView()
                .environmentObject(model)
        }
    }
}
