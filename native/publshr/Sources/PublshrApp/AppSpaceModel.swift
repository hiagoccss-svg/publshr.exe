import Foundation
import PublshrCore

@MainActor
final class AppSpaceModel: ObservableObject {
    @Published private(set) var document: AppSpaceDocument
    @Published var selection: SidebarSelection = .inbox
    @Published var viewType: ViewType = .list
    @Published var selectedTaskID: TaskID?
    @Published var searchQuery: String = ""
    @Published var showCreateTask = false
    @Published var showCreateList = false
    @Published var showCreateSpace = false
    @Published var showSettings = false
    @Published var columnVisibility: NavigationSplitViewVisibility = .all

    private let store: AppSpaceStore

    init(store: AppSpaceStore = AppSpaceStore()) {
        self.store = store
        self.document = store.load()
    }

    var currentUser: TeamMember? {
        document.workspace.members.first { $0.id == document.currentUserID }
    }

    var activeListID: ListID? {
        switch selection {
        case .list(let id): return id
        case .inbox, .space: return nil
        }
    }

    var activeList: TaskList? {
        guard let id = activeListID else { return nil }
        return document.lists.first { $0.id == id }
    }

    // MARK: - Filtered tasks

    func tasks(for listID: ListID, includeSubtasks: Bool = false) -> [TaskItem] {
        let base = document.tasks.filter { $0.listID == listID && (includeSubtasks || $0.parentTaskID == nil) }
        return applySearch(to: base.sorted { $0.order < $1.order })
    }

    func inboxTasks() -> [TaskItem] {
        let assigned = document.tasks.filter {
            $0.parentTaskID == nil && $0.assigneeIDs.contains(document.currentUserID)
        }
        return applySearch(to: assigned.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) })
    }

    func tasksGroupedByStatus(for list: TaskList) -> [(TaskStatus, [TaskItem])] {
        list.statuses.sorted { $0.order < $1.order }.map { status in
            let items = tasks(for: list.id).filter { $0.statusID == status.id }
            return (status, items)
        }
    }

    func subtasks(of taskID: TaskID) -> [TaskItem] {
        document.tasks.filter { $0.parentTaskID == taskID }.sorted { $0.order < $1.order }
    }

    func member(for id: UserID) -> TeamMember? {
        document.workspace.members.first { $0.id == id }
    }

    func task(by id: TaskID) -> TaskItem? {
        document.tasks.first { $0.id == id }
    }

    func lists(in spaceID: SpaceID) -> [TaskList] {
        document.lists.filter { $0.spaceID == spaceID }.sorted { $0.order < $1.order }
    }

    func folders(in spaceID: SpaceID) -> [Folder] {
        document.folders.filter { $0.spaceID == spaceID }.sorted { $0.order < $1.order }
    }

    func lists(in folderID: FolderID) -> [TaskList] {
        document.lists.filter { $0.folderID == folderID }.sorted { $0.order < $1.order }
    }

    func rootLists(in spaceID: SpaceID) -> [TaskList] {
        document.lists.filter { $0.spaceID == spaceID && $0.folderID == nil }.sorted { $0.order < $1.order }
    }

    func space(for id: SpaceID) -> Space? {
        document.spaces.first { $0.id == id }
    }

    func status(in list: TaskList, id: String) -> TaskStatus? {
        list.statuses.first { $0.id == id }
    }

    // MARK: - Mutations

    func selectList(_ listID: ListID) {
        selection = .list(listID)
        viewType = .list
    }

    func selectInbox() {
        selection = .inbox
        selectedTaskID = nil
    }

    func selectTask(_ taskID: TaskID?) {
        selectedTaskID = taskID
    }

    func persist() {
        try? store.save(document)
    }

    func createTask(name: String, listID: ListID, statusID: String? = nil, parentTaskID: TaskID? = nil) {
        guard let list = document.lists.first(where: { $0.id == listID }) else { return }
        let status = statusID ?? list.statuses.first?.id ?? ""
        let maxOrder = document.tasks.filter { $0.listID == listID }.map(\.order).max() ?? -1
        var task = TaskItem(
            listID: listID,
            parentTaskID: parentTaskID,
            name: name,
            statusID: status,
            assigneeIDs: [document.currentUserID],
            order: maxOrder + 1
        )
        if parentTaskID == nil {
            task.assigneeIDs = [document.currentUserID]
        }
        document.tasks.append(task)
        selectedTaskID = task.id
        persist()
    }

    func updateTask(_ taskID: TaskID, mutate: (inout TaskItem) -> Void) {
        guard let index = document.tasks.firstIndex(where: { $0.id == taskID }) else { return }
        mutate(&document.tasks[index])
        document.tasks[index].updatedAt = Date()
        persist()
    }

    func deleteTask(_ taskID: TaskID) {
        let childIDs = document.tasks.filter { $0.parentTaskID == taskID }.map(\.id)
        document.tasks.removeAll { $0.id == taskID || childIDs.contains($0.id) }
        if selectedTaskID == taskID { selectedTaskID = nil }
        persist()
    }

    func moveTask(_ taskID: TaskID, toStatus statusID: String, order: Double? = nil) {
        updateTask(taskID) { task in
            task.statusID = statusID
            if let order { task.order = order }
        }
    }

    func addComment(to taskID: TaskID, body: String) {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        updateTask(taskID) { task in
            task.comments.append(TaskComment(authorID: document.currentUserID, body: trimmed))
        }
    }

    func toggleChecklistItem(taskID: TaskID, itemID: String) {
        updateTask(taskID) { task in
            guard let i = task.checklist.firstIndex(where: { $0.id == itemID }) else { return }
            task.checklist[i].isDone.toggle()
        }
    }

    func addChecklistItem(taskID: TaskID, title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        updateTask(taskID) { task in
            task.checklist.append(ChecklistItem(title: trimmed))
        }
    }

    func createList(name: String, spaceID: SpaceID, folderID: FolderID? = nil) {
        let maxOrder = document.lists.map(\.order).max() ?? -1
        let list = TaskList(spaceID: spaceID, folderID: folderID, name: name, order: maxOrder + 1)
        document.lists.append(list)
        selection = .list(list.id)
        persist()
    }

    func createSpace(name: String) {
        let maxOrder = document.spaces.map(\.order).max() ?? -1
        let space = Space(name: name, order: maxOrder + 1)
        document.spaces.append(space)
        let list = TaskList(spaceID: space.id, name: "List", order: 0)
        document.lists.append(list)
        selection = .list(list.id)
        persist()
    }

    func createFolder(name: String, spaceID: SpaceID) {
        let maxOrder = document.folders.filter { $0.spaceID == spaceID }.map(\.order).max() ?? -1
        document.folders.append(Folder(spaceID: spaceID, name: name, order: maxOrder + 1))
        persist()
    }

    private func applySearch(to tasks: [TaskItem]) -> [TaskItem] {
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return tasks }
        return tasks.filter {
            $0.name.lowercased().contains(q)
                || $0.description.lowercased().contains(q)
                || $0.tagNames.contains { $0.lowercased().contains(q) }
        }
    }
}
