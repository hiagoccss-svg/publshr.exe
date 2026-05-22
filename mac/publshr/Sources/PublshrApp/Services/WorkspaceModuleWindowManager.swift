import AppKit
import SwiftUI

@MainActor
final class WorkspaceModuleWindowManager: ObservableObject {
    static let shared = WorkspaceModuleWindowManager()

    private var windows: [AppModule: NSWindow] = [:]

    func openSettings(
        auth: AuthViewModel,
        chat: ChatViewModel,
        spaces: SpacesViewModel,
        updates: AppUpdateViewModel,
        subscription: SubscriptionService,
        enterprise: EnterpriseWorkspaceService,
        calls: CallSignalingService
    ) {
        open(
            module: .settings,
            chat: chat,
            spaces: spaces,
            auth: auth,
            subscription: subscription,
            updates: updates,
            enterprise: enterprise,
            calls: calls
        )
        Task { await updates.performLiveSync() }
    }

    func open(
        module: AppModule,
        chat: ChatViewModel,
        spaces: SpacesViewModel,
        auth: AuthViewModel,
        subscription: SubscriptionService,
        updates: AppUpdateViewModel? = nil,
        enterprise: EnterpriseWorkspaceService? = nil,
        calls: CallSignalingService? = nil
    ) {
        if let existing = windows[module] {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let root: AnyView = {
            switch module {
            case .chat:
                let chatRoot = EnterpriseChatView(chat: chat, topInset: 12, embedInPopOut: true)
                    .environmentObject(auth)
                    .environmentObject(subscription)
                if let calls {
                    return AnyView(chatRoot.environmentObject(calls))
                }
                return AnyView(chatRoot)
            case .spaces:
                return AnyView(
                    SpacesRootView(spaces: spaces, topInset: 12, embedInPopOut: true)
                        .environmentObject(auth)
                )
            case .settings:
                guard let updates, let enterprise, let calls else {
                    return AnyView(Text("Settings unavailable").padding())
                }
                return AnyView(
                    SettingsRootView()
                        .environmentObject(auth)
                        .environmentObject(chat)
                        .environmentObject(spaces)
                        .environmentObject(subscription)
                        .environmentObject(updates)
                        .environmentObject(enterprise)
                        .environmentObject(calls)
                )
            }
        }()

        let hosting = NSHostingController(rootView: root.frame(minWidth: 900, minHeight: 640))
        let window = NSWindow(contentViewController: hosting)
        window.title = module == .settings ? "Publshr Settings" : module.label
        let size = module == .settings ? NSSize(width: 920, height: 680) : NSSize(width: 1100, height: 760)
        window.setContentSize(size)
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
