import Foundation
import Supabase

@MainActor
public final class SupabaseService: ObservableObject {
    public static let shared = SupabaseService()

    public let client: SupabaseClient

    @Published public private(set) var sessionUserId: UUID?
    @Published public private(set) var profile: ProfileRow?

    private init() {
        client = SupabaseClient(supabaseURL: SupabaseConfig.url, supabaseKey: SupabaseConfig.anonKey)
        Task { await refreshSession() }
    }

    public var isAuthenticated: Bool { sessionUserId != nil }

    public func refreshSession() async {
        if let session = try? await client.auth.session {
            sessionUserId = session.user.id
            await loadProfile()
        } else {
            sessionUserId = nil
            profile = nil
        }
    }

    public func signUp(email: String, password: String, displayName: String) async throws {
        _ = try await client.auth.signUp(email: email, password: password)
        await refreshSession()
        if sessionUserId != nil {
            _ = try await client.rpc(
                "create_workspace",
                params: CreateWorkspaceParams(pName: "\(displayName)'s Workspace", pSlug: nil)
            ).execute()
        }
        await loadProfile()
    }

    public func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
        await refreshSession()
    }

    public func signOut() async throws {
        try await client.auth.signOut()
        sessionUserId = nil
        profile = nil
    }

    public func loadProfile() async {
        guard let uid = sessionUserId else { return }
        let rows: [ProfileRow] = (try? await client.from("profiles").select().eq("id", value: uid.uuidString).execute().value) ?? []
        profile = rows.first
    }

    public func fetchWorkspaces() async throws -> [WorkspaceRow] {
        try await client.from("workspaces").select().order("name").execute().value
    }

    public func fetchSpaces(workspaceId: UUID) async throws -> [SpaceRow] {
        try await client.from("spaces").select().eq("workspace_id", value: workspaceId.uuidString).order("sort_order").execute().value
    }

    public func fetchChannels(workspaceId: UUID) async throws -> [ChatChannelRow] {
        try await client.from("chat_channels").select().eq("workspace_id", value: workspaceId.uuidString).order("name").execute().value
    }

    public func fetchMessages(channelId: UUID) async throws -> [ChatMessageRow] {
        try await client.from("chat_messages").select().eq("channel_id", value: channelId.uuidString).order("created_at").execute().value
    }

    public func sendMessage(channelId: UUID, body: String) async throws -> ChatMessageRow {
        guard let uid = sessionUserId else { throw SupabaseServiceError.notAuthenticated }
        let insert = InsertMessage(channelId: channelId, userId: uid, body: body)
        let rows: [ChatMessageRow] = try await client.from("chat_messages").insert(insert).select().execute().value
        guard let row = rows.first else { throw SupabaseServiceError.emptyResponse }
        return row
    }

    public func fetchTasks(workspaceId: UUID, spaceId: UUID?) async throws -> [TaskRow] {
        var query = client.from("tasks").select().eq("workspace_id", value: workspaceId.uuidString)
        if let spaceId {
            query = query.eq("space_id", value: spaceId.uuidString)
        }
        return try await query.order("sort_order").execute().value
    }

    public func createTask(workspaceId: UUID, spaceId: UUID?, title: String) async throws -> TaskRow {
        guard let uid = sessionUserId else { throw SupabaseServiceError.notAuthenticated }
        let insert = InsertTask(workspaceId: workspaceId, spaceId: spaceId, title: title, createdBy: uid)
        let rows: [TaskRow] = try await client.from("tasks").insert(insert).select().execute().value
        guard let row = rows.first else { throw SupabaseServiceError.emptyResponse }
        return row
    }

    public func createChannel(workspaceId: UUID, name: String) async throws -> ChatChannelRow {
        guard let uid = sessionUserId else { throw SupabaseServiceError.notAuthenticated }
        let insert = InsertChannel(workspaceId: workspaceId, name: name, createdBy: uid)
        let rows: [ChatChannelRow] = try await client.from("chat_channels").insert(insert).select().execute().value
        guard let row = rows.first else { throw SupabaseServiceError.emptyResponse }
        return row
    }

    public func createSpace(workspaceId: UUID, name: String, parentId: UUID?) async throws -> SpaceRow {
        let insert = InsertSpace(workspaceId: workspaceId, name: name, parentId: parentId)
        let rows: [SpaceRow] = try await client.from("spaces").insert(insert).select().execute().value
        guard let row = rows.first else { throw SupabaseServiceError.emptyResponse }
        return row
    }
}

public enum SupabaseServiceError: Error, LocalizedError {
    case notAuthenticated
    case emptyResponse

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Sign in required"
        case .emptyResponse: return "No data returned"
        }
    }
}

private struct InsertMessage: Encodable {
    let channelId: UUID
    let userId: UUID
    let body: String

    enum CodingKeys: String, CodingKey {
        case body
        case channelId = "channel_id"
        case userId = "user_id"
    }
}

private struct InsertTask: Encodable {
    let workspaceId: UUID
    let spaceId: UUID?
    let title: String
    let createdBy: UUID

    enum CodingKeys: String, CodingKey {
        case title
        case workspaceId = "workspace_id"
        case spaceId = "space_id"
        case createdBy = "created_by"
    }
}

private struct InsertChannel: Encodable {
    let workspaceId: UUID
    let name: String
    let createdBy: UUID
    let kind: String = "public"

    enum CodingKeys: String, CodingKey {
        case name, kind
        case workspaceId = "workspace_id"
        case createdBy = "created_by"
    }
}

private struct InsertSpace: Encodable {
    let workspaceId: UUID
    let name: String
    let parentId: UUID?

    enum CodingKeys: String, CodingKey {
        case name
        case workspaceId = "workspace_id"
        case parentId = "parent_id"
    }
}
