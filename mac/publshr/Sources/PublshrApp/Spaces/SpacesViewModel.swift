import Foundation
import Supabase

@MainActor
final class SpacesViewModel: ObservableObject {
    @Published private(set) var spaces: [SpaceRecord] = []
    @Published private(set) var folders: [SpaceFolderRecord] = []
    @Published private(set) var lists: [SpaceListRecord] = []
    @Published private(set) var tasks: [SpaceTaskRecord] = []
    @Published private(set) var activity: [SpaceActivityRecord] = []
    @Published private(set) var documents: [SpaceDocumentRecord] = []
    @Published private(set) var whiteboards: [SpaceWhiteboardRecord] = []
    @Published var selectedWhiteboardId: UUID?
    @Published private(set) var comments: [SpaceCommentRecord] = []
    @Published var profiles: [UUID: Profile] = [:]

    @Published var selectedSpaceId: UUID?
    @Published var selectedFolderId: UUID?
    @Published var selectedListId: UUID?
    @Published var selectedTaskId: UUID?
    @Published var taskView: TaskViewMode = .board
    @Published var searchQuery = ""
    @Published var spacesFocusMode = false
    @Published var showTaskPanel = true
    @Published var newCommentText = ""

    @Published private(set) var isLoading = false
    @Published var isOffline = false
    @Published var errorMessage: String?
    @Published var showNewSpaceSheet = false
    @Published var editingDocument: SpaceDocumentRecord?
    @Published var newSpaceName = ""
    @Published var newSpaceType: SpaceTypeOption = .general
    @Published var newSpaceDescription = ""
    @Published var newFolderName = ""
    @Published var newListName = ""
    @Published var newTaskTitle = ""
    @Published var newDocumentTitle = ""
    @Published var expandedFolderIds: Set<UUID> = []
    @Published var spacesHomeOpen = false
    @Published var spacesHomeQuery = ""
    @Published var spacesHomeTypeFilter = "all"
    @Published var spacesHomeShowArchived = false
    @Published var spacesHomeUseListLayout = false
    @Published var spaceSettingsSpaceId: UUID?
    @Published var activeSection: SpacesEnterpriseSection = .spaces
    @Published private(set) var workspaceSummary: SpacesWorkspaceSummary?
    @Published private(set) var workspaceDocuments: [SpaceDocumentRecord] = []
    @Published private(set) var workspaceApprovals: [SpaceApprovalRecord] = []
    @Published private(set) var workspaceFiles: [SpaceFileRecord] = []
    @Published private(set) var workspaceTasks: [SpaceTaskRecord] = []
    @Published private(set) var workspaceActivity: [SpaceActivityRecord] = []

    enum TaskViewMode: String, CaseIterable, Identifiable {
        case overview, list, board, whiteboard, calendar, timeline, workload, priority
        var id: String { rawValue }

        var label: String {
            switch self {
            case .overview: return "Overview"
            case .list: return "List"
            case .board: return "Board"
            case .whiteboard: return "Whiteboard"
            case .calendar: return "Calendar"
            case .timeline: return "Timeline"
            case .workload: return "Workload"
            case .priority: return "Priority"
            }
        }

        var icon: String {
            switch self {
            case .overview: return "square.grid.2x2"
            case .list: return "list.bullet"
            case .board: return "rectangle.split.3x1"
            case .whiteboard: return "scribble.variable"
            case .calendar: return "calendar"
            case .timeline: return "chart.bar.xaxis"
            case .workload: return "person.2"
            case .priority: return "square.grid.2x2.fill"
            }
        }
    }

    private var service: SpacesService?
    private var workspaceId: UUID?
    private var userId: UUID?
    private var navigationBackStack: [UUID] = []
    private var navigationForwardStack: [UUID] = []
    private var realtimeAttached = false
    private let localStore = SpacesLocalStore()

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
        isOffline = false
        defer { isLoading = false }

        do {
            if let userId {
                // Best-effort demo seed — must not block loading when DB types are misconfigured.
                try? await service.seedDefaultWorkspace(workspaceId: workspaceId, ownerId: userId)
            }
            let loaded = try await service.fetchSpaces(workspaceId: workspaceId)
            spaces = loaded
            let profs = try await service.fetchWorkspaceProfiles(workspaceId: workspaceId)
            profiles = Dictionary(uniqueKeysWithValues: profs.map { ($0.id, $0) })

            if !realtimeAttached {
                service.subscribeWorkspace(workspaceId: workspaceId) { [weak self] in
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        await self.refreshTasksFromRealtime()
                    }
                } onSpaceChange: { [weak self] in
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        await self.reloadSpacesOnly()
                    }
                }
                realtimeAttached = true
            }

            persistToCache(workspaceId: workspaceId)
            await loadWorkspaceData()

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
            isOffline = isNetworkError(error)
            errorMessage = friendlySpacesError(error)
            if isOffline {
                loadFromLocalCache(workspaceId: workspaceId)
            }
        }
    }

    private func loadFromLocalCache(workspaceId: UUID) {
        let cached = localStore.loadSpaces(workspaceId: workspaceId)
        guard !cached.isEmpty else { return }
        spaces = cached
        if let selected = selectedSpaceId ?? cached.first?.id {
            tasks = localStore.loadTasks(spaceId: selected)
        }
    }

    private func persistToCache(workspaceId: UUID) {
        localStore.saveSpaces(spaces, workspaceId: workspaceId)
        if let spaceId = selectedSpaceId {
            localStore.saveTasks(tasks, spaceId: spaceId)
        }
    }

    private func reloadSpacesOnly() async {
        guard let service, let workspaceId else { return }
        do {
            spaces = try await service.fetchSpaces(workspaceId: workspaceId)
            await loadWorkspaceData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Enterprise operations sidebar

    func setActiveSection(_ section: SpacesEnterpriseSection) {
        let resolved: SpacesEnterpriseSection = section == .dashboard ? .chat : section
        activeSection = resolved
        if resolved == .spaces {
            return
        }
        if resolved == .chat {
            NotificationCenter.default.post(name: .publshrSelectModule, object: AppModule.chat.rawValue)
            return
        }
        if resolved == .planner {
            openPlannerCalendar()
            return
        }
        if resolved == .media {
            NotificationCenter.default.post(name: .publshrSelectModule, object: AppModule.mediaMonitoring.rawValue)
            return
        }
        if resolved == .whiteboard {
            spacesHomeOpen = false
            if selectedSpaceId == nil, let first = spaces.first {
                Task { await selectSpace(first.id) }
            }
            return
        }
        selectedSpaceId = nil
        spacesHomeOpen = false
        Task { await loadWorkspaceData() }
    }

    func openSpacesSection() {
        activeSection = .spaces
    }

    func loadWorkspaceData() async {
        guard let service, !spaces.isEmpty else {
            workspaceSummary = spaces.isEmpty
                ? SpacesWorkspaceSummary(spaceCount: 0, openTasks: 0, overdueTasks: 0, documentCount: 0, pendingApprovals: 0)
                : nil
            workspaceDocuments = []
            workspaceApprovals = []
            workspaceFiles = []
            workspaceTasks = []
            workspaceActivity = []
            return
        }
        let spaceIds = spaces.map(\.id)
        do {
            async let docs = service.fetchWorkspaceDocuments(spaceIds: spaceIds)
            async let approvals = service.fetchWorkspaceApprovals(spaceIds: spaceIds)
            async let files = service.fetchWorkspaceFiles(spaceIds: spaceIds)
            async let allTasks = service.fetchWorkspaceTasks(spaceIds: spaceIds)
            async let activity = service.fetchWorkspaceActivity(spaceIds: spaceIds)
            let (documents, approvalRows, fileRows, tasks, activityRows) = try await (
                docs, approvals, files, allTasks, activity
            )
            workspaceDocuments = documents
            workspaceApprovals = approvalRows
            workspaceFiles = fileRows
            workspaceTasks = tasks
            workspaceActivity = activityRows
            let open = tasks.filter { $0.status != .completed }
            let overdue = open.filter { isOverdue(dueDate: $0.dueDate) }
            let pending = approvalRows.filter(\.isPending)
            workspaceSummary = SpacesWorkspaceSummary(
                spaceCount: spaces.count,
                openTasks: open.count,
                overdueTasks: overdue.count,
                documentCount: documents.count,
                pendingApprovals: pending.count
            )
        } catch {
            errorMessage = friendlySpacesError(error)
        }
    }

    func spaceName(for spaceId: UUID) -> String {
        spaces.first(where: { $0.id == spaceId })?.name ?? "Space"
    }

    func spacesFiltered(type: String) -> [SpaceRecord] {
        spaces.filter { $0.type == type && !$0.isArchived }
    }

    private func isOverdue(dueDate: String?) -> Bool {
        guard let dueDate, !dueDate.isEmpty else { return false }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        guard let date = formatter.date(from: String(dueDate.prefix(10))) else { return false }
        return date < Calendar.current.startOfDay(for: Date())
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
        activeSection = .spaces
        selectedSpaceId = id
        spacesHomeOpen = false
        selectedFolderId = nil
        selectedListId = nil
        selectedTaskId = nil
        comments = []
        taskView = defaultView(for: id)
        await loadSpaceContext(id)
    }

    func openSpacesHome() {
        activeSection = .spaces
        selectedSpaceId = nil
        selectedFolderId = nil
        selectedListId = nil
        selectedTaskId = nil
        spacesHomeOpen = true
    }

    /// In-app editorial calendar (Spaces task calendar view).
    func openPlannerCalendar() {
        activeSection = .spaces
        spacesHomeOpen = false
        Task {
            if let id = selectedSpaceId ?? spaces.first?.id {
                await selectSpace(id, recordHistory: false)
            }
            taskView = .calendar
        }
    }

    func defaultView(for spaceId: UUID) -> TaskViewMode {
        let key = "spaces:defaultView:\(spaceId.uuidString)"
        guard let raw = UserDefaults.standard.string(forKey: key),
              let mode = TaskViewMode(rawValue: raw) else {
            return .overview
        }
        return mode
    }

    func setDefaultView(for spaceId: UUID, view: TaskViewMode) {
        UserDefaults.standard.set(view.rawValue, forKey: "spaces:defaultView:\(spaceId.uuidString)")
    }

    func updateSpaceMetadata(
        id: UUID,
        name: String?,
        description: String?,
        isPinned: Bool? = nil,
        isFavourite: Bool? = nil
    ) async {
        guard let service else { return }
        do {
            try await service.updateSpace(
                id: id,
                name: name,
                description: description,
                isPinned: isPinned,
                isFavourite: isFavourite
            )
            if let idx = spaces.firstIndex(where: { $0.id == id }) {
                if let name { spaces[idx].name = name }
                if let description { spaces[idx].description = description }
                if let isPinned { spaces[idx].isPinned = isPinned }
                if let isFavourite { spaces[idx].isFavourite = isFavourite }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadSpaceContext(_ spaceId: UUID) async {
        await loadHierarchy(for: spaceId)
        await loadTasks(for: spaceId)
        await loadActivity(for: spaceId)
        await loadDocuments(for: spaceId)
        await loadWhiteboards(for: spaceId)
    }

    func loadHierarchy(for spaceId: UUID) async {
        guard let service else { return }
        do {
            folders = try await service.fetchFolders(spaceId: spaceId)
            lists = try await service.fetchLists(spaceId: spaceId)
            for folder in folders where !expandedFolderIds.contains(folder.id) {
                expandedFolderIds.insert(folder.id)
            }
            await ensureDefaultList(spaceId: spaceId)
        } catch {
            folders = []
            lists = []
        }
    }

    private func ensureDefaultList(spaceId: UUID) async {
        guard let service, lists.isEmpty else { return }
        do {
            let list = try await service.createList(spaceId: spaceId, folderId: nil, name: "List")
            lists = [list]
            selectedListId = list.id
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadTasks(for spaceId: UUID) async {
        guard let service else { return }
        do {
            tasks = try await service.fetchTasks(spaceId: spaceId, listId: selectedListId)
            if workspaceId != nil {
                localStore.saveTasks(tasks, spaceId: spaceId)
            }
        } catch {
            errorMessage = error.localizedDescription
            tasks = localStore.loadTasks(spaceId: spaceId)
        }
    }

    func selectList(_ listId: UUID?) async {
        selectedListId = listId
        if let listId, let list = lists.first(where: { $0.id == listId }) {
            selectedFolderId = list.folderId
        }
        guard let spaceId = selectedSpaceId else { return }
        await loadTasks(for: spaceId)
    }

    func selectFolder(_ folderId: UUID?) async {
        selectedFolderId = folderId
        if let folderId {
            expandedFolderIds.insert(folderId)
            if let first = lists(in: folderId).first {
                await selectList(first.id)
            } else {
                await selectList(nil)
            }
        }
    }

    func toggleFolderExpanded(_ folderId: UUID) {
        if expandedFolderIds.contains(folderId) {
            expandedFolderIds.remove(folderId)
        } else {
            expandedFolderIds.insert(folderId)
        }
    }

    func isFolderExpanded(_ folderId: UUID) -> Bool {
        expandedFolderIds.contains(folderId)
    }

    var standaloneLists: [SpaceListRecord] {
        lists.filter { $0.folderId == nil }.sorted { $0.sortOrder < $1.sortOrder }
    }

    func lists(in folderId: UUID) -> [SpaceListRecord] {
        lists.filter { $0.folderId == folderId }.sorted { $0.sortOrder < $1.sortOrder }
    }

    var breadcrumbItems: [SpacesBreadcrumbItem] {
        guard let space = selectedSpace else { return [] }
        var items: [SpacesBreadcrumbItem] = []
        items.append(
            SpacesBreadcrumbItem(
                kind: .space,
                title: space.name,
                spaceId: space.id,
                folderId: nil,
                listId: nil,
                isLast: false
            )
        )
        let activeFolderId = selectedFolderId
            ?? lists.first(where: { $0.id == selectedListId })?.folderId
        if let folderId = activeFolderId,
           let folder = folders.first(where: { $0.id == folderId }) {
            items.append(
                SpacesBreadcrumbItem(
                    kind: .folder,
                    title: folder.name,
                    spaceId: space.id,
                    folderId: folderId,
                    listId: nil,
                    isLast: false
                )
            )
        }
        if let listId = selectedListId,
           let list = lists.first(where: { $0.id == listId }) {
            items.append(
                SpacesBreadcrumbItem(
                    kind: .list,
                    title: list.name,
                    spaceId: space.id,
                    folderId: list.folderId,
                    listId: listId,
                    isLast: false
                )
            )
        }
        guard !items.isEmpty else { return items }
        let last = items.count - 1
        let tail = items[last]
        items[last] = SpacesBreadcrumbItem(
            kind: tail.kind,
            title: tail.title,
            spaceId: tail.spaceId,
            folderId: tail.folderId,
            listId: tail.listId,
            isLast: true
        )
        return items
    }

    func navigateBreadcrumb(_ item: SpacesBreadcrumbItem) async {
        switch item.kind {
        case .space:
            if let spaceId = item.spaceId {
                selectedFolderId = nil
                await selectList(nil)
                await selectSpace(spaceId, recordHistory: false)
            }
        case .folder:
            if let folderId = item.folderId {
                await selectFolder(folderId)
            }
        case .list:
            if let listId = item.listId {
                await selectList(listId)
            }
        }
    }

    func createFolder() async {
        guard let service, let spaceId = selectedSpaceId else { return }
        let name = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        do {
            let folder = try await service.createFolder(spaceId: spaceId, name: name)
            newFolderName = ""
            folders.append(folder)
            expandedFolderIds.insert(folder.id)
            let list = try await service.createList(spaceId: spaceId, folderId: folder.id, name: "List")
            lists.append(list)
            await selectList(list.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createList() async {
        guard let service, let spaceId = selectedSpaceId else { return }
        let name = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        do {
            let list = try await service.createList(spaceId: spaceId, folderId: selectedFolderId, name: name)
            newListName = ""
            lists.append(list)
            await selectList(list.id)
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

    func loadWhiteboards(for spaceId: UUID) async {
        guard let service else { return }
        do {
            whiteboards = try await service.fetchWhiteboards(spaceId: spaceId)
            if selectedWhiteboardId == nil {
                selectedWhiteboardId = whiteboards.first?.id
            }
        } catch {
            whiteboards = []
        }
    }

    func createWhiteboard() async {
        guard let service,
              let workspaceId,
              let spaceId = selectedSpaceId,
              let userId else { return }
        let name = "Whiteboard \(whiteboards.count + 1)"
        do {
            let board = try await service.createWhiteboard(
                workspaceId: workspaceId,
                spaceId: spaceId,
                name: name,
                createdBy: userId
            )
            whiteboards.insert(board, at: 0)
            selectedWhiteboardId = board.id
            taskView = .whiteboard
        } catch {
            errorMessage = error.localizedDescription
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
        guard let service else {
            errorMessage = "Sign in to create spaces."
            return
        }
        guard let workspaceId else {
            errorMessage = "Select a workspace before creating a space."
            return
        }
        guard let userId else {
            errorMessage = "Your session is not ready. Wait a moment or sign out and back in."
            return
        }
        let name = newSpaceName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            errorMessage = "Enter a space name."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let space = try await service.createSpace(
                workspaceId: workspaceId,
                ownerId: userId,
                name: name,
                type: newSpaceType.wireValue
            )
            let description = newSpaceDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            if !description.isEmpty {
                try await service.updateSpace(id: space.id, description: description)
            }
            newSpaceName = ""
            newSpaceDescription = ""
            newSpaceType = .general
            showNewSpaceSheet = false
            await reload()
            await selectSpace(space.id)
        } catch {
            errorMessage = friendlySpacesError(error)
        }
    }

    func saveDocument(_ document: SpaceDocumentRecord, title: String, content: String) async {
        guard let service else { return }
        do {
            let updated = try await service.updateDocument(id: document.id, title: title, content: content)
            if let idx = documents.firstIndex(where: { $0.id == document.id }) {
                documents[idx] = updated
            }
            editingDocument = nil
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
            let task = try await service.createTask(spaceId: spaceId, title: title, listId: selectedListId)
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

    func createDocument(openEditor: Bool = false) async {
        guard let service, let spaceId = selectedSpaceId else { return }
        let title = newDocumentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        do {
            let doc = try await service.createDocument(spaceId: spaceId, title: title)
            newDocumentTitle = ""
            documents.insert(doc, at: 0)
            if openEditor {
                editingDocument = doc
            }
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

    private func isNetworkError(_ error: Error) -> Bool {
        if error is URLError { return true }
        let ns = error as NSError
        return ns.domain == NSURLErrorDomain
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
        if text.contains("enum space_type") || text.contains("invalid input value for enum space_type") {
            return "Spaces database type column is outdated. Apply migration 20260523140000_spaces_type_legacy_enum_to_text.sql in Supabase, then tap Retry (or Settings → Sync now)."
        }
        if text.contains("is_pinned") || text.contains("pgrst") && text.contains("400") {
            return "Spaces database needs an upgrade. Your admin must apply migration 20260522100000_spaces_legacy_schema_upgrade.sql in Supabase."
        }
        if text.contains("does not exist") || text.contains("42p01") || text.contains("relation") {
            return "Spaces tables are missing in Supabase. Apply supabase/migrations/20260522010000_spaces_clickup_enterprise.sql to your project."
        }
        if text.contains("row-level security") || text.contains("permission denied") || text.contains("access denied") {
            return "You do not have access to Spaces in this workspace. Ask an admin to add you as a member."
        }
        return error.localizedDescription
    }
}
