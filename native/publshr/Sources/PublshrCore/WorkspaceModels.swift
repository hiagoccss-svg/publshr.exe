import Foundation

// MARK: - Identifiers

public struct WorkspaceID: Hashable, Codable, Sendable {
    public var raw: String
    public init(_ raw: String = UUID().uuidString) { self.raw = raw }
}

public struct SpaceID: Hashable, Codable, Sendable {
    public var raw: String
    public init(_ raw: String = UUID().uuidString) { self.raw = raw }
}

public struct FolderID: Hashable, Codable, Sendable {
    public var raw: String
    public init(_ raw: String = UUID().uuidString) { self.raw = raw }
}

public struct ListID: Hashable, Codable, Sendable {
    public var raw: String
    public init(_ raw: String = UUID().uuidString) { self.raw = raw }
}

public struct TaskID: Hashable, Codable, Sendable {
    public var raw: String
    public init(_ raw: String = UUID().uuidString) { self.raw = raw }
}

public struct UserID: Hashable, Codable, Sendable {
    public var raw: String
    public init(_ raw: String = UUID().uuidString) { self.raw = raw }
}

// MARK: - Enums

public enum TaskPriority: String, Codable, CaseIterable, Sendable {
    case none, low, normal, high, urgent

    public var label: String {
        switch self {
        case .none: return "None"
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
}

public enum ViewType: String, Codable, CaseIterable, Sendable {
    case list, board, calendar, table, timeline, gantt

    public var label: String {
        switch self {
        case .list: return "List"
        case .board: return "Board"
        case .calendar: return "Calendar"
        case .table: return "Table"
        case .timeline: return "Timeline"
        case .gantt: return "Gantt"
        }
    }

    public var systemImage: String {
        switch self {
        case .list: return "list.bullet"
        case .board: return "square.grid.2x2"
        case .calendar: return "calendar"
        case .table: return "tablecells"
        case .timeline: return "chart.bar.xaxis"
        case .gantt: return "chart.bar.doc.horizontal"
        }
    }
}

public enum SidebarSelection: Hashable, Codable, Sendable {
    case inbox
    case list(ListID)
    case space(SpaceID)
}

// MARK: - Domain models

public struct TeamMember: Codable, Identifiable, Hashable, Sendable {
    public var id: UserID
    public var name: String
    public var email: String
    public var colorHex: String

    public init(id: UserID = UserID(), name: String, email: String = "", colorHex: String = "7B68EE") {
        self.id = id
        self.name = name
        self.email = email
        self.colorHex = colorHex
    }
}

public struct TaskStatus: Codable, Identifiable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var colorHex: String
    public var order: Int
    public var isClosed: Bool

    public init(id: String = UUID().uuidString, name: String, colorHex: String, order: Int, isClosed: Bool = false) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.order = order
        self.isClosed = isClosed
    }

    public static func defaultStatuses() -> [TaskStatus] {
        [
            TaskStatus(name: "To Do", colorHex: "87909E", order: 0),
            TaskStatus(name: "In Progress", colorHex: "4194F0", order: 1),
            TaskStatus(name: "Review", colorHex: "F5C518", order: 2),
            TaskStatus(name: "Done", colorHex: "6BC950", order: 3, isClosed: true),
        ]
    }
}

public struct TaskComment: Codable, Identifiable, Hashable, Sendable {
    public var id: String
    public var authorID: UserID
    public var body: String
    public var createdAt: Date

    public init(id: String = UUID().uuidString, authorID: UserID, body: String, createdAt: Date = Date()) {
        self.id = id
        self.authorID = authorID
        self.body = body
        self.createdAt = createdAt
    }
}

public struct ChecklistItem: Codable, Identifiable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var isDone: Bool

    public init(id: String = UUID().uuidString, title: String, isDone: Bool = false) {
        self.id = id
        self.title = title
        self.isDone = isDone
    }
}

public struct TaskItem: Codable, Identifiable, Hashable, Sendable {
    public var id: TaskID
    public var listID: ListID
    public var parentTaskID: TaskID?
    public var name: String
    public var description: String
    public var statusID: String
    public var priority: TaskPriority
    public var assigneeIDs: [UserID]
    public var tagNames: [String]
    public var dueDate: Date?
    public var startDate: Date?
    public var timeEstimateMinutes: Int?
    public var order: Double
    public var comments: [TaskComment]
    public var checklist: [ChecklistItem]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: TaskID = TaskID(),
        listID: ListID,
        parentTaskID: TaskID? = nil,
        name: String,
        description: String = "",
        statusID: String,
        priority: TaskPriority = .normal,
        assigneeIDs: [UserID] = [],
        tagNames: [String] = [],
        dueDate: Date? = nil,
        startDate: Date? = nil,
        timeEstimateMinutes: Int? = nil,
        order: Double = 0,
        comments: [TaskComment] = [],
        checklist: [ChecklistItem] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.listID = listID
        self.parentTaskID = parentTaskID
        self.name = name
        self.description = description
        self.statusID = statusID
        self.priority = priority
        self.assigneeIDs = assigneeIDs
        self.tagNames = tagNames
        self.dueDate = dueDate
        self.startDate = startDate
        self.timeEstimateMinutes = timeEstimateMinutes
        self.order = order
        self.comments = comments
        self.checklist = checklist
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct TaskList: Codable, Identifiable, Hashable, Sendable {
    public var id: ListID
    public var spaceID: SpaceID
    public var folderID: FolderID?
    public var name: String
    public var icon: String
    public var statuses: [TaskStatus]
    public var order: Int

    public init(
        id: ListID = ListID(),
        spaceID: SpaceID,
        folderID: FolderID? = nil,
        name: String,
        icon: String = "list.bullet",
        statuses: [TaskStatus] = TaskStatus.defaultStatuses(),
        order: Int = 0
    ) {
        self.id = id
        self.spaceID = spaceID
        self.folderID = folderID
        self.name = name
        self.icon = icon
        self.statuses = statuses
        self.order = order
    }
}

public struct Folder: Codable, Identifiable, Hashable, Sendable {
    public var id: FolderID
    public var spaceID: SpaceID
    public var name: String
    public var order: Int

    public init(id: FolderID = FolderID(), spaceID: SpaceID, name: String, order: Int = 0) {
        self.id = id
        self.spaceID = spaceID
        self.name = name
        self.order = order
    }
}

public struct Space: Codable, Identifiable, Hashable, Sendable {
    public var id: SpaceID
    public var name: String
    public var colorHex: String
    public var icon: String
    public var isPrivate: Bool
    public var order: Int

    public init(
        id: SpaceID = SpaceID(),
        name: String,
        colorHex: String = "7B68EE",
        icon: String = "folder.fill",
        isPrivate: Bool = false,
        order: Int = 0
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.isPrivate = isPrivate
        self.order = order
    }
}

public struct Workspace: Codable, Identifiable, Hashable, Sendable {
    public var id: WorkspaceID
    public var name: String
    public var members: [TeamMember]

    public init(id: WorkspaceID = WorkspaceID(), name: String, members: [TeamMember] = []) {
        self.id = id
        self.name = name
        self.members = members
    }
}

public struct AppSpaceDocument: Codable, Sendable {
    public var workspace: Workspace
    public var spaces: [Space]
    public var folders: [Folder]
    public var lists: [TaskList]
    public var tasks: [TaskItem]
    public var currentUserID: UserID

    public init(
        workspace: Workspace,
        spaces: [Space] = [],
        folders: [Folder] = [],
        lists: [TaskList] = [],
        tasks: [TaskItem] = [],
        currentUserID: UserID
    ) {
        self.workspace = workspace
        self.spaces = spaces
        self.folders = folders
        self.lists = lists
        self.tasks = tasks
        self.currentUserID = currentUserID
    }
}
