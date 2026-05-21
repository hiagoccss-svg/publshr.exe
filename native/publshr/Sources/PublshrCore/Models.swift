import Foundation

public struct Space: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var colorHex: String
    public var folders: [SpaceFolder]

    public init(id: UUID = UUID(), name: String, colorHex: String, folders: [SpaceFolder] = []) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.folders = folders
    }
}

public struct SpaceFolder: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var lists: [SpaceList]

    public init(id: UUID = UUID(), name: String, lists: [SpaceList] = []) {
        self.id = id
        self.name = name
        self.lists = lists
    }
}

public struct SpaceList: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String

    public init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

public struct ChatChannel: Identifiable, Codable, Hashable {
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

public struct ChatMessage: Identifiable, Codable, Hashable {
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
    public var spaces: [Space]
    public var channels: [ChatChannel]
    public var messages: [ChatMessage]

    public init(spaces: [Space] = [], channels: [ChatChannel] = [], messages: [ChatMessage] = []) {
        self.spaces = spaces
        self.channels = channels
        self.messages = messages
    }
}
