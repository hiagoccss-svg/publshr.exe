import SwiftUI

@main
struct PublshrApp: App {
    @StateObject private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    auth.handleIncomingURL(url)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1280, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
