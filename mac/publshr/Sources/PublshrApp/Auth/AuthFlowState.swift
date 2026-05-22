import Foundation

enum AuthFlowState: Equatable {
    case bootstrapping
    case signedOut
    case confirmEmail
    case selectWorkspace
    case signedIn
}
