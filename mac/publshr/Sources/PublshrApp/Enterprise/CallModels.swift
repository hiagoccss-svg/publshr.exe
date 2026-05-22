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
