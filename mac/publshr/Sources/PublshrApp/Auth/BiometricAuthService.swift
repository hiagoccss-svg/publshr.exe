import Foundation
import LocalAuthentication

enum BiometricAuthService {
    static var isAvailable: Bool {
        var error: NSError?
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    static var biometricLabel: String {
        let context = LAContext()
        switch context.biometryType {
        case .touchID: return "Touch ID"
        case .faceID: return "Face ID"
        case .opticID: return "Optic ID"
        default: return "Biometrics"
        }
    }

    static func authenticate(reason: String = "Unlock Publshr") async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Use password"
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }
        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}
