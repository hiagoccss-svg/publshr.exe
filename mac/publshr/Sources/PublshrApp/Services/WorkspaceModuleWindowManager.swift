import AppKit
import SwiftUI

@MainActor
final class WorkspaceModuleWindowManager: ObservableObject {
    static let shared = WorkspaceModuleWindowManager()

    private var windows: [AppModule: NSWindow] = [:]

    func open(
        module: AppModule,
        chat: ChatViewModel,
        spaces: SpacesViewModel,
        auth: AuthViewModel,
        subscription: SubscriptionService
    ) {
        if let existing = windows[module] {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let root: AnyView = {
            switch module {
            case .chat:
                return AnyView(
                    EnterpriseChatView(chat: chat, topInset: 12, embedInPopOut: true)
                        .environmentObject(auth)
                        .environmentObject(subscription)
                )
            case .spaces:
                return AnyView(
                    SpacesRootView(spaces: spaces, topInset: 12, embedInPopOut: true)
                        .environmentObject(auth)
                )
            case .settings:
                return AnyView(SettingsRootView().environmentObject(auth))
            }
        }()

        let hosting = NSHostingController(rootView: root.frame(minWidth: 900, minHeight: 640))
        let window = NSWindow(contentViewController: hosting)
        window.title = module.label
        window.setContentSize(NSSize(width: 1100, height: 760))
        window.center()
        window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        window.isReleasedWhenClosed = false

        windows[module] = window

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.windows.removeValue(forKey: module)
            }
        }

        window.makeKeyAndOrderFront(nil)
    }

    func closeAll() {
        windows.values.forEach { $0.close() }
        windows.removeAll()
    }
}
