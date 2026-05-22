import Foundation
import Supabase

/// Supabase-backed chat sync, send, and realtime subscriptions.
@MainActor
final class ChatService {
    let client: SupabaseClient
    let store: ChatLocalStore
    private var realtimeTask: Task<Void, Never>?
    private var messageUpdateTask: Task<Void, Never>?
    private let jsonDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    init(client: SupabaseClient, store: ChatLocalStore = ChatLocalStore()) {
        self.client = client
        self.store = store
    }

    func stopRealtime() {
        realtimeTask?.cancel()
        realtimeTask = nil
        messageUpdateTask?.cancel()
        messageUpdateTask = nil
    }

    func updateWorkspaceSettings(workspaceId: UUID, settings: [String: JSONValue]) async throws {
        struct Patch: Encodable {
            let settings: [String: JSONValue]
        }
        try await client
            .from("workspaces")
            .update(Patch(settings: settings))
            .eq("id", value: workspaceId.uuidString)
            .execute()
    }

    // MARK: - Workspace

    func fetchWorkspaces() async throws -> [Workspace] {
        let rows: [Workspace] = try await client
            .from("workspaces")
            .select()
            .order("created_at")
            .execute()
            .value
        return rows
    }

    func fetchMemberWorkspaces(userId: UUID) async throws -> [Workspace] {
        let members: [WorkspaceMember] = try await client
            .from("workspace_members")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        guard !members.isEmpty else { return [] }
        let ids = members.map(\.workspaceId.uuidString)
        let rows: [Workspace] = try await client
            .from("workspaces")
            .select()
            .in("id", values: ids)
            .execute()
            .value
        return rows
    }

    func createWorkspace(name: String) async throws -> Workspace {
        struct Params: Encodable { let p_name: String }
        let ws: Workspace = try await client
            .rpc("create_workspace", params: Params(p_name: name))
            .execute()
            .value
        return ws
    }

    // MARK: - Channels

    func fetchChannels(workspaceId: UUID) async throws -> [ChatChannel] {
        let rows: [ChatChannel] = try await client
            .from("chat_channels")
            .select()
            .eq("workspace_id", value: workspaceId.uuidString)
            .eq("is_archived", value: false)
            .order("last_message_at", ascending: false)
            .execute()
            .value
        store.cacheChannels(rows)
        return rows
    }

    func createChannel(
        workspaceId: UUID,
        name: String,
        kind: ChatChannelKind = .channel,
        visibility: ChatChannelVisibility = .public,
        description: String? = nil,
        createdBy: UUID
    ) async throws -> ChatChannel {
        struct Insert: Encodable {
            let workspace_id: UUID
            let name: String
            let description: String?
            let kind: String
            let visibility: String
            let created_by: UUID
        }
        let row: ChatChannel = try await client
            .from("chat_channels")
            .insert(Insert(
                workspace_id: workspaceId,
                name: name,
                description: description,
                kind: kind.rawValue,
                visibility: visibility.rawValue,
                created_by: createdBy
            ))
            .select()
            .single()
            .execute()
            .value
        store.cacheChannels([row])
        return row
    }

    func createDM(
        workspaceId: UUID,
        currentUserId: UUID,
        otherUserId: UUID,
        otherDisplayName: String
    ) async throws -> ChatChannel {
        let slug = [currentUserId, otherUserId].map(\.uuidString).sorted().joined(separator: ":")
        let existing: [ChatChannel] = try await client
            .from("chat_channels")
            .select()
            .eq("workspace_id", value: workspaceId.uuidString)
            .eq("kind", value: ChatChannelKind.dm.rawValue)
            .eq("name", value: "dm:\(slug)")
            .limit(1)
            .execute()
            .value
        if let channel = existing.first { return channel }

        let channel = try await createChannel(
            workspaceId: workspaceId,
            name: "dm:\(slug)",
            kind: .dm,
            visibility: .private,
            description: "Direct message with \(otherDisplayName)",
            createdBy: currentUserId
        )
        try await addChannelMember(workspaceId: workspaceId, channelId: channel.id, userId: currentUserId)
        try await addChannelMember(workspaceId: workspaceId, channelId: channel.id, userId: otherUserId)
        return channel
    }

    func addChannelMember(workspaceId: UUID, channelId: UUID, userId: UUID) async throws {
        struct Insert: Encodable {
            let workspace_id: UUID
            let channel_id: UUID
            let user_id: UUID
        }
        _ = try await client
            .from("chat_channel_members")
            .insert(Insert(workspace_id: workspaceId, channel_id: channelId, user_id: userId))
            .execute()
    }

    // MARK: - Messages

    func fetchMessages(channelId: UUID, workspaceId: UUID, limit: Int = 100) async throws -> [ChatMessage] {
        let rows: [ChatMessage] = try await client
            .from("chat_messages")
            .select()
            .eq("channel_id", value: channelId.uuidString)
            .eq("workspace_id", value: workspaceId.uuidString)
            .eq("is_deleted", value: false)
            .order("created_at", ascending: true)
            .limit(limit)
            .execute()
            .value
        store.cacheMessages(rows, channelId: channelId)
        return rows
    }

    func sendMessage(
        workspaceId: UUID,
        channelId: UUID,
        userId: UUID,
        body: String,
        threadParentId: UUID? = nil
    ) async throws -> ChatMessage {
        struct Insert: Encodable {
            let workspace_id: UUID
            let channel_id: UUID
            let user_id: UUID
            let body: String
            let thread_parent_id: UUID?
        }
        let row: ChatMessage = try await client
            .from("chat_messages")
            .insert(Insert(
                workspace_id: workspaceId,
                channel_id: channelId,
                user_id: userId,
                body: body,
                thread_parent_id: threadParentId
            ))
            .select()
            .single()
            .execute()
            .value
        store.upsertMessage(row)
        return row
    }

    func seedDefaultChannels(workspaceId: UUID, userId: UUID) async throws {
        let existing = try await fetchChannels(workspaceId: workspaceId)
        guard existing.isEmpty else { return }
        let defaults: [(String, ChatChannelVisibility)] = [
            ("editorial", .public),
            ("approvals", .internal),
            ("campaign-launch", .public),
        ]
        for (name, vis) in defaults {
            _ = try await createChannel(
                workspaceId: workspaceId,
                name: name,
                visibility: vis,
                createdBy: userId
            )
        }
    }

    // MARK: - Presence

    func fetchPresence(workspaceId: UUID) async throws -> [ChatPresence] {
        let rows: [ChatPresence] = try await client
            .from("chat_presence")
            .select()
            .eq("workspace_id", value: workspaceId.uuidString)
            .execute()
            .value
        store.cachePresence(rows)
        return rows
    }

    func upsertPresence(workspaceId: UUID, userId: UUID, status: ChatPresenceStatus, activity: String? = nil) async throws {
        struct Upsert: Encodable {
            let workspace_id: UUID
            let user_id: UUID
            let status: String
            let activity: String?
            let last_seen_at: Date
        }
        let row: ChatPresence = try await client
            .from("chat_presence")
            .upsert(Upsert(
                workspace_id: workspaceId,
                user_id: userId,
                status: status.rawValue,
                activity: activity,
                last_seen_at: Date()
            ))
            .select()
            .single()
            .execute()
            .value
        store.cachePresence([row])
    }

    // MARK: - Profiles

    func fetchWorkspaceProfiles(workspaceId: UUID) async throws -> [Profile] {
        let members: [WorkspaceMember] = try await client
            .from("workspace_members")
            .select()
            .eq("workspace_id", value: workspaceId.uuidString)
            .execute()
            .value
        let ids = members.map(\.userId.uuidString)
        guard !ids.isEmpty else { return [] }
        let profiles: [Profile] = try await client
            .from("profiles")
            .select()
            .in("id", values: ids)
            .execute()
            .value
        return profiles
    }

    // MARK: - Realtime

    func subscribeMessages(
        workspaceId: UUID,
        onInsert: @escaping @Sendable (ChatMessage) -> Void
    ) {
        realtimeTask?.cancel()
        realtimeTask = Task {
            let channel = await client.channel("chat-messages-\(workspaceId.uuidString)")
            let stream = await channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "chat_messages",
                filter: "workspace_id=eq.\(workspaceId.uuidString)"
            )
            await channel.subscribe()
            for await action in stream {
                guard let record = try? action.decodeRecord(as: ChatMessage.self, decoder: self.jsonDecoder) else { continue }
                store.upsertMessage(record)
                onInsert(record)
            }
        }
    }

    func subscribeMessageUpdates(
        workspaceId: UUID,
        onUpdate: @escaping @Sendable (ChatMessage) -> Void,
        onDelete: @escaping @Sendable (UUID) -> Void
    ) {
        messageUpdateTask?.cancel()
        messageUpdateTask = Task {
            let channel = await client.channel("chat-msg-updates-\(workspaceId.uuidString)")
            let updates = await channel.postgresChange(
                UpdateAction.self,
                schema: "public",
                table: "chat_messages",
                filter: "workspace_id=eq.\(workspaceId.uuidString)"
            )
            let deletes = await channel.postgresChange(
                DeleteAction.self,
                schema: "public",
                table: "chat_messages",
                filter: "workspace_id=eq.\(workspaceId.uuidString)"
            )
            await channel.subscribe()
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    for await action in updates {
                        guard let record = try? action.decodeRecord(as: ChatMessage.self, decoder: self.jsonDecoder) else { continue }
                        self.store.upsertMessage(record)
                        if record.isDeleted {
                            onDelete(record.id)
                        } else {
                            onUpdate(record)
                        }
                    }
                }
                group.addTask {
                    for await action in deletes {
                        guard let id = try? action.decodeOldRecord(as: ChatMessage.self, decoder: self.jsonDecoder)?.id else { continue }
                        onDelete(id)
                    }
                }
            }
        }
    }

    func subscribePresence(
        workspaceId: UUID,
        onChange: @escaping @Sendable (ChatPresence) -> Void
    ) {
        Task {
            let channel = await client.channel("chat-presence-\(workspaceId.uuidString)")
            let inserts = await channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "chat_presence",
                filter: "workspace_id=eq.\(workspaceId.uuidString)"
            )
            let updates = await channel.postgresChange(
                UpdateAction.self,
                schema: "public",
                table: "chat_presence",
                filter: "workspace_id=eq.\(workspaceId.uuidString)"
            )
            await channel.subscribe()
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    for await action in inserts {
                        guard let record = try? action.decodeRecord(as: ChatPresence.self, decoder: self.jsonDecoder) else { continue }
                        onChange(record)
                    }
                }
                group.addTask {
                    for await action in updates {
                        guard let record = try? action.decodeRecord(as: ChatPresence.self, decoder: self.jsonDecoder) else { continue }
                        onChange(record)
                    }
                }
            }
        }
    }

    func cachedChannels(workspaceId: UUID) -> [ChatChannel] {
        store.loadChannels(workspaceId: workspaceId)
    }

    func cachedMessages(channelId: UUID) -> [ChatMessage] {
        store.loadMessages(channelId: channelId)
    }

    func localStore() -> ChatLocalStore { store }
}

enum ChatServiceError: LocalizedError {
    case workspaceCreateFailed
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .workspaceCreateFailed: "Could not create workspace."
        case .notAuthenticated: "Sign in to use chat."
        }
    }
}
