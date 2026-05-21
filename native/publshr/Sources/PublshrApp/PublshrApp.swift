import SwiftUI

@main
struct PublshrApplication: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            AppSpaceRootView()
                .environmentObject(model)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Task") {
                    NotificationCenter.default.post(name: .publshrNewTask, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .defaultSize(width: 1280, height: 800)
    }
}

extension Notification.Name {
    static let publshrNewTask = Notification.Name("publshr.newTask")
}
