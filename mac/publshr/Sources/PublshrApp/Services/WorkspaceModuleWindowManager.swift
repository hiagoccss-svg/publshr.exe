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
        enterprise: EnterpriseWorkspaceService
    ) {
        open(
            module: .settings,
            chat: chat,
            spaces: spaces,
            auth: auth,
            subscription: subscription,
            updates: updates,
            enterprise: enterprise
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
        enterprise: EnterpriseWorkspaceService? = nil
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
                guard let updates, let enterprise else {
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
                )
            }
        }()

        let hosting = NSHostingController(rootView: root.frame(minWidth: 900, minHeight: 640))
        let window = NSWindow(contentViewController: hosting)
        window.title = module.windowTitle
        window.setContentSize(NSSize(width: 1100, height: 720))
        window.center()
        window.makeKeyAndOrderFront(nil)
        windows[module] = window
    }

    func closeAll() {
        for window in windows.values {
            window.close()
        }
        windows.removeAll()
    }
}

private extension AppModule {
    var windowTitle: String {
        switch self {
        case .chat: "Publshr Chat"
        case .spaces: "Publshr Spaces"
        case .settings: "Publshr Settings"
        }
    }
}
