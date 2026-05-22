import Foundation
import Supabase

/// GDPR-style consent + policy links — required before full enterprise access.
enum PrivacyConsentStore {
    private static let acceptedKey = "com.publshr.privacy.accepted.v1"
    private static let acceptedAtKey = "com.publshr.privacy.acceptedAt"

    static let privacyPolicyURL = URL(string: "https://publshr.com/privacy")!
    static let termsURL = URL(string: "https://publshr.com/terms")!

    static var hasAcceptedPrivacyPolicy: Bool {
        UserDefaults.standard.bool(forKey: acceptedKey)
    }

    static var acceptedAt: Date? {
        let t = UserDefaults.standard.double(forKey: acceptedAtKey)
        return t > 0 ? Date(timeIntervalSince1970: t) : nil
    }

    static func accept() {
        UserDefaults.standard.set(true, forKey: acceptedKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: acceptedAtKey)
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: acceptedKey)
        UserDefaults.standard.removeObject(forKey: acceptedAtKey)
    }

    @MainActor
    static func logAcceptance(client: SupabaseClient, userId: UUID, workspaceId: UUID?) async {
        struct Insert: Encodable {
            let user_id: UUID
            let workspace_id: UUID?
            let event_type: String
            let detail: String
        }
        try? await client
            .from("privacy_audit_events")
            .insert(Insert(
                user_id: userId,
                workspace_id: workspaceId,
                event_type: "privacy_policy_accepted",
                detail: "macOS app v\(DeviceIdentityService.current.appVersion)"
            ))
            .execute()
    }
}
