import SwiftUI

@main
struct PublshrApplication: App {
    @NSApplicationDelegateAdaptor(MacAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("Publshr") {
            RootView()
        }
        .defaultSize(width: 1280, height: 800)

        Settings {
            SettingsView()
        }
    }
}
