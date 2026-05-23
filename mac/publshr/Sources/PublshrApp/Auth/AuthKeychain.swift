import Foundation
import Security

/// Secure storage for session tokens. When biometrics are enabled, items require Touch ID / Face ID (or device password) to read.
enum AuthKeychain {
    private static let service = "com.publshr.app.auth"
    private static let protectionVersionKey = "com.publshr.app.auth.protection.v1"

    struct StoredSession: Codable {
        let email: String
        let accessToken: String
        let refreshToken: String
        let userId: UUID
    }

    enum LoadResult {
        case success(StoredSession)
        case notFound
        case userCancelled
        case failed
    }

    /// True when the stored item was saved with `SecAccessControl` (system prompt on read).
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

    /// Prefer biometric access control; fall back to user presence (login password) on Macs without enrolled biometrics.
    private static func makeProtectedAccessControl() -> SecAccessControl? {
        var error: Unmanaged<CFError>?
        let flagSets: [SecAccessControlCreateFlags] = [.biometryCurrentSet, .userPresence]
        for flags in flagSets {
            error = nil
            if let access = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                flags,
                &error
            ) {
                return access
            }
        }
        return nil
    }

    static func save(_ session: StoredSession, requireBiometry: Bool) -> Bool {
        guard let data = try? JSONEncoder().encode(session) else { return false }
        delete()

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: session.email,
            kSecValueData as String: data,
            kSecAttrSynchronizable as String: false,
        ]

        if requireBiometry {
            guard let access = makeProtectedAccessControl() else { return false }
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
        switch loadResult() {
        case .success(let session): return session
        default: return nil
        }
    }

    static func loadResult() -> LoadResult {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            guard let data = item as? Data,
                  let session = try? JSONDecoder().decode(StoredSession.self, from: data) else {
                return .failed
            }
            return .success(session)
        case errSecItemNotFound:
            return .notFound
        case errSecUserCanceled, errSecAuthFailed:
            return .userCancelled
        default:
            return .failed
        }
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
