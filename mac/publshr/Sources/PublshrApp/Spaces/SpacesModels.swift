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

    /// Kanban columns (ClickUp-style board).
    static let boardColumns: [SpaceTaskStatus] = [.todo, .in_progress, .review, .approved, .completed]
}

enum SpaceTaskPriority: String, Codable {
    case none, low, normal, high, urgent
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
    var dueDate: String?
    var sortOrder: Double

    enum CodingKeys: String, CodingKey {
        case id
        case spaceId = "space_id"
        case title, description, status, priority
        case dueDate = "due_date"
        case sortOrder = "sort_order"
    }
}
