import Foundation

/// Local JWT expiry checks — no network required (offline unlock / cache decisions).
enum AuthJWT {
    private static let leewaySeconds: TimeInterval = 90

    static func isAccessTokenExpired(_ accessToken: String) -> Bool {
        guard let exp = expirationDate(accessToken) else { return true }
        return Date().addingTimeInterval(leewaySeconds) >= exp
    }

    static func expirationDate(_ jwt: String) -> Date? {
        let parts = jwt.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        var payload = String(parts[1])
        let remainder = payload.count % 4
        if remainder > 0 { payload += String(repeating: "=", count: 4 - remainder) }
        guard let data = Data(base64Encoded: payload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = json["exp"] as? TimeInterval else {
            return nil
        }
        return Date(timeIntervalSince1970: exp)
    }
}
