import AppKit
import SwiftUI

@MainActor
final class WorkspaceModuleWindowManager: ObservableObject {
    static let shared = WorkspaceModuleWindowManager()

    private var windows: [AppModule: NSWindow] = [:]
    private(set) var pendingSettingsSection: SettingsSection?

    func consumePendingSettingsSection() -> SettingsSection? {
        defer { pendingSettingsSection = nil }
        return pendingSettingsSection
    }

    func openSettings(
        auth: AuthViewModel,
        chat: ChatViewModel,
        spaces: SpacesViewModel,
        updates: AppUpdateViewModel,
        subscription: SubscriptionService,
        enterprise: EnterpriseWorkspaceService,
        section: SettingsSection? = nil
    ) {
        pendingSettingsSection = section
        open(
            module: .settings,
            chat: chat,
            spaces: spaces,
            auth: auth,
            subscription: subscription,
            updates: updates,
            enterprise: enterprise
        )
        Task { await updates.performLiveSync(forceGitHub: true) }
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
            case .spaces, .whiteboard:
                return AnyView(
                    SpacesRootView(spaces: spaces, topInset: 12, embedInPopOut: true)
                        .environmentObject(auth)
                )
            case .mediaMonitoring:
                return AnyView(
                    MediaMonitoringModuleView()
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
