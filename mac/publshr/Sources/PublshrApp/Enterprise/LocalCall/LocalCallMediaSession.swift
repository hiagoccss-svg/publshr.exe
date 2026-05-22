import Foundation
import LiveKit

/// Connects to the embedded local LiveKit SFU (no cloud).
@MainActor
final class LocalCallMediaSession: ObservableObject {
    @Published private(set) var isConnected = false
    @Published private(set) var connectionError: String?

    private var room: Room?

    func connect(wsURL: URL, token: String, enableVideo: Bool) async {
        disconnect()
        let room = Room()
        self.room = room
        do {
            try await room.connect(url: wsURL.absoluteString, token: token)
            try await room.localParticipant.setMicrophone(enabled: true)
            try await room.localParticipant.setCamera(enabled: enableVideo)
            isConnected = true
            connectionError = nil
        } catch {
            connectionError = error.localizedDescription
            isConnected = false
        }
    }

    func setMuted(_ muted: Bool) async {
        try? await room?.localParticipant.setMicrophone(enabled: !muted)
    }

    func setVideoEnabled(_ enabled: Bool) async {
        try? await room?.localParticipant.setCamera(enabled: enabled)
    }

    func disconnect() {
        Task {
            await room?.disconnect()
        }
        room = nil
        isConnected = false
    }
}
