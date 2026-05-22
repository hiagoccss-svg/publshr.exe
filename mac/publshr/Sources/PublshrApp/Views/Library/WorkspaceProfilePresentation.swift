import Foundation

/// Opens the workspace profile sheet for the signed-in user or a teammate.
enum WorkspaceProfilePresentation: Identifiable, Equatable {
    case currentUser
    case member(UUID)

    var id: String {
        switch self {
        case .currentUser:
            return "me"
        case .member(let userId):
            return userId.uuidString
        }
    }
}
