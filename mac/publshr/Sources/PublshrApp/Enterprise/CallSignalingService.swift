import Foundation
import Supabase
import AVFoundation

/// Workspace voice/video — **local-first**: embedded SFU + LAN signaling (up to 20 participants).
/// No cloud media APIs. Supabase is optional and only used for call discovery when online.
@MainActor
final class CallSignalingService: ObservableObject {
    @Published private(set) var activeRoom: CallRoomRecord?
    @Published private(set) var participants: [CallParticipantRow] = []
    @Published var isMuted = false
    @Published var isVideoEnabled = false
    @Published var errorMessage: String?
    @Published private(set) var mediaStatus = "Local call — starting embedded media server…"
    @Published private(set) var localRoomCode: String?
    @Published private(set) var localJoinHint: String?
    @Published var callScope: CallScope = .meeting
    @Published var incomingInvite: IncomingCallInvite?

    private var client: SupabaseClient?
    private var realtimeTask: Task<Void, Never>?
    private var hubSyncTask: Task<Void, Never>?
    private var incomingListenTask: Task<Void, Never>?
    private var userId: UUID?
    private var displayName = "Participant"
    private weak var chatPresenter: ChatViewModel?
    private weak var authPresenter: AuthViewModel?
    private let jsonDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private let liveKitServer = LocalLiveKitServer()
    private let signalingHub = LocalCallSignalingHub()
    private let mediaSession = LocalCallMediaSession()
    private var useCloudDiscovery = true

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

    func attach(client: SupabaseClient, userId: UUID, displayName: String? = nil, workspaceId: UUID? = nil) {
        self.client = client
        self.userId = userId
        if let displayName, !displayName.isEmpty {
            self.displayName = displayName
        }
        if let workspaceId {
            Task { await subscribeIncomingCalls(workspaceId: workspaceId) }
        }
    }

    func bindPresentation(chat: ChatViewModel, auth: AuthViewModel) {
        chatPresenter = chat
        authPresenter = auth
    }

    func detach() {
        Task { await tearDownLocalCall() }
        incomingListenTask?.cancel()
        incomingListenTask = nil
        realtimeTask?.cancel()
        realtimeTask = nil
        activeRoom = nil
        participants = []
        localRoomCode = nil
        localJoinHint = nil
        incomingInvite = nil
        CallWindowManager.shared.close()
        IncomingCallWindowManager.shared.close()
    }

    func startChannelCall(
        workspaceId: UUID,
        channelId: UUID,
        title: String,
        video: Bool,
        scope: CallScope = .meeting,
        workspaceSettings: [String: JSONValue]? = nil,
        userDisplayName: String? = nil
    ) async {
        guard let userId else { return }
        callScope = scope
        if let userDisplayName, !userDisplayName.isEmpty {
            displayName = userDisplayName
        }
        useCloudDiscovery = !isLocalOnly(settings: workspaceSettings)
        isVideoEnabled = video
        isMuted = false
        mediaStatus = "Starting local media server (no cloud APIs)…"
        errorMessage = nil

        await requestMediaPermissions(video: video)

        let roomId = UUID()
        let roomCode = String(channelId.uuidString.prefix(8)).lowercased()
        let livekitRoomName = "publshr-\(roomCode)"
        localRoomCode = roomCode

        activeRoom = CallRoomRecord(
            id: roomId,
            workspaceId: workspaceId,
            channelId: channelId,
            title: title,
            kind: video ? "video" : "voice",
            status: "active",
            createdBy: userId,
            livekitRoom: livekitRoomName
        )

        await liveKitServer.startIfNeeded()
        if let err = liveKitServer.lastError {
            mediaStatus = err
            errorMessage = err
        } else if liveKitServer.isRunning, let wsURL = liveKitServer.wsURL {
            mediaStatus = "Local SFU running — connecting…"
            await connectMedia(wsURL: wsURL, roomName: livekitRoomName, video: video)
        } else {
            mediaStatus = "Waiting for local SFU…"
        }

        do {
            try await signalingHub.startHosting(
                roomId: roomId,
                channelId: channelId,
                roomCode: roomCode,
                displayName: displayName,
                userId: userId
            )
            syncParticipantsFromHub(roomId: roomId)
            updateJoinHint()
            startHubParticipantSync(roomId: roomId)
        } catch {
            errorMessage = error.localizedDescription
        }

        if useCloudDiscovery {
            await publishRoomToCloud(
                workspaceId: workspaceId,
                channelId: channelId,
                title: title,
                video: video,
                userId: userId,
                livekitRoom: livekitRoomName,
                roomId: roomId
            )
        }

        signalingHub.updateLocalMediaState(isMuted: isMuted, isVideoEnabled: isVideoEnabled)
        presentCallWindow()
    }

    func acceptIncomingCall(chat: ChatViewModel, auth: AuthViewModel) async {
        guard let invite = incomingInvite else { return }
        incomingInvite = nil
        IncomingCallWindowManager.shared.close()
        callScope = invite.scope
        isVideoEnabled = invite.isVideo
        isMuted = false
        await joinRoom(invite.room)
        if let roomName = invite.room.livekitRoom,
           let wsURL = liveKitServer.wsURL ?? URL(string: "ws://\(LocalNetworkAddress.lanHostIPv4() ?? "127.0.0.1"):\(LocalCallConfiguration.liveKitHTTPPort)") {
            await connectMedia(wsURL: wsURL, roomName: roomName, video: invite.isVideo)
        }
        bindPresentation(chat: chat, auth: auth)
        presentCallWindow()
    }

    func declineIncomingCall() {
        incomingInvite = nil
        IncomingCallWindowManager.shared.close()
    }

    func presentIncomingRing(chat: ChatViewModel, auth: AuthViewModel) {
        guard let invite = incomingInvite else { return }
        bindPresentation(chat: chat, auth: auth)
        IncomingCallWindowManager.shared.present(invite: invite, calls: self, chat: chat, auth: auth)
    }

    private func presentCallWindow() {
        guard activeRoom != nil,
              let chat = chatPresenter,
              let auth = authPresenter else { return }
        CallWindowManager.shared.present(calls: self, chat: chat, auth: auth)
    }

    func joinDiscoveredLocalCall(channelId: UUID, roomId: UUID, title: String, video: Bool) async {
        guard let userId else { return }
        isVideoEnabled = video
        activeRoom = CallRoomRecord(
            id: roomId,
            workspaceId: UUID(),
            channelId: channelId,
            title: title,
            kind: video ? "video" : "voice",
            status: "active",
            createdBy: userId,
            livekitRoom: "publshr-\(String(channelId.uuidString.prefix(8)).lowercased()"
        )
        signalingHub.browseAndJoin(channelId: channelId, roomId: roomId, displayName: displayName, userId: userId)
        mediaStatus = "Joining call on your network…"
        if let wsURL = liveKitServer.wsURL ?? URL(string: "ws://\(LocalNetworkAddress.lanHostIPv4() ?? "127.0.0.1"):\(LocalCallConfiguration.liveKitHTTPPort)") {
            await connectMedia(wsURL: wsURL, roomName: activeRoom?.livekitRoom ?? "publshr-room", video: video)
        }
    }

    func joinRoom(_ room: CallRoomRecord) async {
        guard let userId else { return }
        activeRoom = room
        let roomCode = room.livekitRoom?.replacingOccurrences(of: "publshr-", with: "") ?? room.id.uuidString.prefix(8).description
        localRoomCode = roomCode
        if let channelId = room.channelId {
            signalingHub.browseAndJoin(channelId: channelId, roomId: room.id, displayName: displayName, userId: userId)
        }
        await reloadParticipants(roomId: room.id)
        subscribeParticipants(roomId: room.id)
        updateJoinHint()
    }

    func leaveCall() async {
        CallWindowManager.shared.close()
        await tearDownLocalCall()
        guard let client, let userId, let room = activeRoom, useCloudDiscovery else {
            activeRoom = nil
            participants = []
            localRoomCode = nil
            localJoinHint = nil
            return
        }
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
        localRoomCode = nil
        localJoinHint = nil
    }

    func endCall() async {
        if useCloudDiscovery, let client, let room = activeRoom {
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
        }
        await leaveCall()
    }

    func onMuteChanged() async {
        signalingHub.updateLocalMediaState(isMuted: isMuted, isVideoEnabled: isVideoEnabled)
        await mediaSession.setMuted(isMuted)
        guard let client, let userId, let room = activeRoom, useCloudDiscovery else { return }
        struct Patch: Encodable {
            let is_muted: Bool
            let is_video_enabled: Bool
        }
        try? await client
            .from("call_participants")
            .update(Patch(is_muted: isMuted, is_video_enabled: isVideoEnabled))
            .eq("room_id", value: room.id.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    private func connectMedia(wsURL: URL, roomName: String, video: Bool) async {
        guard let userId else { return }
        do {
            let token = try LocalCallJWT.accessToken(
                apiKey: LocalCallConfiguration.liveKitAPIKey,
                apiSecret: LocalCallConfiguration.liveKitAPISecret,
                identity: userId.uuidString,
                roomName: roomName
            )
            await mediaSession.connect(wsURL: wsURL, token: token, enableVideo: video)
            if mediaSession.isConnected {
                mediaStatus = "Connected — local voice/video (up to \(LocalCallConfiguration.maxParticipants) people)."
            } else {
                mediaStatus = mediaSession.connectionError ?? "Could not connect to local SFU."
            }
        } catch {
            mediaStatus = error.localizedDescription
        }
    }

    private func tearDownLocalCall() async {
        hubSyncTask?.cancel()
        hubSyncTask = nil
        await mediaSession.setMuted(true)
        mediaSession.disconnect()
        signalingHub.stop()
        if signalingHub.isHosting {
            liveKitServer.stop()
        }
    }

    private func startHubParticipantSync(roomId: UUID) {
        hubSyncTask?.cancel()
        hubSyncTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.syncParticipantsFromHub(roomId: roomId)
                try? await Task.sleep(nanoseconds: 400_000_000)
            }
        }
    }

    private func syncParticipantsFromHub(roomId: UUID) {
        participants = signalingHub.participants.map { p in
            CallParticipantRow(
                id: p.userId,
                roomId: roomId,
                userId: p.userId,
                joinedAt: p.joinedAt,
                leftAt: nil,
                isMuted: p.isMuted,
                isVideoEnabled: p.isVideoEnabled
            )
        }
    }

    private func updateJoinHint() {
        guard let code = localRoomCode else { return }
        if let host = signalingHub.hostAddress, let port = signalingHub.signalingPort {
            localJoinHint = "Others on your network: open this channel’s call or join LAN room \(code) at \(host):\(port)"
        } else {
            localJoinHint = "Room code: \(code) (same Wi‑Fi / LAN)"
        }
    }

    private func isLocalOnly(settings: [String: JSONValue]?) -> Bool {
        guard let settings, case .string(let mode) = settings["calls_mode"] else { return true }
        return mode != "cloud"
    }

    private func subscribeIncomingCalls(workspaceId: UUID) async {
        guard let client, let userId else { return }
        incomingListenTask?.cancel()
        incomingListenTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let channel = await client.channel("incoming-calls-\(userId.uuidString)")
            let stream = await channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "call_rooms",
                filter: "workspace_id=eq.\(workspaceId.uuidString)"
            )
            await channel.subscribe()
            for await action in stream {
                guard let record = try? action.decodeRecord(as: CallRoomRecord.self, decoder: jsonDecoder),
                      record.status == "active",
                      record.createdBy != userId,
                      activeRoom == nil else { continue }
                let scope: CallScope = record.title.localizedCaseInsensitiveContains("private") ? .private : .meeting
                await MainActor.run {
                    guard self.incomingInvite == nil else { return }
                    self.incomingInvite = IncomingCallInvite(
                        id: record.id,
                        room: record,
                        callerId: record.createdBy,
                        callerName: "Team member",
                        scope: scope,
                        startedAt: Date()
                    )
                }
            }
        }
    }

    private func publishRoomToCloud(
        workspaceId: UUID,
        channelId: UUID,
        title: String,
        video: Bool,
        userId: UUID,
        livekitRoom: String,
        roomId: UUID
    ) async {
        guard let client else { return }
        do {
            struct Insert: Encodable {
                let id: UUID
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
                    id: roomId,
                    workspace_id: workspaceId,
                    channel_id: channelId,
                    title: "\(title) · \(callScope.label)",
                    kind: video ? "video" : "voice",
                    created_by: userId,
                    livekit_room: livekitRoom
                ))
                .select()
                .single()
                .execute()
                .value
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
        } catch {
            // Local call still works without cloud discovery.
            NSLog("Cloud call discovery unavailable: \(error)")
        }
    }

    private func reloadParticipants(roomId: UUID) async {
        if !signalingHub.participants.isEmpty {
            syncParticipantsFromHub(roomId: roomId)
            return
        }
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
        guard let client, useCloudDiscovery else { return }
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
