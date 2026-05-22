import Foundation
import Supabase

extension ChatService {
    // MARK: - Phase 2: Edit / delete

    func editMessage(messageId: UUID, workspaceId: UUID, body: String) async throws -> ChatMessage {
        struct Patch: Encodable {
            let body: String
            let is_edited: Bool = true
        }
        let row: ChatMessage = try await client
            .from("chat_messages")
            .update(Patch(body: body))
            .eq("id", value: messageId.uuidString)
            .eq("workspace_id", value: workspaceId.uuidString)
            .select()
            .single()
            .execute()
            .value
        store.upsertMessage(row)
        return row
    }

    func deleteMessage(messageId: UUID, workspaceId: UUID, soft: Bool = true) async throws {
        if soft {
            struct Patch: Encodable {
                let is_deleted: Bool = true
                let body: String? = nil
                let attachments: [ChatAttachment] = []
            }
            _ = try await client
                .from("chat_messages")
                .update(Patch())
                .eq("id", value: messageId.uuidString)
                .eq("workspace_id", value: workspaceId.uuidString)
                .execute()
        }
    }

    func fetchThreadReplies(parentId: UUID, workspaceId: UUID) async throws -> [ChatMessage] {
        let rows: [ChatMessage] = try await client
            .from("chat_messages")
            .select()
            .eq("thread_parent_id", value: parentId.uuidString)
            .eq("workspace_id", value: workspaceId.uuidString)
            .eq("is_deleted", value: false)
            .order("created_at", ascending: true)
            .execute()
            .value
        return rows
    }

    func sendMessageExtended(
        workspaceId: UUID,
        channelId: UUID,
        userId: UUID,
        body: String?,
        threadParentId: UUID? = nil,
        attachments: [ChatAttachment] = []
    ) async throws -> ChatMessage {
        struct Insert: Encodable {
            let workspace_id: UUID
            let channel_id: UUID
            let user_id: UUID
            let body: String?
            let thread_parent_id: UUID?
            let attachments: [ChatAttachment]
        }
        let row: ChatMessage = try await client
            .from("chat_messages")
            .insert(Insert(
                workspace_id: workspaceId,
                channel_id: channelId,
                user_id: userId,
                body: body,
                thread_parent_id: threadParentId,
                attachments: attachments
            ))
            .select()
            .single()
            .execute()
            .value
        store.upsertMessage(row)
        return row
    }

    // MARK: - Reactions

    func fetchReactions(workspaceId: UUID, messageIds: [UUID]) async throws -> [ChatReaction] {
        guard !messageIds.isEmpty else { return [] }
        let rows: [ChatReaction] = try await client
            .from("chat_reactions")
            .select()
            .eq("workspace_id", value: workspaceId.uuidString)
            .in("message_id", values: messageIds.map(\.uuidString))
            .execute()
            .value
        return rows
    }

    func toggleReaction(workspaceId: UUID, messageId: UUID, userId: UUID, emoji: String) async throws -> Bool {
        let existing: [ChatReaction] = try await client
            .from("chat_reactions")
            .select()
            .eq("message_id", value: messageId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .eq("emoji", value: emoji)
            .limit(1)
            .execute()
            .value
        if existing.first != nil {
            _ = try await client
                .from("chat_reactions")
                .delete()
                .eq("message_id", value: messageId.uuidString)
                .eq("user_id", value: userId.uuidString)
                .eq("emoji", value: emoji)
                .execute()
            return false
        }
        struct Insert: Encodable {
            let workspace_id: UUID
            let message_id: UUID
            let user_id: UUID
            let emoji: String
        }
        _ = try await client
            .from("chat_reactions")
            .insert(Insert(workspace_id: workspaceId, message_id: messageId, user_id: userId, emoji: emoji))
            .execute()
        return true
    }

    // MARK: - Pins

    func fetchPinned(channelId: UUID, workspaceId: UUID) async throws -> [ChatPinnedItem] {
        try await client
            .from("chat_pinned_items")
            .select()
            .eq("channel_id", value: channelId.uuidString)
            .eq("workspace_id", value: workspaceId.uuidString)
            .order("sort_order")
            .execute()
            .value
    }

    func pinMessage(workspaceId: UUID, channelId: UUID, messageId: UUID, userId: UUID) async throws -> ChatPinnedItem {
        struct Insert: Encodable {
            let workspace_id: UUID
            let channel_id: UUID
            let message_id: UUID
            let pinned_by: UUID
        }
        return try await client
            .from("chat_pinned_items")
            .insert(Insert(workspace_id: workspaceId, channel_id: channelId, message_id: messageId, pinned_by: userId))
            .select()
            .single()
            .execute()
            .value
    }

    func unpinItem(itemId: UUID) async throws {
        _ = try await client.from("chat_pinned_items").delete().eq("id", value: itemId.uuidString).execute()
    }

    // MARK: - Read receipts

    func markSeen(workspaceId: UUID, messageId: UUID, userId: UUID) async throws {
        struct Insert: Encodable {
            let message_id: UUID
            let workspace_id: UUID
            let user_id: UUID
            let seen_at: Date
        }
        _ = try await client
            .from("chat_read_receipts")
            .upsert(Insert(message_id: messageId, workspace_id: workspaceId, user_id: userId, seen_at: Date()))
            .execute()
    }

    func fetchReceipts(messageId: UUID) async throws -> [ChatReadReceipt] {
        try await client
            .from("chat_read_receipts")
            .select()
            .eq("message_id", value: messageId.uuidString)
            .execute()
            .value
    }

    // MARK: - Message links

    func attachLink(
        workspaceId: UUID,
        messageId: UUID,
        linkType: ChatLinkType,
        linkId: UUID,
        preview: ChatLinkPreview
    ) async throws -> ChatMessageLink {
        struct Insert: Encodable {
            let workspace_id: UUID
            let message_id: UUID
            let link_type: String
            let link_id: UUID
            let preview: ChatLinkPreview
        }
        return try await client
            .from("chat_message_links")
            .insert(Insert(
                workspace_id: workspaceId,
                message_id: messageId,
                link_type: linkType.rawValue,
                link_id: linkId,
                preview: preview
            ))
            .select()
            .single()
            .execute()
            .value
    }

    func fetchLinks(messageIds: [UUID]) async throws -> [ChatMessageLink] {
        guard !messageIds.isEmpty else { return [] }
        return try await client
            .from("chat_message_links")
            .select()
            .in("message_id", values: messageIds.map(\.uuidString))
            .execute()
            .value
    }

    // MARK: - Files

    func uploadChatFile(
        workspaceId: UUID,
        userId: UUID,
        fileName: String,
        mimeType: String,
        data: Data
    ) async throws -> (fileRecord: ChatUploadedFile, publicURL: URL) {
        let path = "\(workspaceId.uuidString)/chat/\(UUID().uuidString)-\(fileName)"
        _ = try await client.storage
            .from("workspace-files")
            .upload(path, data: data, options: FileOptions(contentType: mimeType))

        struct FileInsert: Encodable {
            let workspace_id: UUID
            let uploaded_by: UUID
            let bucket: String
            let storage_path: String
            let file_name: String
            let mime_type: String
            let size_bytes: Int
        }
        struct FileRow: Decodable {
            let id: UUID
            let storage_path: String
        }
        let row: FileRow = try await client
            .from("files")
            .insert(FileInsert(
                workspace_id: workspaceId,
                uploaded_by: userId,
                bucket: "workspace-files",
                storage_path: path,
                file_name: fileName,
                mime_type: mimeType,
                size_bytes: data.count
            ))
            .select()
            .single()
            .execute()
            .value

        let signed = try await client.storage.from("workspace-files").createSignedURL(path: path, expiresIn: 3600)
        return (
            ChatUploadedFile(id: row.id, path: path, fileName: fileName, mimeType: mimeType, size: data.count),
            signed
        )
    }

    // MARK: - Voice

    func saveVoiceTranscript(
        workspaceId: UUID,
        messageId: UUID,
        storagePath: String,
        durationMs: Int,
        waveform: [Double]
    ) async throws -> ChatVoiceTranscript {
        struct Insert: Encodable {
            let workspace_id: UUID
            let message_id: UUID
            let storage_path: String
            let duration_ms: Int
            let waveform: [Double]
            let transcript_status: String
        }
        return try await client
            .from("chat_voice_transcripts")
            .insert(Insert(
                workspace_id: workspaceId,
                message_id: messageId,
                storage_path: storagePath,
                duration_ms: durationMs,
                waveform: waveform,
                transcript_status: ChatTranscriptStatus.pending.rawValue
            ))
            .select()
            .single()
            .execute()
            .value
    }

    func updateTranscript(id: UUID, transcript: String, status: ChatTranscriptStatus) async throws {
        struct Patch: Encodable {
            let transcript: String
            let transcript_status: String
        }
        _ = try await client
            .from("chat_voice_transcripts")
            .update(Patch(transcript: transcript, transcript_status: status.rawValue))
            .eq("id", value: id.uuidString)
            .execute()
    }

    func fetchVoiceTranscript(messageId: UUID) async throws -> ChatVoiceTranscript? {
        let rows: [ChatVoiceTranscript] = try await client
            .from("chat_voice_transcripts")
            .select()
            .eq("message_id", value: messageId.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    // MARK: - Planner

    func fetchTasks(workspaceId: UUID, limit: Int = 20) async throws -> [PlannerTask] {
        struct Row: Decodable {
            let id: UUID
            let workspace_id: UUID
            let title: String
            let status: String
            let due_date: String?
            let owner_id: UUID?
        }
        let rows: [Row] = try await client
            .from("planner_items")
            .select("id, workspace_id, title, status, due_date, owner_id")
            .eq("workspace_id", value: workspaceId.uuidString)
            .order("updated_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return rows.map { row in
            PlannerTask(
                id: row.id,
                workspaceId: row.workspace_id,
                title: row.title,
                status: row.status,
                dueDate: row.due_date.flatMap { formatter.date(from: $0) },
                assigneeId: row.owner_id
            )
        }
    }

    // MARK: - Search (remote + local)

    func searchWorkspace(workspaceId: UUID, query: String) async throws -> ChatRemoteSearchResult {
        struct Params: Encodable {
            let p_workspace_id: UUID
            let p_query: String
            let p_limit: Int
        }
        struct Raw: Decodable {
            let query: String?
            let messages: [ChatSearchMessageRow]?
            let tasks: [ChatSearchTaskRow]?
        }
        let raw: Raw = try await client
            .rpc("search_workspace", params: Params(p_workspace_id: workspaceId, p_query: query, p_limit: 25))
            .execute()
            .value
        return ChatRemoteSearchResult(
            messages: raw.messages ?? [],
            tasks: raw.tasks ?? []
        )
    }

    func subscribeReactions(workspaceId: UUID, onChange: @escaping @Sendable () -> Void) {
        Task {
            let channel = await client.channel("chat-reactions-\(workspaceId.uuidString)")
            let inserts = await channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "chat_reactions",
                filter: "workspace_id=eq.\(workspaceId.uuidString)"
            )
            let deletes = await channel.postgresChange(
                DeleteAction.self,
                schema: "public",
                table: "chat_reactions",
                filter: "workspace_id=eq.\(workspaceId.uuidString)"
            )
            await channel.subscribe()
            await withTaskGroup(of: Void.self) { group in
                group.addTask { for await _ in inserts { onChange() } }
                group.addTask { for await _ in deletes { onChange() } }
            }
        }
    }

    func fetchMainChannelMessages(channelId: UUID, workspaceId: UUID, limit: Int = 100) async throws -> [ChatMessage] {
        let all = try await fetchMessages(channelId: channelId, workspaceId: workspaceId, limit: limit + 50)
        let main = all.filter { $0.threadParentId == nil }
        store.cacheMessages(all, channelId: channelId)
        return main
    }
}

struct ChatUploadedFile: Equatable {
    let id: UUID
    let path: String
    let fileName: String
    let mimeType: String
    let size: Int
}

struct ChatRemoteSearchResult {
    let messages: [ChatSearchMessageRow]
    let tasks: [ChatSearchTaskRow]
}

struct ChatSearchMessageRow: Decodable {
    let id: UUID
    let channel_id: UUID
    let body: String?
    let channel_name: String?
}

struct ChatSearchTaskRow: Decodable {
    let id: UUID
    let title: String
    let status: String?
}
