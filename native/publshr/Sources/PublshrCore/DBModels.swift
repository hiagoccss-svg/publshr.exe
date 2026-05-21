import Foundation

public struct ProfileRow: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var email: String?
    public var displayName: String?
    public var avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, email
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
    }
}

public struct WorkspaceRow: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var slug: String?
    public var ownerId: UUID?

    enum CodingKeys: String, CodingKey {
        case id, name, slug
        case ownerId = "owner_id"
    }
}

public struct SpaceRow: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var workspaceId: UUID
    public var parentId: UUID?
    public var name: String
    public var color: String?
    public var sortOrder: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, color
        case workspaceId = "workspace_id"
        case parentId = "parent_id"
        case sortOrder = "sort_order"
    }
}

public struct TaskRow: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var workspaceId: UUID
    public var spaceId: UUID?
    public var title: String
    public var status: String?
    public var priority: String?
    public var sortOrder: Int?

    enum CodingKeys: String, CodingKey {
        case id, title, status, priority
        case workspaceId = "workspace_id"
        case spaceId = "space_id"
        case sortOrder = "sort_order"
    }
}

public struct ChatChannelRow: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var workspaceId: UUID
    public var name: String
    public var kind: String?
    public var description: String?

    enum CodingKeys: String, CodingKey {
        case id, name, kind, description
        case workspaceId = "workspace_id"
    }
}

public struct ChatMessageRow: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var channelId: UUID
    public var userId: UUID
    public var body: String
    public var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, body
        case channelId = "channel_id"
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

public struct CreateWorkspaceParams: Encodable, Sendable {
    public let pName: String
    public let pSlug: String?

    enum CodingKeys: String, CodingKey {
        case pName = "p_name"
        case pSlug = "p_slug"
    }
}

public struct WorkspaceCreated: Codable, Sendable {
    public var id: UUID?
}
