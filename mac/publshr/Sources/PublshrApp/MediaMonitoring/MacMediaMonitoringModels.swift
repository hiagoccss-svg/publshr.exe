import Foundation

enum MediaSentiment: String, Codable {
    case positive, neutral, negative, mixed
}

struct MediaMonitorRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let workspaceId: UUID
    var name: String
    var keywords: String
    var isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case workspaceId = "workspace_id"
        case name, keywords
        case isActive = "is_active"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        workspaceId = try c.decode(UUID.self, forKey: .workspaceId)
        name = try c.decode(String.self, forKey: .name)
        keywords = try c.decode(String.self, forKey: .keywords)
        isActive = try c.decodeIfPresent(Bool.self, forKey: .isActive) ?? false
    }
}

struct MediaMonitorResultRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let monitorProfileId: UUID
    var title: String
    var url: String?
    var author: String?
    var publishedAt: String?
    var sentiment: String
    var publicationName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case monitorProfileId = "monitor_profile_id"
        case title, url, author
        case publishedAt = "published_at"
        case sentiment
        case publicationName = "publication_name"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        monitorProfileId = try c.decode(UUID.self, forKey: .monitorProfileId)
        title = try c.decode(String.self, forKey: .title)
        url = try c.decodeIfPresent(String.self, forKey: .url)
        author = try c.decodeIfPresent(String.self, forKey: .author)
        publishedAt = try c.decodeIfPresent(String.self, forKey: .publishedAt)
        sentiment = try c.decodeIfPresent(String.self, forKey: .sentiment) ?? "neutral"
        publicationName = try c.decodeIfPresent(String.self, forKey: .publicationName)
    }
}
