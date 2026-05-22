import Foundation

/// First-run enterprise setup after install (privacy, device, workspace).
enum EnterpriseInstallState {
    private static let completedKey = "com.publshr.enterprise.setup.completed"

    static var needsEnterpriseSetup: Bool {
        !UserDefaults.standard.bool(forKey: completedKey) || !PrivacyConsentStore.hasAcceptedPrivacyPolicy
    }

    static func markCompleted() {
        UserDefaults.standard.set(true, forKey: completedKey)
    }

    static func resetForTesting() {
        UserDefaults.standard.removeObject(forKey: completedKey)
        PrivacyConsentStore.reset()
    }
}
