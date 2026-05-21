import SwiftUI

@main
struct PublshrApplication: App {
    @NSApplicationDelegateAdaptor(MacAppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("Publshr") {
            MainWorkspaceView()
                .environmentObject(model)
        }
        .defaultSize(width: 1100, height: 720)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New draft") { model.createDraft() }
                    .keyboardShortcut("n", modifiers: .command)
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
