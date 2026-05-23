import Foundation
import Security

/// Secure storage for session tokens. When biometrics are enabled, items require Touch ID / Face ID to read.
enum AuthKeychain {
    private static let service = "com.publshr.app.auth"
    private static let protectionVersionKey = "com.publshr.app.auth.protection.v1"

    struct StoredSession: Codable {
        let email: String
        let accessToken: String
        let refreshToken: String
        let userId: UUID
    }

    /// True when the stored item was saved with `SecAccessControl` biometry (system prompt on read).
    static var usesBiometricProtection: Bool {
        UserDefaults.standard.bool(forKey: protectionVersionKey)
    }

    static func hasStoredSession() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }

    static func save(_ session: StoredSession, requireBiometry: Bool) -> Bool {
        guard let data = try? JSONEncoder().encode(session) else { return false }
        delete()

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: session.email,
            kSecValueData as String: data,
        ]

        if requireBiometry {
            var error: Unmanaged<CFError>?
            guard let access = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .biometryCurrentSet,
                &error
            ) else {
                return false
            }
            query[kSecAttrAccessControl as String] = access
            UserDefaults.standard.set(true, forKey: protectionVersionKey)
        } else {
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            UserDefaults.standard.set(false, forKey: protectionVersionKey)
        }

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func load() -> StoredSession? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let session = try? JSONDecoder().decode(StoredSession.self, from: data) else {
            return nil
        }
        return session
    }

    static func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]
        SecItemDelete(query as CFDictionary)
        UserDefaults.standard.removeObject(forKey: protectionVersionKey)
    }
}
