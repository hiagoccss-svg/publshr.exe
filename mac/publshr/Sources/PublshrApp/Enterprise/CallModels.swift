import Foundation

enum CallScope: String, Codable, CaseIterable {
    case `private` = "private"
    case meeting = "meeting"

    var label: String {
        switch self {
        case .private: return "Private"
        case .meeting: return "Meeting"
        }
    }

    var icon: String {
        switch self {
        case .private: return "person.2.fill"
        case .meeting: return "person.3.fill"
        }
    }
}

/// Active call on a channel (for join badge).
struct LiveCallSummary: Equatable, Identifiable {
    var id: UUID { roomId }
    let roomId: UUID
    let channelId: UUID
    let title: String
    let kind: String
    let scope: CallScope
    let participantCount: Int
    let createdBy: UUID
    let livekitRoom: String?

    var isVideo: Bool { kind == "video" }
}

struct IncomingCallInvite: Identifiable, Equatable {
    let id: UUID
    let room: CallSignalingService.CallRoomRecord
    let callerId: UUID
    let callerName: String
    let scope: CallScope
    let startedAt: Date

    var isVideo: Bool { room.kind == "video" }
    var channelTitle: String { room.title }
}
