import Foundation
import LiveKit

/// One tile in the call window grid (local or remote camera).
struct CallVideoTile: Identifiable, Equatable {
    let id: String
    let userId: UUID?
    let displayName: String
    let isLocal: Bool
    let isCameraEnabled: Bool
    let videoTrack: VideoTrack?

    static func == (lhs: CallVideoTile, rhs: CallVideoTile) -> Bool {
        lhs.id == rhs.id
            && lhs.userId == rhs.userId
            && lhs.displayName == rhs.displayName
            && lhs.isLocal == rhs.isLocal
            && lhs.isCameraEnabled == rhs.isCameraEnabled
    }
}
