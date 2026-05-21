import Foundation
import PublshrCore

@MainActor
final class AppModel: ObservableObject {
    @Published var statusLine = "Ready"
    @Published var detailText = "Publisher helper for macOS. Works offline; syncs from Git when online."
    @Published var commitLabel = "—"
    @Published var isSyncing = false
    @Published var preferOffline = false

    private let git = GitSync()

    init() {
        Task { await syncOnLaunch() }
    }

    func syncOnLaunch() async {
        await performSync(silent: true)
    }

    func checkForUpdates() async {
        await performSync(silent: false)
    }

    private func performSync(silent: Bool) async {
        isSyncing = true
        if !silent {
            statusLine = "Checking GitHub…"
        }

        let offline = preferOffline || !(await isNetworkAvailable())
        let result = await git.sync(offline: offline)

        switch result {
        case .success(let sync):
            statusLine = sync.updated ? "Up to date with Git" : "Ready"
            detailText = sync.message
            commitLabel = sync.commit ?? "—"
        case .failure(let error):
            statusLine = "Sync skipped"
            detailText = error.localizedDescription
        }

        isSyncing = false
    }

    private func isNetworkAvailable() async -> Bool {
        guard let url = URL(string: "https://github.com") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 4
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }
            return (200...399).contains(http.statusCode)
        } catch {
            return false
        }
    }
}
