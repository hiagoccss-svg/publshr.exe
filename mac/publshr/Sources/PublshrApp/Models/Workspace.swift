import Foundation

struct Workspace: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var slug: String
    var logoUrl: String?
    let ownerId: UUID
    var planId: String
    var settings: [String: JSONValue]?

    enum CodingKeys: String, CodingKey {
        case id, name, slug
        case logoUrl = "logo_url"
        case ownerId = "owner_id"
        case planId = "plan_id"
        case settings
    }
}

struct WorkspaceMember: Codable, Identifiable, Equatable {
    let workspaceId: UUID
    let userId: UUID
    var role: String
    var joinedAt: Date

    var id: String { "\(workspaceId.uuidString)-\(userId.uuidString)" }

    enum CodingKeys: String, CodingKey {
        case workspaceId = "workspace_id"
        case userId = "user_id"
        case role
        case joinedAt = "joined_at"
    }
}

/// Lightweight JSON helper for workspace settings blobs.
enum JSONValue: Codable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let v = try? container.decode(Bool.self) { self = .bool(v) }
        else if let v = try? container.decode(Double.self) { self = .number(v) }
        else if let v = try? container.decode(String.self) { self = .string(v) }
        else if let v = try? container.decode([String: JSONValue].self) { self = .object(v) }
        else if let v = try? container.decode([JSONValue].self) { self = .array(v) }
        else { self = .null }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let v): try container.encode(v)
        case .number(let v): try container.encode(v)
        case .bool(let v): try container.encode(v)
        case .object(let v): try container.encode(v)
        case .array(let v): try container.encode(v)
        case .null: try container.encodeNil()
        }
    }
}
