import Foundation
import PublshrCore

// PublshrCore: ChatChannel, ChatMessage, Space, LocalStore

enum MainSection: String, CaseIterable, Identifiable {
    case chat = "Chat"
    case spaces = "Spaces"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .spaces: return "square.grid.2x2.fill"
        }
    }
}

@MainActor
final class AppModel: ObservableObject {
    @Published var section: MainSection = .chat
    @Published var workspace: WorkspaceData
    @Published var selectedChannelID: UUID?
    @Published var selectedSpaceID: UUID?
    @Published var selectedListID: UUID?
    @Published var chatInput: String = ""
    @Published var sidebarSearch: String = ""
    @Published var preferOffline = false
    @Published var statusMessage = "Ready"
    @Published var lastCommit = "—"
    @Published var isSyncing = false
    @Published var settingsUpdateNote = ""

    private let git = GitSync()

    init() {
        workspace = LocalStore.load()
        if workspace.spaces.isEmpty && workspace.channels.isEmpty {
            workspace = LocalStore.defaultWorkspace()
            persist()
        }
        selectedChannelID = workspace.channels.first?.id
        selectedSpaceID = workspace.spaces.first?.id
        Task { await syncInBackground() }
    }

    var filteredChannels: [ChatChannel] {
        let q = sidebarSearch.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return workspace.channels }
        return workspace.channels.filter { $0.name.lowercased().contains(q) }
    }

    var channelMessages: [ChatMessage] {
        guard let id = selectedChannelID else { return [] }
        return workspace.messages
            .filter { $0.channelID == id }
            .sorted { $0.sentAt < $1.sentAt }
    }

    var selectedChannel: ChatChannel? {
        workspace.channels.first { $0.id == selectedChannelID }
    }

    var selectedSpace: Space? {
        workspace.spaces.first { $0.id == selectedSpaceID }
    }

    func persist() {
        LocalStore.save(workspace)
    }

    func sendMessage() {
        let text = chatInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let channelID = selectedChannelID else { return }
        let msg = ChatMessage(channelID: channelID, author: "You", body: text)
        workspace.messages.append(msg)
        chatInput = ""
        persist()
    }

    func createChannel() {
        let ch = ChatChannel(name: "new-channel", spaceID: selectedSpaceID)
        workspace.channels.append(ch)
        selectedChannelID = ch.id
        section = .chat
        persist()
    }

    func createSpace() {
        let space = Space(name: "New Space", colorHex: "10B981", folders: [])
        workspace.spaces.append(space)
        selectedSpaceID = space.id
        section = .spaces
        persist()
    }

    func syncFromSettings() async { await performSync(showInSettings: true) }
    func checkForUpdatesFromMenu() async { await performSync(showInSettings: true) }

    func syncInBackground() async { await performSync(showInSettings: false) }

    private func performSync(showInSettings: Bool) async {
        isSyncing = true
        statusMessage = "Syncing…"
        let networkAvailable = await isNetworkAvailable()
        let offline = preferOffline || !networkAvailable
        let result = await git.sync(offline: offline)
        switch result {
        case .success(let sync):
            lastCommit = sync.commit ?? "—"
            statusMessage = sync.updated ? "Synced" : "Ready"
            settingsUpdateNote = sync.message
        case .failure(let error):
            statusMessage = "Ready"
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
        } catch { return false }
    }
}
