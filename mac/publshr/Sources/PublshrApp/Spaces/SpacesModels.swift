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

struct SpaceRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let workspaceId: UUID
    var name: String
    var description: String
    var type: String
    var status: String
    var color: String
    var isPinned: Bool
    var isArchived: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case workspaceId = "workspace_id"
        case name, description, type, status, color
        case isPinned = "is_pinned"
        case isArchived = "is_archived"
    }
}

struct SpaceTaskRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let spaceId: UUID
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
        case title, description, status, priority
        case assigneeId = "assignee_id"
        case startDate = "start_date"
        case dueDate = "due_date"
        case tags, checklist
        case sortOrder = "sort_order"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        spaceId = try c.decode(UUID.self, forKey: .spaceId)
        title = try c.decode(String.self, forKey: .title)
        description = try c.decodeIfPresent(String.self, forKey: .description) ?? ""
        status = try c.decode(SpaceTaskStatus.self, forKey: .status)
        priority = try c.decodeIfPresent(SpaceTaskPriority.self, forKey: .priority) ?? .normal
        assigneeId = try c.decodeIfPresent(UUID.self, forKey: .assigneeId)
        startDate = try c.decodeIfPresent(String.self, forKey: .startDate)
        dueDate = try c.decodeIfPresent(String.self, forKey: .dueDate)
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        checklist = try c.decodeIfPresent([SpaceChecklistItem].self, forKey: .checklist) ?? []
        sortOrder = try c.decodeIfPresent(Double.self, forKey: .sortOrder) ?? 0
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

struct SpaceTaskPatch: Encodable {
    var title: String?
    var description: String?
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

    enum CodingKeys: String, CodingKey {
        case title, description, status, priority
        case assigneeId = "assignee_id"
        case startDate = "start_date"
        case dueDate = "due_date"
        case tags, checklist
        case sortOrder = "sort_order"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(title, forKey: .title)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(status, forKey: .status)
        try c.encodeIfPresent(priority, forKey: .priority)
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
