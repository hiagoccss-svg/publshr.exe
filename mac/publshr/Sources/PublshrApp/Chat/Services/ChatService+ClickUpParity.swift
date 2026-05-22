import Foundation
import Supabase

extension ChatService {
    func updateMemberLastRead(
        memberId: UUID,
        workspaceId: UUID,
        lastReadAt: Date?
    ) async throws {
        struct Patch: Encodable {
            let last_read_at: String?
        }
        let value = lastReadAt.map { ISO8601DateFormatter().string(from: $0) }
        _ = try await client
            .from("chat_channel_members")
            .update(Patch(last_read_at: value))
            .eq("id", value: memberId.uuidString)
            .eq("workspace_id", value: workspaceId.uuidString)
            .execute()
    }

    func assignMessage(
        workspaceId: UUID,
        messageId: UUID,
        assignedTo: UUID?
    ) async throws -> ChatMessage {
        struct Patch: Encodable {
            let assigned_to: UUID?
        }
        let row: ChatMessage = try await client
            .from("chat_messages")
            .update(Patch(assigned_to: assignedTo))
            .eq("id", value: messageId.uuidString)
            .eq("workspace_id", value: workspaceId.uuidString)
            .select()
            .single()
            .execute()
            .value
        store.upsertMessage(row)
        return row
    }

    func createScheduledMessage(
        workspaceId: UUID,
        channelId: UUID,
        userId: UUID,
        body: String,
        sendAt: Date,
        threadParentId: UUID? = nil
    ) async throws -> ChatScheduledMessage {
        struct Insert: Encodable {
            let workspace_id: UUID
            let channel_id: UUID
            let user_id: UUID
            let body: String
            let thread_parent_id: UUID?
            let send_at: String
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let row: ChatScheduledMessage = try await client
            .from("chat_scheduled_messages")
            .insert(Insert(
                workspace_id: workspaceId,
                channel_id: channelId,
                user_id: userId,
                body: body,
                thread_parent_id: threadParentId,
                send_at: formatter.string(from: sendAt)
            ))
            .select()
            .single()
            .execute()
            .value
        return row
    }

    func fetchPendingScheduled(
        workspaceId: UUID,
        userId: UUID
    ) async throws -> [ChatScheduledMessage] {
        let rows: [ChatScheduledMessage] = try await client
            .from("chat_scheduled_messages")
            .select()
            .eq("workspace_id", value: workspaceId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .eq("status", value: "pending")
            .order("send_at", ascending: true)
            .execute()
            .value
        return rows
    }

    func cancelScheduledMessage(id: UUID, workspaceId: UUID) async throws {
        struct Patch: Encodable { let status: String }
        _ = try await client
            .from("chat_scheduled_messages")
            .update(Patch(status: "cancelled"))
            .eq("id", value: id.uuidString)
            .eq("workspace_id", value: workspaceId.uuidString)
            .execute()
    }

    func markScheduledSent(id: UUID, workspaceId: UUID) async throws {
        struct Patch: Encodable { let status: String }
        _ = try await client
            .from("chat_scheduled_messages")
            .update(Patch(status: "sent"))
            .eq("id", value: id.uuidString)
            .eq("workspace_id", value: workspaceId.uuidString)
            .execute()
    }

    func fetchRecentSentMessages(
        workspaceId: UUID,
        userId: UUID,
        limit: Int = 40
    ) async throws -> [ChatMessage] {
        let rows: [ChatMessage] = try await client
            .from("chat_messages")
            .select()
            .eq("workspace_id", value: workspaceId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .eq("is_deleted", value: false)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        return rows
    }
}
