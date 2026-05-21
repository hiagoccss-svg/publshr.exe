import Foundation
import PublshrCore

enum WorkspaceMode: String, CaseIterable, Hashable {
    case chat = "Chat"
    case projects = "Projects"
}

@MainActor
final class AppModel: ObservableObject {
    @Published var mode: WorkspaceMode = .chat
    @Published var workspaces: [WorkspaceRow] = []
    @Published var spaces: [SpaceRow] = []
    @Published var channels: [ChatChannelRow] = []
    @Published var messages: [ChatMessageRow] = []
    @Published var tasks: [TaskRow] = []
    @Published var selectedWorkspaceId: UUID?
    @Published var selectedSpaceId: UUID?
    @Published var selectedChannelId: UUID?
    @Published var chatInput = ""
    @Published var searchText = ""
    @Published var errorMessage: String?
    @Published var isLoading = false

    let supabase = SupabaseService.shared

    func bootstrapAfterLogin() async {
        isLoading = true
        defer { isLoading = false }
        do {
            workspaces = try await supabase.fetchWorkspaces()
            if selectedWorkspaceId == nil { selectedWorkspaceId = workspaces.first?.id }
            await reloadWorkspaceData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reloadWorkspaceData() async {
        guard let wid = selectedWorkspaceId else { return }
        do {
            spaces = try await supabase.fetchSpaces(workspaceId: wid)
            channels = try await supabase.fetchChannels(workspaceId: wid)
            if selectedChannelId == nil { selectedChannelId = channels.first?.id }
            if selectedSpaceId == nil { selectedSpaceId = spaces.first?.id }
            if mode == .chat { await loadMessages() }
            else { await loadTasks() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMessages() async {
        guard let cid = selectedChannelId else { messages = []; return }
        do {
            messages = try await supabase.fetchMessages(channelId: cid)
        } catch { errorMessage = error.localizedDescription }
    }

    func loadTasks() async {
        guard let wid = selectedWorkspaceId else { tasks = []; return }
        do {
            tasks = try await supabase.fetchTasks(workspaceId: wid, spaceId: selectedSpaceId)
        } catch { errorMessage = error.localizedDescription }
    }

    func sendMessage() async {
        let text = chatInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let cid = selectedChannelId else { return }
        do {
            let row = try await supabase.sendMessage(channelId: cid, body: text)
            messages.append(row)
            chatInput = ""
        } catch { errorMessage = error.localizedDescription }
    }

    func newChannel() async {
        guard let wid = selectedWorkspaceId else { return }
        do {
            let ch = try await supabase.createChannel(workspaceId: wid, name: "channel-\(Int.random(in: 1000...9999))")
            channels.append(ch)
            selectedChannelId = ch.id
            mode = .chat
            await loadMessages()
        } catch { errorMessage = error.localizedDescription }
    }

    func newSpace() async {
        guard let wid = selectedWorkspaceId else { return }
        do {
            let sp = try await supabase.createSpace(workspaceId: wid, name: "New space", parentId: nil)
            spaces.append(sp)
            selectedSpaceId = sp.id
            mode = .projects
        } catch { errorMessage = error.localizedDescription }
    }

    func newTask() async {
        guard let wid = selectedWorkspaceId else { return }
        do {
            let t = try await supabase.createTask(workspaceId: wid, spaceId: selectedSpaceId, title: "New task")
            tasks.append(t)
        } catch { errorMessage = error.localizedDescription }
    }
}
