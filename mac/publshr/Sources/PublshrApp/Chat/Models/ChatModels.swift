import Foundation

// MARK: - Channel

enum ChatChannelKind: String, Codable, CaseIterable {
    case channel
    case dm
    case group
    case thread
}

enum ChatChannelVisibility: String, Codable, CaseIterable {
    case `public`
    case `private`
    case `internal`
    case clientSafe = "client_safe"
    case announcement
    case readOnly = "read_only"
    case hidden
    case inviteOnly = "invite_only"
}

struct ChatChannel: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let workspaceId: UUID
    var name: String
    var description: String?
    var kind: ChatChannelKind
    var visibility: ChatChannelVisibility
    var isArchived: Bool
    var lastMessageAt: Date?
    var messageCount: Int
    let createdBy: UUID?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, description, kind, visibility
        case workspaceId = "workspace_id"
        case isArchived = "is_archived"
        case lastMessageAt = "last_message_at"
        case messageCount = "message_count"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var displayTitle: String {
        if kind == .dm, name.hasPrefix("dm:") {
            return String(name.dropFirst(3))
        }
        if kind == .channel, !name.hasPrefix("#") {
            return "#\(name)"
        }
        return name
    }

    var sidebarIcon: String {
        switch kind {
        case .channel: visibility == .announcement ? "megaphone" : "number"
        case .dm: "person"
        case .group: "person.3"
        case .thread: "bubble.left.and.bubble.right"
        }
    }
}

// MARK: - Message

enum ChatDeliveryStatus: String, Codable {
    case sending
    case sent
    case delivered
    case seen
    case failed
}

struct ChatMessage: Codable, Identifiable, Equatable {
    let id: UUID
    let workspaceId: UUID
    let channelId: UUID
    let userId: UUID
    var body: String?
    var threadParentId: UUID?
    var attachments: [ChatAttachment]
    var isEdited: Bool
    var isDeleted: Bool
    let createdAt: Date
    var updatedAt: Date

    /// Client-only delivery state (not persisted server-side in Phase 1).
    var localStatus: ChatDeliveryStatus = .sent

    enum CodingKeys: String, CodingKey {
        case id, body, attachments
        case workspaceId = "workspace_id"
        case channelId = "channel_id"
        case userId = "user_id"
        case threadParentId = "thread_parent_id"
        case isEdited = "is_edited"
        case isDeleted = "is_deleted"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ChatAttachment: Codable, Equatable {
    var type: String
    var url: String?
    var name: String?
    var size: Int?
    /// Phase 3: voice note duration, waveform, transcript reference.
    var voiceNoteDurationMs: Int?
    var transcriptId: UUID?
}

// MARK: - Presence

enum ChatPresenceStatus: String, Codable, CaseIterable {
    case online
    case away
    case busy
    case inMeeting = "in_meeting"
    case offline
    case invisible

    var label: String {
        switch self {
        case .online: "Online"
        case .away: "Away"
        case .busy: "Busy"
        case .inMeeting: "In a meeting"
        case .offline: "Offline"
        case .invisible: "Invisible"
        }
    }

    var colorName: String {
        switch self {
        case .online: "green"
        case .away: "yellow"
        case .busy, .inMeeting: "red"
        case .offline, .invisible: "gray"
        }
    }
}

struct ChatPresence: Codable, Identifiable, Equatable {
    let workspaceId: UUID
    let userId: UUID
    var status: ChatPresenceStatus
    var activity: String?
    var lastSeenAt: Date
    var updatedAt: Date

    var id: String { "\(workspaceId.uuidString)-\(userId.uuidString)" }

    enum CodingKeys: String, CodingKey {
        case status, activity
        case workspaceId = "workspace_id"
        case userId = "user_id"
        case lastSeenAt = "last_seen_at"
        case updatedAt = "updated_at"
    }
}

struct ChatChannelMember: Codable, Identifiable, Equatable {
    let id: UUID
    let workspaceId: UUID
    let channelId: UUID
    let userId: UUID
    var role: String
    var lastReadAt: Date?
    var notificationLevel: String
    var joinedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, role
        case workspaceId = "workspace_id"
        case channelId = "channel_id"
        case userId = "user_id"
        case lastReadAt = "last_read_at"
        case notificationLevel = "notification_level"
        case joinedAt = "joined_at"
    }
}

// MARK: - Workspace chat permissions (stored in workspaces.settings.chat)

struct ChatWorkspacePermissions: Codable, Equatable {
    var canCreateChannels: Bool = true
    var canCreateGroupChats: Bool = true
    var canDM: Bool = true
    var canInviteUsers: Bool = true
    var canAddGuests: Bool = false
    var canDeleteMessages: Bool = true
    var canEditMessages: Bool = true
    var canPinMessages: Bool = true
    var canUploadFiles: Bool = true
    var canUseVoiceNotes: Bool = true
    var canExportChats: Bool = false
    var readReceiptsEnabled: Bool = false

    static let `default` = ChatWorkspacePermissions()
}

struct ChatTypingState: Equatable {
    let channelId: UUID
    let userId: UUID
    let displayName: String
    let expiresAt: Date
}

struct ChatDraft: Codable, Equatable {
    let channelId: UUID
    var body: String
    var updatedAt: Date
}
