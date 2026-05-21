import SwiftUI

@main
struct PublshrApp: App {
    @StateObject private var auth = AuthViewModel()
    @StateObject private var chat = ChatViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
                .environmentObject(chat)
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
