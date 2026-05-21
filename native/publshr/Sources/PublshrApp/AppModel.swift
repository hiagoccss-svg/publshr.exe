import Foundation
import PublshrCore

struct DraftItem: Identifiable, Hashable {
    let id: UUID
    var title: String
    var subtitle: String
    var updatedAt: Date
}

@MainActor
final class AppModel: ObservableObject {
    @Published var drafts: [DraftItem] = [
        DraftItem(id: UUID(), title: "Welcome", subtitle: "Start publishing from your Mac", updatedAt: .now),
    ]
    @Published var selectedDraftID: DraftItem.ID?
    @Published var editorText: String = """
    # Welcome to Publshr

    Your publisher workspace on macOS — the same role as publshr.exe on Windows.

    Use the sidebar to manage drafts. Publishing tools will connect here as the app grows.
    """

    @Published var statusMessage: String = "Ready"
    @Published var preferOffline = false
    @Published var lastCommit: String = "—"
    @Published var isSyncing = false
    @Published var settingsUpdateNote: String = ""

    private let git = GitSync()

    init() {
        selectedDraftID = drafts.first?.id
        Task { await syncInBackground() }
    }

    var selectedDraft: DraftItem? {
        drafts.first { $0.id == selectedDraftID }
    }

    func createDraft() {
        let draft = DraftItem(
            id: UUID(),
            title: "Untitled draft",
            subtitle: "New",
            updatedAt: .now
        )
        drafts.insert(draft, at: 0)
        selectedDraftID = draft.id
        editorText = ""
    }

    func checkForUpdatesFromMenu() async {
        await performSync(showInSettings: true)
    }

    func syncInBackground() async {
        await performSync(showInSettings: false)
    }

    func syncFromSettings() async {
        await performSync(showInSettings: true)
    }

    private func performSync(showInSettings: Bool) async {
        isSyncing = true
        statusMessage = "Syncing…"

        let networkAvailable = await isNetworkAvailable()
        let offline = preferOffline || !networkAvailable
        let result = await git.sync(offline: offline)

        switch result {
        case .success(let sync):
            lastCommit = sync.commit ?? "—"
            statusMessage = sync.updated ? "Synced with GitHub" : "Ready"
            settingsUpdateNote = sync.message
            if showInSettings && sync.updated {
                settingsUpdateNote += "\nProject files updated in Application Support."
            }
        case .failure(let error):
            statusMessage = "Ready (offline)"
            settingsUpdateNote = error.localizedDescription
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
