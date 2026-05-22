import Foundation
import LiveKit

/// Connects to the embedded local LiveKit SFU and publishes video tile state.
@MainActor
final class LocalCallMediaSession: ObservableObject {
    @Published private(set) var isConnected = false
    @Published private(set) var connectionError: String?
    @Published private(set) var videoTiles: [CallVideoTile] = []

    private var room: Room?
    private var delegateBridge: MediaRoomDelegate?
    private var localUserId: UUID?
    private var localDisplayName = "You"

    func connect(
        wsURL: URL,
        token: String,
        enableVideo: Bool,
        localUserId: UUID,
        localDisplayName: String
    ) async {
        disconnect()
        self.localUserId = localUserId
        self.localDisplayName = localDisplayName

        let bridge = MediaRoomDelegate { [weak self] in
            DispatchQueue.main.async { [weak self] in
                self?.rebuildVideoTiles()
            }
        }
        delegateBridge = bridge

        let room = Room(delegate: bridge)
        self.room = room
        do {
            try await room.connect(url: wsURL.absoluteString, token: token)
            try await room.localParticipant.setMicrophone(enabled: true)
            try await room.localParticipant.setCamera(enabled: enableVideo)
            isConnected = true
            connectionError = nil
            rebuildVideoTiles()
        } catch {
            connectionError = error.localizedDescription
            isConnected = false
            videoTiles = []
        }
    }

    func setMuted(_ muted: Bool) async {
        try? await room?.localParticipant.setMicrophone(enabled: !muted)
    }

    func setVideoEnabled(_ enabled: Bool) async {
        try? await room?.localParticipant.setCamera(enabled: enabled)
        rebuildVideoTiles()
    }

    func disconnect() {
        Task {
            await room?.disconnect()
        }
        room = nil
        delegateBridge = nil
        isConnected = false
        videoTiles = []
    }

    private func rebuildVideoTiles() {
        guard let room else {
            videoTiles = []
            return
        }

        var tiles: [CallVideoTile] = []

        let localTrack = cameraVideoTrack(for: room.localParticipant)
        let localCam = room.localParticipant.isCameraEnabled()
        tiles.append(
            CallVideoTile(
                id: "local",
                userId: localUserId,
                displayName: localDisplayName,
                isLocal: true,
                isCameraEnabled: localCam,
                videoTrack: localTrack
            )
        )

        for remote in room.remoteParticipants.values.sorted(by: { ($0.identity?.stringValue ?? "") < ($1.identity?.stringValue ?? "") }) {
            let identity = remote.identity?.stringValue ?? remote.sid?.stringValue ?? UUID().uuidString
            let userId = UUID(uuidString: identity)
            let track = cameraVideoTrack(for: remote)
            let camOn = remote.isCameraEnabled()
            tiles.append(
                CallVideoTile(
                    id: identity,
                    userId: userId,
                    displayName: userId == localUserId ? localDisplayName : identity.prefix(8).description,
                    isLocal: false,
                    isCameraEnabled: camOn,
                    videoTrack: track
                )
            )
        }

        videoTiles = tiles
    }

    private func cameraVideoTrack(for participant: Participant) -> VideoTrack? {
        for publication in participant.trackPublications.values {
            guard publication.source == .camera,
                  !publication.isMuted,
                  let track = publication.track as? VideoTrack else { continue }
            return track
        }
        return nil
    }
}

// MARK: - Room delegate

private final class MediaRoomDelegate: RoomDelegate, @unchecked Sendable {
    private let onChange: @Sendable () -> Void

    init(onChange: @escaping @Sendable () -> Void) {
        self.onChange = onChange
    }

    func room(_ room: Room, participant: RemoteParticipant, didSubscribeTrack publication: RemoteTrackPublication) {
        onChange()
    }

    func room(_ room: Room, participant: RemoteParticipant, didUnsubscribeTrack publication: RemoteTrackPublication) {
        onChange()
    }

    func room(_ room: Room, participant: Participant, didUpdateState state: ParticipantState) {
        onChange()
    }

    func room(_ room: Room, participant: LocalParticipant, didPublishTrack publication: LocalTrackPublication) {
        onChange()
    }
}
