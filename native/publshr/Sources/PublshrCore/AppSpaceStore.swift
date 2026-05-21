import Foundation

public enum AppSpaceStoreError: Error, LocalizedError {
    case listNotFound
    case taskNotFound
    case spaceNotFound

    public var errorDescription: String? {
        switch self {
        case .listNotFound: return "List not found"
        case .taskNotFound: return "Task not found"
        case .spaceNotFound: return "Space not found"
        }
    }
}

public final class AppSpaceStore: @unchecked Sendable {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let lock = NSLock()

    public init(fileURL: URL? = nil) {
        let url = fileURL ?? AppConfig.appSpaceDataPath
        self.fileURL = url
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    public func load() -> AppSpaceDocument {
        lock.lock()
        defer { lock.unlock() }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return Self.makeDefaultDocument()
        }
        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode(AppSpaceDocument.self, from: data)
        } catch {
            return Self.makeDefaultDocument()
        }
    }

    public func save(_ document: AppSpaceDocument) throws {
        lock.lock()
        defer { lock.unlock() }

        let dir = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let data = try encoder.encode(document)
        try data.write(to: fileURL, options: .atomic)
    }

    public static func makeDefaultDocument() -> AppSpaceDocument {
        let me = TeamMember(name: "You", email: "you@local", colorHex: "7B68EE")
        let teammate = TeamMember(name: "Teammate", email: "team@local", colorHex: "4194F0")
        let workspace = Workspace(name: "My Workspace", members: [me, teammate])

        let engineering = Space(name: "Engineering", colorHex: "7B68EE", icon: "hammer.fill", order: 0)
        let marketing = Space(name: "Marketing", colorHex: "FF6B6B", icon: "megaphone.fill", order: 1)

        let sprintFolder = Folder(spaceID: engineering.id, name: "Sprint", order: 0)

        let backlog = TaskList(spaceID: engineering.id, name: "Backlog", icon: "tray.full")
        let sprintList = TaskList(
            spaceID: engineering.id,
            folderID: sprintFolder.id,
            name: "Sprint Board",
            icon: "flag.fill"
        )
        let campaigns = TaskList(spaceID: marketing.id, name: "Campaigns", icon: "sparkles")

        let todoStatus = backlog.statuses.first!.id
        let inProgress = backlog.statuses[1].id
        let doneStatus = backlog.statuses.last!.id

        let now = Date()
        let tasks: [TaskItem] = [
            TaskItem(
                listID: backlog.id,
                name: "Design app space navigation",
                description: "Match ClickUp sidebar: Inbox, spaces, folders, lists.",
                statusID: doneStatus,
                priority: .high,
                assigneeIDs: [me.id],
                tagNames: ["design"],
                order: 0,
                createdAt: now,
                updatedAt: now
            ),
            TaskItem(
                listID: backlog.id,
                name: "Implement board view with drag-and-drop",
                description: "Columns per status; drag cards between columns.",
                statusID: inProgress,
                priority: .urgent,
                assigneeIDs: [me.id, teammate.id],
                tagNames: ["dev"],
                dueDate: Calendar.current.date(byAdding: .day, value: 3, to: now),
                order: 1,
                createdAt: now,
                updatedAt: now
            ),
            TaskItem(
                listID: sprintList.id,
                name: "Ship desktop task detail panel",
                statusID: todoStatus,
                priority: .normal,
                assigneeIDs: [teammate.id],
                order: 0,
                createdAt: now,
                updatedAt: now
            ),
            TaskItem(
                listID: campaigns.id,
                name: "Q2 launch checklist",
                description: "Landing page, email sequence, social posts.",
                statusID: todoStatus,
                priority: .low,
                dueDate: Calendar.current.date(byAdding: .day, value: 14, to: now),
                order: 0,
                createdAt: now,
                updatedAt: now
            ),
        ]

        return AppSpaceDocument(
            workspace: workspace,
            spaces: [engineering, marketing],
            folders: [sprintFolder],
            lists: [backlog, sprintList, campaigns],
            tasks: tasks,
            currentUserID: me.id
        )
    }
}
