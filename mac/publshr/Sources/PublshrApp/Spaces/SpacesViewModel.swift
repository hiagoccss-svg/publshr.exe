import Foundation
import Supabase

@MainActor
final class SpacesViewModel: ObservableObject {
    @Published private(set) var spaces: [SpaceRecord] = []
    @Published private(set) var tasks: [SpaceTaskRecord] = []
    @Published var selectedSpaceId: UUID?
    @Published var selectedTaskId: UUID?
    @Published var taskView: TaskViewMode = .board
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var newSpaceName = ""
    @Published var newTaskTitle = ""

    enum TaskViewMode: String, CaseIterable {
        case overview, list, board

        var label: String {
            switch self {
            case .overview: return "Overview"
            case .list: return "List"
            case .board: return "Board"
            }
        }
    }

    private var service: SpacesService?
    private var workspaceId: UUID?
    private var userId: UUID?

    func attach(auth: AuthViewModel) {
        service = SpacesService(client: auth.client)
        workspaceId = auth.selectedWorkspace?.id
        userId = auth.session?.user.id
        Task { await reload() }
    }

    func detach() {
        service = nil
        workspaceId = nil
        userId = nil
        spaces = []
        tasks = []
        selectedSpaceId = nil
        selectedTaskId = nil
    }

    func reload() async {
        guard let service, let workspaceId else {
            spaces = []
            tasks = []
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let loaded = try await service.fetchSpaces(workspaceId: workspaceId)
            spaces = loaded
            if let selected = selectedSpaceId, loaded.contains(where: { $0.id == selected }) {
                await loadTasks(for: selected)
            } else if let first = loaded.first {
                selectedSpaceId = first.id
                await loadTasks(for: first.id)
            } else {
                selectedSpaceId = nil
                tasks = []
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectSpace(_ id: UUID) async {
        selectedSpaceId = id
        selectedTaskId = nil
        await loadTasks(for: id)
    }

    func loadTasks(for spaceId: UUID) async {
        guard let service else { return }
        do {
            tasks = try await service.fetchTasks(spaceId: spaceId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createSpace() async {
        guard let service, let workspaceId, let userId else { return }
        let name = newSpaceName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let space = try await service.createSpace(workspaceId: workspaceId, ownerId: userId, name: name)
            newSpaceName = ""
            spaces.append(space)
            await selectSpace(space.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createTask() async {
        guard let service, let spaceId = selectedSpaceId else { return }
        let title = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        do {
            let task = try await service.createTask(spaceId: spaceId, title: title)
            newTaskTitle = ""
            tasks.append(task)
            selectedTaskId = task.id
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func moveTask(_ taskId: UUID, to status: SpaceTaskStatus) async {
        guard let service else { return }
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        let previous = tasks[index].status
        tasks[index].status = status
        do {
            try await service.updateTaskStatus(taskId: taskId, status: status)
        } catch {
            tasks[index].status = previous
            errorMessage = error.localizedDescription
        }
    }

    var selectedSpace: SpaceRecord? {
        guard let selectedSpaceId else { return nil }
        return spaces.first { $0.id == selectedSpaceId }
    }

    var selectedTask: SpaceTaskRecord? {
        guard let selectedTaskId else { return nil }
        return tasks.first { $0.id == selectedTaskId }
    }

    func tasks(in status: SpaceTaskStatus) -> [SpaceTaskRecord] {
        tasks.filter { $0.status == status }
    }
}
