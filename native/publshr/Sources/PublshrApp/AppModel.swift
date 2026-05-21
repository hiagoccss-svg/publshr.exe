import Foundation
import PublshrCore

enum AppSection: String, CaseIterable, Identifiable {
    case publisher = "Publisher"
    case updates = "Updates"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .publisher: return "square.and.arrow.up.on.square.fill"
        case .updates: return "arrow.triangle.2.circlepath"
        }
    }
}

@MainActor
final class AppModel: ObservableObject {
    @Published var selectedSection: AppSection = .publisher

    @Published var installPath: String = ""
    @Published var isInstalledInApplications = false

    @Published var statusLine = "Ready"
    @Published var detailText = "Updates run inside Publshr when you are online."
    @Published var commitLabel = "—"
    @Published var isSyncing = false
    @Published var preferOffline = false
    @Published var updateAvailable = false

    private let git = GitSync()

    init() {
        refreshInstallStatus()
        Task { await checkForUpdatesInBackground() }
    }

    func refreshInstallStatus() {
        let bundle = Bundle.main.bundlePath
        installPath = bundle
        isInstalledInApplications =
            bundle.contains("/Applications/") || bundle.contains("/applications/")
    }

    func checkForUpdatesInBackground() async {
        await performSync(silent: true)
    }

    func checkForUpdatesNow() async {
        selectedSection = .updates
        await performSync(silent: false)
    }

    func syncNow() async {
        await performSync(silent: false)
    }

    private func performSync(silent: Bool) async {
        isSyncing = true
        if !silent {
            statusLine = "Checking for updates…"
        }

        let networkAvailable = await isNetworkAvailable()
        let offline = preferOffline || !networkAvailable
        let result = await git.sync(offline: offline)

        switch result {
        case .success(let sync):
            updateAvailable = sync.updated
            statusLine = sync.updated ? "Update synced" : "Up to date"
            detailText = sync.message
            commitLabel = sync.commit ?? "—"
            if sync.updated && !silent {
                detailText += "\n\nRepo synced to Application Support. To refresh this app binary after a release, run ./install-mac-app.sh again."
            }
        case .failure(let error):
            statusLine = "Update check failed"
            detailText = error.localizedDescription
            updateAvailable = false
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
