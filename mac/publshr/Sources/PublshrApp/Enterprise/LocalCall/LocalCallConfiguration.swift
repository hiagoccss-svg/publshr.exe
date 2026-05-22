import Foundation

/// Local-only voice/video — embedded SFU on LAN, no cloud media APIs.
enum LocalCallConfiguration {
    /// SFU supports up to 20 simultaneous publishers/subscribers on a typical LAN.
    static let maxParticipants = 20

    static let bonjourType = "_publshr-call._tcp."
    static let bonjourDomain = "local."

    /// Default ports when the host starts the embedded LiveKit server.
    static let liveKitHTTPPort: UInt16 = 7880
    static let signalingPort: UInt16 = 8765

    /// Dev keys used by `livekit-server --dev` (self-hosted, not LiveKit Cloud).
    static let liveKitAPIKey = "devkey"
    static let liveKitAPISecret = "secret"

    static var bundledLiveKitServerNames: [String] {
        ["livekit-server", "livekit-server-macos"]
    }
}
