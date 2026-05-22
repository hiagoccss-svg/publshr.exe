import Foundation
import LocalAuthentication

enum BiometricAuthService {
    /// Hardware supports Touch ID / Face ID (may still need a password fallback on Mac).
    static var isAvailable: Bool {
        var error: NSError?
        let context = LAContext()
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return true
        }
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    static var biometricLabel: String {
        let context = LAContext()
        switch context.biometryType {
        case .touchID: return "Touch ID"
        case .faceID: return "Face ID"
        case .opticID: return "Optic ID"
        default: return "Device password"
        }
    }

    /// Quick unlock — biometrics when possible, otherwise Mac login password (single prompt).
    static func authenticate(reason: String = "Unlock Publshr") async -> Bool {
        await withCheckedContinuation { continuation in
            let context = LAContext()
            context.localizedCancelTitle = "Cancel"
            context.localizedFallbackTitle = "Use password"
            var error: NSError?
            let policy: LAPolicy
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                policy = .deviceOwnerAuthenticationWithBiometrics
            } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                policy = .deviceOwnerAuthentication
            } else {
                continuation.resume(returning: false)
                return
            }
            context.evaluatePolicy(policy, localizedReason: reason) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}
