import Foundation
import LocalAuthentication
import Security

enum BiometricGate {
    private static let service = "com.publshr.app.biometric"
    private static let account = "session_unlock"

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "publshr.biometric.enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "publshr.biometric.enabled") }
    }

    static var canUseBiometrics: Bool {
        var error: NSError?
        let ctx = LAContext()
        return ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    static func authenticate(reason: String = "Unlock Publshr") async -> Bool {
        guard isEnabled, canUseBiometrics else { return true }
        let ctx = LAContext()
        ctx.localizedCancelTitle = "Use Password"
        do {
            return try await ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
        } catch {
            return false
        }
    }
}
