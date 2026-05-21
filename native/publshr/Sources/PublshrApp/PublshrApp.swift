import SwiftUI

@main
struct PublshrApplication: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 560, minHeight: 420)
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
