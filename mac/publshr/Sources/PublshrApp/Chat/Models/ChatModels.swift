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
        if kind == .channel {
            var n = name
            if n.hasPrefix("#") { n.removeFirst() }
            return "#\(n)"
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

    var isVoice: Bool { type == "voice" }
    var isVideo: Bool { type == "video" }
    var isImage: Bool { type == "image" }
    var isMediaAttachment: Bool { isVoice || isVideo || isImage }
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

// MARK: - Phase 2: Reactions

struct ChatReaction: Codable, Identifiable, Equatable {
    let id: UUID
    let workspaceId: UUID
    let messageId: UUID
    let userId: UUID
    let emoji: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, emoji
        case workspaceId = "workspace_id"
        case messageId = "message_id"
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

struct ChatReactionSummary: Equatable {
    let emoji: String
    let count: Int
    let userIds: [UUID]
    var includesMe: Bool = false
}

// MARK: - Phase 2: Pinned

struct ChatPinnedItem: Codable, Identifiable, Equatable {
    let id: UUID
    let workspaceId: UUID
    let channelId: UUID
    let messageId: UUID?
    let fileId: UUID?
    let pinnedBy: UUID
    var sortOrder: Int
    var note: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, note
        case workspaceId = "workspace_id"
        case channelId = "channel_id"
        case messageId = "message_id"
        case fileId = "file_id"
        case pinnedBy = "pinned_by"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
    }
}

// MARK: - Phase 2: Read receipts

struct ChatReadReceipt: Codable, Equatable {
    let messageId: UUID
    let workspaceId: UUID
    let userId: UUID
    let seenAt: Date

    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case workspaceId = "workspace_id"
        case userId = "user_id"
        case seenAt = "seen_at"
    }
}

// MARK: - Phase 2/3: Message links

enum ChatLinkType: String, Codable {
    case task
    case plannerItem = "planner_item"
    case campaign
    case document
    case report
    case coverage
    case approval
    case file
}

struct ChatMessageLink: Codable, Identifiable, Equatable {
    let id: UUID
    let workspaceId: UUID
    let messageId: UUID
    let linkType: ChatLinkType
    let linkId: UUID
    var preview: ChatLinkPreview
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, preview
        case workspaceId = "workspace_id"
        case messageId = "message_id"
        case linkType = "link_type"
        case linkId = "link_id"
        case createdAt = "created_at"
    }
}

struct ChatLinkPreview: Codable, Equatable {
    var title: String?
    var status: String?
    var dueDate: String?
    var owner: String?
    var subtitle: String?

    init(title: String? = nil, status: String? = nil, dueDate: String? = nil, owner: String? = nil, subtitle: String? = nil) {
        self.title = title
        self.status = status
        self.dueDate = dueDate
        self.owner = owner
        self.subtitle = subtitle
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let dict = try? c.decode([String: JSONValue].self) {
            title = dict["title"]?.stringValue
            status = dict["status"]?.stringValue
            dueDate = dict["due_date"]?.stringValue ?? dict["dueDate"]?.stringValue
            owner = dict["owner"]?.stringValue
            subtitle = dict["subtitle"]?.stringValue
        } else {
            title = nil; status = nil; dueDate = nil; owner = nil; subtitle = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        var dict: [String: String] = [:]
        if let title { dict["title"] = title }
        if let status { dict["status"] = status }
        if let dueDate { dict["due_date"] = dueDate }
        if let owner { dict["owner"] = owner }
        if let subtitle { dict["subtitle"] = subtitle }
        try c.encode(dict)
    }
}

private extension JSONValue {
    var stringValue: String? {
        if case .string(let s) = self { return s }
        return nil
    }
}

// MARK: - Phase 3: Voice

enum ChatTranscriptStatus: String, Codable {
    case pending, processing, ready, failed
}

struct ChatVoiceTranscript: Codable, Identifiable, Equatable {
    let id: UUID
    let workspaceId: UUID
    let messageId: UUID
    let storagePath: String
    var durationMs: Int
    var waveform: [Double]
    var transcript: String?
    var transcriptStatus: ChatTranscriptStatus
    var segments: [ChatTranscriptSegment]
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, transcript, segments
        case workspaceId = "workspace_id"
        case messageId = "message_id"
        case storagePath = "storage_path"
        case durationMs = "duration_ms"
        case waveform, transcriptStatus = "transcript_status"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ChatTranscriptSegment: Codable, Equatable {
    var startMs: Int
    var endMs: Int
    var text: String
}

// MARK: - Phase 4: Search & AI

struct ChatSearchHit: Identifiable, Equatable {
    let id: String
    let kind: ChatSearchKind
    let title: String
    let subtitle: String
    let channelId: UUID?
    let messageId: UUID?
    let createdAt: Date?
}

enum ChatSearchKind: String {
    case message, file, voice, user, channel, task
}

// MARK: - Planner task (for integration)

struct PlannerTask: Codable, Identifiable, Equatable {
    let id: UUID
    let workspaceId: UUID
    let title: String
    var status: String
    var dueDate: Date?
    var assigneeId: UUID?

    enum CodingKeys: String, CodingKey {
        case id, title, status
        case workspaceId = "workspace_id"
        case dueDate = "due_date"
        case assigneeId = "assignee_id"
    }
}

// MARK: - Mention parsing

struct ChatMentionToken: Equatable {
    let type: MentionType
    let raw: String
    let userId: UUID?

    enum MentionType { case user, channel, here, team }
}

enum ChatQuickReaction: String, CaseIterable {
    case thumbsUp = "👍"
    case heart = "❤️"
    case laugh = "😄"
    case eyes = "👀"
    case check = "✅"
}
