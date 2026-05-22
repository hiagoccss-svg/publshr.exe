import Foundation
import Supabase
import AVFoundation

/// Workspace voice/video calls — Supabase signaling + native AV capture prep.
/// Configure `livekit_url` in workspace settings for full duplex media (LiveKit).
@MainActor
final class CallSignalingService: ObservableObject {
    @Published private(set) var activeRoom: CallRoomRecord?
    @Published private(set) var participants: [CallParticipantRow] = []
    @Published var isMuted = false
    @Published var isVideoEnabled = false
    @Published var errorMessage: String?
    @Published private(set) var mediaStatus = "Signaling only — add LiveKit URL in workspace settings for HD voice/video."

    private var client: SupabaseClient?
    private var realtimeTask: Task<Void, Never>?
    private var userId: UUID?

    struct CallRoomRecord: Codable, Identifiable, Equatable {
        let id: UUID
        let workspaceId: UUID
        let channelId: UUID?
        let title: String
        let kind: String
        let status: String
        let createdBy: UUID
        let livekitRoom: String?

        enum CodingKeys: String, CodingKey {
            case id
            case workspaceId = "workspace_id"
            case channelId = "channel_id"
            case title, kind, status
            case createdBy = "created_by"
            case livekitRoom = "livekit_room"
        }
    }

    struct CallParticipantRow: Codable, Identifiable, Equatable {
        let id: UUID
        let roomId: UUID
        let userId: UUID
        let joinedAt: Date
        let leftAt: Date?
        let isMuted: Bool
        let isVideoEnabled: Bool

        enum CodingKeys: String, CodingKey {
            case id
            case roomId = "room_id"
            case userId = "user_id"
            case joinedAt = "joined_at"
            case leftAt = "left_at"
            case isMuted = "is_muted"
            case isVideoEnabled = "is_video_enabled"
        }

        var isActive: Bool { leftAt == nil }
    }

    func attach(client: SupabaseClient, userId: UUID) {
        self.client = client
        self.userId = userId
    }

    func detach() {
        realtimeTask?.cancel()
        realtimeTask = nil
        activeRoom = nil
        participants = []
    }

    func startChannelCall(workspaceId: UUID, channelId: UUID, title: String, video: Bool, workspaceSettings: [String: JSONValue]? = nil) async {
        guard let client, let userId else { return }
        if let settings = workspaceSettings,
           case .string(let url) = settings["livekit_url"],
           !url.isEmpty {
            mediaStatus = "Connecting via LiveKit (\(url))…"
        } else {
            mediaStatus = "Signaling only — add LiveKit URL in workspace settings for HD voice/video."
        }
        await requestMediaPermissions(video: video)
        do {
            struct Insert: Encodable {
                let workspace_id: UUID
                let channel_id: UUID
                let title: String
                let kind: String
                let created_by: UUID
                let livekit_room: String
            }
            let room: CallRoomRecord = try await client
                .from("call_rooms")
                .insert(Insert(
                    workspace_id: workspaceId,
                    channel_id: channelId,
                    title: title,
                    kind: video ? "video" : "voice",
                    created_by: userId,
                    livekit_room: "publshr-\(channelId.uuidString.prefix(8))"
                ))
                .select()
                .single()
                .execute()
                .value
            activeRoom = room
            await joinRoom(room)
            subscribeParticipants(roomId: room.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func joinRoom(_ room: CallRoomRecord) async {
        guard let client, let userId else { return }
        activeRoom = room
        struct Upsert: Encodable {
            let room_id: UUID
            let user_id: UUID
            let is_muted: Bool
            let is_video_enabled: Bool
        }
        try? await client
            .from("call_participants")
            .upsert(Upsert(room_id: room.id, user_id: userId, is_muted: isMuted, is_video_enabled: isVideoEnabled), onConflict: "room_id,user_id")
            .execute()
        await reloadParticipants(roomId: room.id)
        subscribeParticipants(roomId: room.id)
    }

    func leaveCall() async {
        guard let client, let userId, let room = activeRoom else { return }
        struct Patch: Encodable {
            let left_at: String
        }
        let iso = ISO8601DateFormatter().string(from: Date())
        try? await client
            .from("call_participants")
            .update(Patch(left_at: iso))
            .eq("room_id", value: room.id.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
        realtimeTask?.cancel()
        activeRoom = nil
        participants = []
    }

    func endCall() async {
        guard let client, let room = activeRoom else { return }
        struct Patch: Encodable {
            let status: String
            let ended_at: String
        }
        let iso = ISO8601DateFormatter().string(from: Date())
        try? await client
            .from("call_rooms")
            .update(Patch(status: "ended", ended_at: iso))
            .eq("id", value: room.id.uuidString)
            .execute()
        await leaveCall()
    }

    private func reloadParticipants(roomId: UUID) async {
        guard let client else { return }
        do {
            participants = try await client
                .from("call_participants")
                .select()
                .eq("room_id", value: roomId.uuidString)
                .order("joined_at")
                .execute()
                .value
        } catch {
            participants = []
        }
    }

    private func subscribeParticipants(roomId: UUID) {
        guard let client else { return }
        realtimeTask?.cancel()
        realtimeTask = Task {
            let channel = await client.channel("call-\(roomId.uuidString)")
            let stream = await channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "call_participants",
                filter: "room_id=eq.\(roomId.uuidString)"
            )
            let updates = await channel.postgresChange(
                UpdateAction.self,
                schema: "public",
                table: "call_participants",
                filter: "room_id=eq.\(roomId.uuidString)"
            )
            await channel.subscribe()
            await withTaskGroup(of: Void.self) { group in
                group.addTask { [weak self] in
                    for await _ in stream {
                        await self?.reloadParticipants(roomId: roomId)
                    }
                }
                group.addTask { [weak self] in
                    for await _ in updates {
                        await self?.reloadParticipants(roomId: roomId)
                    }
                }
            }
        }
    }

    private func requestMediaPermissions(video: Bool) async {
        _ = await AVCaptureDevice.requestAccess(for: .audio)
        if video {
            _ = await AVCaptureDevice.requestAccess(for: .video)
        }
    }
}
