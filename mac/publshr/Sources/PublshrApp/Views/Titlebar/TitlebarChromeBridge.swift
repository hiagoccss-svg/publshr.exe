import AppKit
import SwiftUI

/// Connects SwiftUI environment objects to the AppKit titlebar accessory host.
@MainActor
final class TitlebarChromeBridge: ObservableObject {
    static let shared = TitlebarChromeBridge()

    static let accessoryIdentifier = NSUserInterfaceItemIdentifier("PublshrUnifiedTitlebar")

    private(set) var isRegistered = false

    var tabStore: WorkspaceTabStore!
    var auth: AuthViewModel!
    var chat: ChatViewModel!
    var subscription: SubscriptionService!
    var calls: CallSignalingService!
    var spaces: SpacesViewModel!

    @Published var module: AppModule = .chat
    @Published var showNewChannel = false
    @Published var showNewDM = false
    @Published var showCommandPalette = false
    @Published var showNotificationsPanel = false

    private weak var installedWindow: NSWindow?

    private init() {}

    func register(
        tabStore: WorkspaceTabStore,
        auth: AuthViewModel,
        chat: ChatViewModel,
        spaces: SpacesViewModel,
        subscription: SubscriptionService,
        calls: CallSignalingService,
        module: AppModule
    ) {
        self.tabStore = tabStore
        self.auth = auth
        self.chat = chat
        self.spaces = spaces
        self.subscription = subscription
        self.calls = calls
        self.module = module
        isRegistered = true
        if let installedWindow {
            installTitlebarAccessory(on: installedWindow)
        }
    }

    func syncModule(_ module: AppModule) {
        guard self.module != module else { return }
        self.module = module
    }

    func attachWindow(_ window: NSWindow) {
        installedWindow = window
        guard isRegistered else { return }
        installTitlebarAccessory(on: window)
    }

    func installTitlebarAccessory(on window: NSWindow) {
        guard isRegistered else { return }

        MainWindowChrome.apply(to: window)

        if let existing = window.titlebarAccessoryViewControllers.first(where: {
            $0.identifier == Self.accessoryIdentifier
        }) {
            resizeAccessory(existing, window: window)
            return
        }

        let accessory = NSTitlebarAccessoryViewController()
        accessory.identifier = Self.accessoryIdentifier
        accessory.layoutAttribute = .left
        accessory.fullScreenMinHeight = AppWindowChromeMetrics.trafficLightRowHeight

        let root = TitlebarChromeAccessoryRoot()
            .environmentObject(tabStore)
            .environmentObject(auth)
            .environmentObject(chat)
            .environmentObject(subscription)
            .environmentObject(calls)

        let hosting = NSHostingView(rootView: AnyView(root))
        hosting.translatesAutoresizingMaskIntoConstraints = false
        // Do not set x/y inside SwiftUI — frame only via Auto Layout (macOS 15+ hit-testing).

        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hosting)

        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: container.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        accessory.view = container
        window.addTitlebarAccessoryViewController(accessory)
        resizeAccessory(accessory, window: window)
    }

    private func resizeAccessory(_ accessory: NSTitlebarAccessoryViewController, window: NSWindow) {
        let height = AppWindowChromeMetrics.trafficLightRowHeight
        let width = max(window.frame.width - AppWindowChromeMetrics.trafficLightLeadingInset, 320)
        accessory.view.setFrameSize(NSSize(width: width, height: height))
        accessory.fullScreenMinHeight = height
    }
}

/// Hosted inside `NSTitlebarAccessoryViewController` — same row as traffic lights.
struct TitlebarChromeAccessoryRoot: View {
    @ObservedObject private var bridge = TitlebarChromeBridge.shared

    var body: some View {
        Group {
            if bridge.isRegistered {
                LibraryShellHeaderView(
                    spaces: bridge.spaces,
                    module: $bridge.module,
                    showNewChannel: $bridge.showNewChannel,
                    showNewDM: $bridge.showNewDM,
                    showCommandPalette: $bridge.showCommandPalette,
                    showNotificationsPanel: $bridge.showNotificationsPanel,
                    reservesTrafficLightLeadingInset: false
                )
            }
        }
        .frame(
            maxWidth: .infinity,
            minHeight: AppWindowChromeMetrics.trafficLightRowHeight,
            maxHeight: AppWindowChromeMetrics.trafficLightRowHeight
        )
    }
}
