import Foundation
import Supabase

@MainActor
final class SpacesViewModel: ObservableObject {
    @Published private(set) var spaces: [SpaceRecord] = []
    @Published private(set) var tasks: [SpaceTaskRecord] = []
    @Published private(set) var activity: [SpaceActivityRecord] = []
    @Published private(set) var documents: [SpaceDocumentRecord] = []
    @Published private(set) var comments: [SpaceCommentRecord] = []
    @Published var profiles: [UUID: Profile] = [:]

    @Published var selectedSpaceId: UUID?
    @Published var selectedTaskId: UUID?
    @Published var taskView: TaskViewMode = .board
    @Published var searchQuery = ""
    @Published var spacesFocusMode = false
    @Published var showTaskPanel = true
    @Published var newCommentText = ""

    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var newSpaceName = ""
    @Published var newTaskTitle = ""
    @Published var newDocumentTitle = ""

    enum TaskViewMode: String, CaseIterable, Identifiable {
        case overview, list, board
        var id: String { rawValue }

        var label: String {
            switch self {
            case .overview: return "Overview"
            case .list: return "List"
            case .board: return "Board"
            }
        }

        var icon: String {
            switch self {
            case .overview: return "square.grid.2x2"
            case .list: return "list.bullet"
            case .board: return "rectangle.split.3x1"
            }
        }
    }

    private var service: SpacesService?
    private var workspaceId: UUID?
    private var userId: UUID?
    private var navigationBackStack: [UUID] = []
    private var navigationForwardStack: [UUID] = []
    private var realtimeAttached = false

    func attach(auth: AuthViewModel) {
        let newWorkspaceId = auth.selectedWorkspace?.id
        let workspaceChanged = workspaceId != newWorkspaceId
        service = SpacesService(client: auth.client)
        workspaceId = newWorkspaceId
        userId = auth.session?.user.id ?? auth.profile?.id
        if workspaceChanged || spaces.isEmpty {
            Task { await reload() }
        }
    }

    func detach() {
        service?.stopRealtime()
        realtimeAttached = false
        service = nil
        workspaceId = nil
        userId = nil
        spaces = []
        tasks = []
        activity = []
        documents = []
        comments = []
        profiles = [:]
        selectedSpaceId = nil
        selectedTaskId = nil
    }

    // MARK: - Load

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
            let profs = try await service.fetchWorkspaceProfiles(workspaceId: workspaceId)
            profiles = Dictionary(uniqueKeysWithValues: profs.map { ($0.id, $0) })

            if !realtimeAttached {
                service.subscribeWorkspace(workspaceId: workspaceId) { [weak self] in
                    Task { @MainActor in await self?.refreshTasksFromRealtime() }
                } onSpaceChange: { [weak self] in
                    Task { @MainActor in await self?.reloadSpacesOnly() }
                }
                realtimeAttached = true
            }

            if let selected = selectedSpaceId, loaded.contains(where: { $0.id == selected }) {
                await loadSpaceContext(selected)
            } else if let first = loaded.first {
                await selectSpace(first.id, recordHistory: false)
            } else {
                selectedSpaceId = nil
                tasks = []
                activity = []
                documents = []
            }
        } catch {
            errorMessage = friendlySpacesError(error)
        }
    }

    private func reloadSpacesOnly() async {
        guard let service, let workspaceId else { return }
        do {
            spaces = try await service.fetchSpaces(workspaceId: workspaceId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshTasksFromRealtime() async {
        guard let selectedSpaceId else { return }
        await loadTasks(for: selectedSpaceId)
    }

    func selectSpace(_ id: UUID, recordHistory: Bool = true) async {
        if recordHistory, let previous = selectedSpaceId, previous != id {
            navigationBackStack.append(previous)
            if navigationBackStack.count > 32 { navigationBackStack.removeFirst() }
            navigationForwardStack.removeAll()
        }
        selectedSpaceId = id
        selectedTaskId = nil
        comments = []
        await loadSpaceContext(id)
    }

    func loadSpaceContext(_ spaceId: UUID) async {
        await loadTasks(for: spaceId)
        await loadActivity(for: spaceId)
        await loadDocuments(for: spaceId)
    }

    func loadTasks(for spaceId: UUID) async {
        guard let service else { return }
        do {
            tasks = try await service.fetchTasks(spaceId: spaceId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadActivity(for spaceId: UUID) async {
        guard let service else { return }
        do {
            activity = try await service.fetchActivity(spaceId: spaceId)
        } catch {
            activity = []
        }
    }

    func loadDocuments(for spaceId: UUID) async {
        guard let service else { return }
        do {
            documents = try await service.fetchDocuments(spaceId: spaceId)
        } catch {
            documents = []
        }
    }

    func loadComments(for taskId: UUID) async {
        guard let service else { return }
        do {
            comments = try await service.fetchComments(taskId: taskId)
        } catch {
            comments = []
        }
    }

    // MARK: - Navigation

    var canNavigateBack: Bool { !navigationBackStack.isEmpty }
    var canNavigateForward: Bool { !navigationForwardStack.isEmpty }

    func navigateBack() async {
        guard let current = selectedSpaceId,
              let previous = navigationBackStack.popLast() else { return }
        navigationForwardStack.append(current)
        await selectSpace(previous, recordHistory: false)
    }

    func navigateForward() async {
        guard let current = selectedSpaceId,
              let next = navigationForwardStack.popLast() else { return }
        navigationBackStack.append(current)
        await selectSpace(next, recordHistory: false)
    }

    // MARK: - Spaces CRUD

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

    func togglePinSelectedSpace() async {
        guard let service, let space = selectedSpace else { return }
        let next = !space.isPinned
        do {
            try await service.updateSpace(id: space.id, isPinned: next)
            if let idx = spaces.firstIndex(where: { $0.id == space.id }) {
                spaces[idx].isPinned = next
            }
            spaces.sort { lhs, rhs in
                if lhs.isPinned != rhs.isPinned { return lhs.isPinned && !rhs.isPinned }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Tasks

    func createTask() async {
        guard let service, let spaceId = selectedSpaceId else { return }
        let title = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        do {
            let task = try await service.createTask(spaceId: spaceId, title: title)
            newTaskTitle = ""
            tasks.append(task)
            selectedTaskId = task.id
            showTaskPanel = true
            await loadComments(for: task.id)
            await logTaskAction("created task \"\(title)\"", taskId: task.id)
            await loadActivity(for: spaceId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectTask(_ taskId: UUID?) async {
        selectedTaskId = taskId
        if let taskId {
            showTaskPanel = true
            await loadComments(for: taskId)
        } else {
            comments = []
            newCommentText = ""
        }
    }

    func moveTask(_ taskId: UUID, to status: SpaceTaskStatus) async {
        await applyTaskPatch(taskId: taskId, patch: SpaceTaskPatch(status: status.rawValue), log: "moved task to \(status.label)")
    }

    func updateTaskTitle(_ taskId: UUID, title: String) async {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        await applyTaskPatch(taskId: taskId, patch: SpaceTaskPatch(title: trimmed), log: "updated task title")
    }

    func updateTaskDescription(_ taskId: UUID, description: String) async {
        await applyTaskPatch(taskId: taskId, patch: SpaceTaskPatch(description: description), log: nil)
    }

    func updateTaskPriority(_ taskId: UUID, priority: SpaceTaskPriority) async {
        await applyTaskPatch(taskId: taskId, patch: SpaceTaskPatch(priority: priority.rawValue), log: "set priority to \(priority.label)")
    }

    func updateTaskAssignee(_ taskId: UUID, assigneeId: UUID?) async {
        var patch = SpaceTaskPatch()
        if let assigneeId {
            patch.assigneeId = assigneeId
        } else {
            patch.clearAssignee = true
        }
        await applyTaskPatch(taskId: taskId, patch: patch, log: "updated assignee")
    }

    func updateTaskDueDate(_ taskId: UUID, dueDate: String?) async {
        var patch = SpaceTaskPatch()
        if let dueDate {
            patch.dueDate = dueDate
        } else {
            patch.clearDueDate = true
        }
        await applyTaskPatch(taskId: taskId, patch: patch, log: "updated due date")
    }

    func updateTaskTags(_ taskId: UUID, tags: [String]) async {
        await applyTaskPatch(taskId: taskId, patch: SpaceTaskPatch(tags: tags), log: nil)
    }

    func updateTaskChecklist(_ taskId: UUID, checklist: [SpaceChecklistItem]) async {
        await applyTaskPatch(taskId: taskId, patch: SpaceTaskPatch(checklist: checklist), log: nil)
    }

    func archiveSelectedTask() async {
        guard let taskId = selectedTaskId, let spaceId = selectedSpaceId else { return }
        guard let service else { return }
        do {
            try await service.archiveTask(taskId: taskId)
            tasks.removeAll { $0.id == taskId }
            selectedTaskId = nil
            comments = []
            await logTaskAction("archived task", taskId: taskId)
            await loadActivity(for: spaceId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func postComment() async {
        guard let service,
              let spaceId = selectedSpaceId,
              let taskId = selectedTaskId,
              let userId else { return }
        let body = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        do {
            let comment = try await service.postComment(spaceId: spaceId, taskId: taskId, userId: userId, body: body)
            comments.append(comment)
            newCommentText = ""
            await logTaskAction("commented on task", taskId: taskId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createDocument() async {
        guard let service, let spaceId = selectedSpaceId else { return }
        let title = newDocumentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        do {
            let doc = try await service.createDocument(spaceId: spaceId, title: title)
            newDocumentTitle = ""
            documents.insert(doc, at: 0)
            if let userId {
                try? await service.logActivity(
                    spaceId: spaceId,
                    userId: userId,
                    action: "created document \"\(title)\"",
                    entityType: "document",
                    entityId: doc.id
                )
                await loadActivity(for: spaceId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyTaskPatch(taskId: UUID, patch: SpaceTaskPatch, log: String?) async {
        guard let service, let index = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        let previous = tasks[index]
        do {
            let updated = try await service.updateTask(id: taskId, patch: patch)
            tasks[index] = updated
            if let log {
                await logTaskAction(log, taskId: taskId)
            }
            if let spaceId = selectedSpaceId {
                await loadActivity(for: spaceId)
            }
        } catch {
            tasks[index] = previous
            errorMessage = error.localizedDescription
        }
    }

    private func logTaskAction(_ action: String, taskId: UUID) async {
        guard let service, let spaceId = selectedSpaceId, let userId else { return }
        try? await service.logActivity(
            spaceId: spaceId,
            userId: userId,
            action: action,
            entityType: "task",
            entityId: taskId
        )
    }

    // MARK: - Display helpers

    var selectedSpace: SpaceRecord? {
        guard let selectedSpaceId else { return nil }
        return spaces.first { $0.id == selectedSpaceId }
    }

    var selectedTask: SpaceTaskRecord? {
        guard let selectedTaskId else { return nil }
        return tasks.first { $0.id == selectedTaskId }
    }

    var filteredSpaces: [SpaceRecord] {
        filterSpaces(spaces)
    }

    var filteredTasks: [SpaceTaskRecord] {
        filterTasks(tasks)
    }

    func tasks(in status: SpaceTaskStatus) -> [SpaceTaskRecord] {
        filterTasks(tasks.filter { $0.status == status })
    }

    func displayName(for userId: UUID) -> String {
        if userId == self.userId { return "You" }
        return profiles[userId]?.displayName ?? profiles[userId]?.email ?? "Member"
    }

    func profile(for userId: UUID) -> Profile? {
        profiles[userId]
    }

    func spaceSubtitle(_ space: SpaceRecord) -> String {
        let open = tasks.filter { $0.status != .completed && $0.status != .archived }.count
        if open == 0 { return "No open tasks" }
        return open == 1 ? "1 open task" : "\(open) open tasks"
    }

    func activityLabel(_ item: SpaceActivityRecord) -> String {
        let who = displayName(for: item.userId)
        return "\(who) \(item.action)"
    }

    private func filterSpaces(_ list: [SpaceRecord]) -> [SpaceRecord] {
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return list }
        return list.filter {
            $0.name.lowercased().contains(q) || $0.description.lowercased().contains(q)
        }
    }

    private func filterTasks(_ list: [SpaceTaskRecord]) -> [SpaceTaskRecord] {
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return list }
        return list.filter {
            $0.title.lowercased().contains(q)
                || $0.description.lowercased().contains(q)
                || $0.tags.contains { $0.lowercased().contains(q) }
        }
    }

    private func friendlySpacesError(_ error: Error) -> String {
        let text = error.localizedDescription.lowercased()
        if text.contains("does not exist") || text.contains("42p01") || text.contains("relation") {
            return "Spaces tables are missing in Supabase. Apply desktop/spaces/supabase/migrations/001_spaces_schema.sql to your project."
        }
        return error.localizedDescription
    }
}
