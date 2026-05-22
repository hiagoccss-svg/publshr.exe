import AppKit
import Foundation

/// Handles sleep/wake and network reachability for session restore and chat reconnect.
@MainActor
final class AppLifecycleService: ObservableObject {
    static let shared = AppLifecycleService()

    @Published private(set) var isNetworkReachable = true

    var onWake: (() -> Void)?
    var onNetworkRestored: (() -> Void)?

    private var observers: [NSObjectProtocol] = []
    private var pathMonitor: Any?

    private init() {}

    func start() {
        stop()
        let center = NSWorkspace.shared.notificationCenter
        observers.append(center.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { _ in
            // App will suspend; realtime channels pause automatically.
        })
        observers.append(center.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.onWake?()
        })

        // Lightweight reachability via periodic HEAD (no extra framework).
        Task { await pollReachabilityLoop() }
    }

    func stop() {
        for token in observers {
            NSWorkspace.shared.notificationCenter.removeObserver(token)
        }
        observers.removeAll()
    }

    private func pollReachabilityLoop() async {
        while !Task.isCancelled {
            async let githubReachable = checkHEADReachable("https://github.com")
            async let supabaseReachable = checkHEADReachable(SupabaseConfig.url.absoluteString)
            let githubUp = await githubReachable
            let supabaseUp = await supabaseReachable
            let reachable = githubUp || supabaseUp
            let wasOffline = !isNetworkReachable
            isNetworkReachable = reachable
            if reachable && wasOffline {
                onNetworkRestored?()
            }
            try? await Task.sleep(nanoseconds: 30_000_000_000)
        }
    }

    private func checkHEADReachable(_ urlString: String) async -> Bool {
        guard let url = URL(string: urlString) else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 8
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }
            return (200 ... 499).contains(http.statusCode)
        } catch {
            return false
        }
    }
}
