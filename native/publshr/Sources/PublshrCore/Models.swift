import Foundation

/// Legacy offline catalog types (LocalStore). Not used by Supabase or App Space.
public struct OfflineCatalogSpace: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var colorHex: String
    public var folders: [OfflineSpaceFolder]

    public init(id: UUID = UUID(), name: String, colorHex: String, folders: [OfflineSpaceFolder] = []) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.folders = folders
    }
}

public struct OfflineSpaceFolder: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var lists: [OfflineSpaceList]

    public init(id: UUID = UUID(), name: String, lists: [OfflineSpaceList] = []) {
        self.id = id
        self.name = name
        self.lists = lists
    }
}

public struct OfflineSpaceList: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String

    public init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

public struct OfflineChatChannel: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var isDM: Bool
    public var spaceID: UUID?

    public init(id: UUID = UUID(), name: String, isDM: Bool = false, spaceID: UUID? = nil) {
        self.id = id
        self.name = name
        self.isDM = isDM
        self.spaceID = spaceID
    }
}

public struct OfflineChatMessage: Identifiable, Codable, Hashable {
    public var id: UUID
    public var channelID: UUID
    public var author: String
    public var body: String
    public var sentAt: Date

    public init(id: UUID = UUID(), channelID: UUID, author: String, body: String, sentAt: Date = .now) {
        self.id = id
        self.channelID = channelID
        self.author = author
        self.body = body
        self.sentAt = sentAt
    }
}

public struct WorkspaceData: Codable {
    public var spaces: [OfflineCatalogSpace]
    public var channels: [OfflineChatChannel]
    public var messages: [OfflineChatMessage]

    public init(
        spaces: [OfflineCatalogSpace] = [],
        channels: [OfflineChatChannel] = [],
        messages: [OfflineChatMessage] = []
    ) {
        self.spaces = spaces
        self.channels = channels
        self.messages = messages
    }
}
