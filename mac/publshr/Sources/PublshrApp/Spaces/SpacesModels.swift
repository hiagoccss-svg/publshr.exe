import Foundation

enum SpaceTaskStatus: String, Codable, CaseIterable, Identifiable {
    case todo
    case in_progress
    case review
    case blocked
    case approved
    case completed
    case archived

    var id: String { rawValue }

    var label: String {
        switch self {
        case .todo: return "To Do"
        case .in_progress: return "In Progress"
        case .review: return "Review"
        case .blocked: return "Blocked"
        case .approved: return "Approved"
        case .completed: return "Completed"
        case .archived: return "Archived"
        }
    }

    static let boardColumns: [SpaceTaskStatus] = [.todo, .in_progress, .review, .approved, .completed]

    /// Value for Supabase `task_status` (legacy planner enum vs ClickUp text column).
    var databaseValue: String { TaskStatusWire.toDatabase(rawValue) }

    init(databaseValue: String) {
        let canonical = TaskStatusWire.fromDatabase(databaseValue)
        self = SpaceTaskStatus(rawValue: canonical) ?? .todo
    }
}

/// Maps app task statuses to production Postgres `task_status` (`open`, `done`, …).
enum TaskStatusWire {
    private static let toLegacy: [String: String] = [
        SpaceTaskStatus.todo.rawValue: "open",
        SpaceTaskStatus.completed.rawValue: "done",
        SpaceTaskStatus.archived.rawValue: "cancelled",
        SpaceTaskStatus.blocked.rawValue: "review",
        SpaceTaskStatus.approved.rawValue: "review",
    ]

    private static let fromLegacy: [String: String] = [
        "open": SpaceTaskStatus.todo.rawValue,
        "done": SpaceTaskStatus.completed.rawValue,
        "cancelled": SpaceTaskStatus.archived.rawValue,
    ]

    static func toDatabase(_ appStatus: String) -> String {
        let key = appStatus.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let mapped = toLegacy[key] { return mapped }
        if fromLegacy[key] != nil || SpaceTaskStatus(rawValue: key) != nil { return key }
        return "open"
    }

    static func fromDatabase(_ stored: String) -> String {
        let key = stored.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let mapped = fromLegacy[key] { return mapped }
        if SpaceTaskStatus(rawValue: key) != nil { return key }
        return SpaceTaskStatus.todo.rawValue
    }
}

/// Maps app priorities to production `tasks.priority` check (`medium` vs `normal`).
enum TaskPriorityWire {
    static func toDatabase(_ appPriority: String) -> String? {
        let key = appPriority.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch key {
        case SpaceTaskPriority.none.rawValue: return nil
        case SpaceTaskPriority.normal.rawValue: return "medium"
        case SpaceTaskPriority.low.rawValue, SpaceTaskPriority.high.rawValue, SpaceTaskPriority.urgent.rawValue:
            return key
        default:
            return "medium"
        }
    }

    static func fromDatabase(_ stored: String?) -> String {
        guard let stored else { return SpaceTaskPriority.none.rawValue }
        let key = stored.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if key == "medium" { return SpaceTaskPriority.normal.rawValue }
        if SpaceTaskPriority(rawValue: key) != nil { return key }
        return SpaceTaskPriority.normal.rawValue
    }
}

/// Top-level space kinds — no separate `project` type; use folders inside a Space (ClickUp-style).
enum SpaceTypeOption: String, CaseIterable, Identifiable {
    case general
    case department
    case client
    case campaign
    case initiative
    case editorial
    case operation
    case launch
    case event
    case retainer
    case publication

    var id: String { rawValue }

    var label: String {
        switch self {
        case .general: return "General"
        case .department: return "Department"
        case .client: return "Client"
        case .campaign: return "Campaign"
        case .initiative: return "Initiative"
        case .editorial: return "Editorial"
        case .operation: return "Operation"
        case .launch: return "Launch"
        case .event: return "Event"
        case .retainer: return "Retainer"
        case .publication: return "Publication"
        }
    }

    /// Legacy rows stored as `project` map to initiative in UI and filters.
    static func resolved(rawType: String) -> SpaceTypeOption {
        let normalized = SpacesHomeLogic.normalizeSpaceType(rawType)
        return SpaceTypeOption(rawValue: normalized) ?? .general
    }

    /// Value sent to Supabase on insert/update (must match `spaces.type` column).
    var wireValue: String { rawValue }

    /// Map legacy Postgres `space_type` enum labels to canonical app types.
    static func fromWire(_ wire: String) -> SpaceTypeOption {
        resolved(rawType: wire)
    }
}

/// Encode/decode space kinds for Supabase (legacy enum + text column).
enum SpaceTypeWire {
    private static let legacyToCanonical: [String: String] = [
        "project": SpaceTypeOption.initiative.rawValue,
        "folder": SpaceTypeOption.operation.rawValue,
        "list": SpaceTypeOption.general.rawValue,
        "board": SpaceTypeOption.operation.rawValue,
        "channel": SpaceTypeOption.general.rawValue,
    ]

    static func toDatabase(_ appType: String) -> String {
        let key = appType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if SpaceTypeOption(rawValue: key) != nil { return key }
        if let mapped = legacyToCanonical[key] { return mapped }
        return SpaceTypeOption.general.rawValue
    }

    static func fromDatabase(_ stored: String) -> String {
        let key = stored.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if key.isEmpty { return SpaceTypeOption.general.rawValue }
        if let mapped = legacyToCanonical[key] { return mapped }
        if SpaceTypeOption(rawValue: key) != nil { return key }
        return SpaceTypeOption.general.rawValue
    }
}

enum SpaceTaskPriority: String, Codable, CaseIterable, Identifiable {
    case none, low, normal, high, urgent

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: return "None"
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
}

struct SpaceChecklistItem: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var done: Bool

    init(id: String = UUID().uuidString, title: String, done: Bool = false) {
        self.id = id
        self.title = title
        self.done = done
    }
}

struct SpaceFolderRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let spaceId: UUID
    var name: String
    var sortOrder: Double
    var isArchived: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case spaceId = "space_id"
        case name
        case sortOrder = "sort_order"
        case isArchived = "is_archived"
    }
}

struct SpaceListRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let spaceId: UUID
    var folderId: UUID?
    var name: String
    var sortOrder: Double
    var isArchived: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case spaceId = "space_id"
        case folderId = "folder_id"
        case name
        case sortOrder = "sort_order"
        case isArchived = "is_archived"
    }
}

struct SpaceRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let workspaceId: UUID
    var name: String
    var description: String
    var type: String
    var status: String
    var color: String
    var isPinned: Bool
    var isFavourite: Bool
    var isArchived: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case workspaceId = "workspace_id"
        case name, description, type, status, color
        case isPinned = "is_pinned"
        case isFavourite = "is_favourite"
        case isArchived = "is_archived"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        workspaceId = try c.decode(UUID.self, forKey: .workspaceId)
        name = try c.decode(String.self, forKey: .name)
        description = try c.decodeIfPresent(String.self, forKey: .description) ?? ""
        let rawType = try c.decodeIfPresent(String.self, forKey: .type) ?? "general"
        type = SpaceTypeWire.fromDatabase(rawType)
        status = try c.decodeIfPresent(String.self, forKey: .status) ?? "active"
        color = try c.decodeIfPresent(String.self, forKey: .color) ?? "#3d5a80"
        isPinned = try c.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        isFavourite = try c.decodeIfPresent(Bool.self, forKey: .isFavourite) ?? false
        isArchived = try c.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(workspaceId, forKey: .workspaceId)
        try c.encode(name, forKey: .name)
        try c.encode(description, forKey: .description)
        try c.encode(type, forKey: .type)
        try c.encode(status, forKey: .status)
        try c.encode(color, forKey: .color)
        try c.encode(isPinned, forKey: .isPinned)
        try c.encode(isFavourite, forKey: .isFavourite)
        try c.encode(isArchived, forKey: .isArchived)
    }
}

struct SpaceTaskRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let spaceId: UUID
    var listId: UUID?
    var title: String
    var description: String
    var status: SpaceTaskStatus
    var priority: SpaceTaskPriority
    var assigneeId: UUID?
    var startDate: String?
    var dueDate: String?
    var tags: [String]
    var checklist: [SpaceChecklistItem]
    var sortOrder: Double

    enum CodingKeys: String, CodingKey {
        case id
        case spaceId = "space_id"
        case listId = "list_id"
        case title, description, status, priority
        case assigneeId = "assignee_id"
        case startDate = "start_date"
        case dueDate = "due_date"
        case tags, checklist
        case sortOrder = "sort_order"
        case isArchived = "is_archived"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        spaceId = try c.decode(UUID.self, forKey: .spaceId)
        listId = try c.decodeIfPresent(UUID.self, forKey: .listId)
        title = try c.decode(String.self, forKey: .title)
        description = try c.decodeIfPresent(String.self, forKey: .description) ?? ""
        if let rawStatus = try? c.decode(String.self, forKey: .status) {
            status = SpaceTaskStatus(databaseValue: rawStatus)
        } else {
            status = try c.decode(SpaceTaskStatus.self, forKey: .status)
        }
        if c.contains(.isArchived), try c.decode(Bool.self, forKey: .isArchived) {
            status = .archived
        }
        if let rawPriority = try? c.decode(String.self, forKey: .priority) {
            priority = SpaceTaskPriority(rawValue: TaskPriorityWire.fromDatabase(rawPriority)) ?? .normal
        } else {
            priority = try c.decodeIfPresent(SpaceTaskPriority.self, forKey: .priority) ?? .normal
        }
        assigneeId = try c.decodeIfPresent(UUID.self, forKey: .assigneeId)
        startDate = try c.decodeIfPresent(String.self, forKey: .startDate)
        dueDate = try c.decodeIfPresent(String.self, forKey: .dueDate)
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        checklist = try c.decodeIfPresent([SpaceChecklistItem].self, forKey: .checklist) ?? []
        sortOrder = try c.decodeIfPresent(Double.self, forKey: .sortOrder) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(spaceId, forKey: .spaceId)
        try c.encodeIfPresent(listId, forKey: .listId)
        try c.encode(title, forKey: .title)
        try c.encode(description, forKey: .description)
        try c.encode(status.databaseValue, forKey: .status)
        if let dbPriority = TaskPriorityWire.toDatabase(priority.rawValue) {
            try c.encode(dbPriority, forKey: .priority)
        } else {
            try c.encodeNil(forKey: .priority)
        }
        try c.encodeIfPresent(assigneeId, forKey: .assigneeId)
        try c.encodeIfPresent(startDate, forKey: .startDate)
        try c.encodeIfPresent(dueDate, forKey: .dueDate)
        try c.encode(tags, forKey: .tags)
        try c.encode(checklist, forKey: .checklist)
        try c.encode(sortOrder, forKey: .sortOrder)
        if status == .archived {
            try c.encode(true, forKey: .isArchived)
        }
    }

    var checklistDoneCount: Int {
        checklist.filter(\.done).count
    }

    var checklistProgressLabel: String? {
        guard !checklist.isEmpty else { return nil }
        return "\(checklistDoneCount)/\(checklist.count)"
    }
}

struct SpaceActivityRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let spaceId: UUID
    let userId: UUID
    let action: String
    let entityType: String
    let entityId: UUID
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case spaceId = "space_id"
        case userId = "user_id"
        case action
        case entityType = "entity_type"
        case entityId = "entity_id"
        case createdAt = "created_at"
    }
}

struct SpaceCommentRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let spaceId: UUID
    let taskId: UUID?
    let userId: UUID
    let body: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case spaceId = "space_id"
        case taskId = "task_id"
        case userId = "user_id"
        case body
        case createdAt = "created_at"
    }
}

struct SpaceApprovalRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let spaceId: UUID
    let taskId: UUID?
    let documentId: UUID?
    var status: String
    var title: String
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case spaceId = "space_id"
        case taskId = "task_id"
        case documentId = "document_id"
        case status, title
        case updatedAt = "updated_at"
    }

    var isPending: Bool {
        status == "requested" || status == "in_review"
    }
}

struct SpaceFileRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let spaceId: UUID
    var fileName: String
    var fileUrl: String
    var mimeType: String
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case spaceId = "space_id"
        case fileName = "file_name"
        case fileUrl = "file_url"
        case mimeType = "mime_type"
        case updatedAt = "updated_at"
    }
}

struct SpacesWorkspaceSummary: Equatable {
    var spaceCount: Int
    var openTasks: Int
    var overdueTasks: Int
    var documentCount: Int
    var pendingApprovals: Int
}

struct SpaceDocumentRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let spaceId: UUID
    var title: String
    var docType: String
    var content: String
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case spaceId = "space_id"
        case title
        case docType = "doc_type"
        case content
        case updatedAt = "updated_at"
    }
}

/// Collaborative canvas (tldraw snapshot stored in Supabase `whiteboards.snapshot`).
struct SpaceWhiteboardRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let workspaceId: UUID
    let spaceId: UUID
    var name: String
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case workspaceId = "workspace_id"
        case spaceId = "space_id"
        case name
        case updatedAt = "updated_at"
    }
}

struct SpaceTaskPatch: Encodable {
    var title: String?
    var description: String?
    var listId: UUID?
    var status: String?
    var priority: String?
    var assigneeId: UUID?
    var clearAssignee: Bool = false
    var startDate: String?
    var clearStartDate: Bool = false
    var dueDate: String?
    var clearDueDate: Bool = false
    var tags: [String]?
    var checklist: [SpaceChecklistItem]?
    var sortOrder: Double?
    var isArchived: Bool?

    enum CodingKeys: String, CodingKey {
        case title, description
        case listId = "list_id"
        case status, priority
        case assigneeId = "assignee_id"
        case startDate = "start_date"
        case dueDate = "due_date"
        case tags, checklist
        case sortOrder = "sort_order"
        case isArchived = "is_archived"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(title, forKey: .title)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(listId, forKey: .listId)
        if let status {
            try c.encode(TaskStatusWire.toDatabase(status), forKey: .status)
        }
        if let priority {
            if let db = TaskPriorityWire.toDatabase(priority) {
                try c.encode(db, forKey: .priority)
            } else {
                try c.encodeNil(forKey: .priority)
            }
        }
        try c.encodeIfPresent(isArchived, forKey: .isArchived)
        if clearAssignee {
            try c.encodeNil(forKey: .assigneeId)
        } else if let assigneeId {
            try c.encode(assigneeId, forKey: .assigneeId)
        }
        if clearStartDate {
            try c.encodeNil(forKey: .startDate)
        } else if let startDate {
            try c.encode(startDate, forKey: .startDate)
        }
        if clearDueDate {
            try c.encodeNil(forKey: .dueDate)
        } else if let dueDate {
            try c.encode(dueDate, forKey: .dueDate)
        }
        try c.encodeIfPresent(tags, forKey: .tags)
        try c.encodeIfPresent(checklist, forKey: .checklist)
        try c.encodeIfPresent(sortOrder, forKey: .sortOrder)
    }
}
