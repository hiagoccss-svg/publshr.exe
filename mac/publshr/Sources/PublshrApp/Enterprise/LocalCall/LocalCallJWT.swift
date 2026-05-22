import CryptoKit
import Foundation

/// Generates LiveKit access tokens locally (HMAC-SHA256) — no token API.
enum LocalCallJWT {
    static func accessToken(
        apiKey: String,
        apiSecret: String,
        identity: String,
        roomName: String,
        ttlSeconds: Int = 86_400
    ) throws -> String {
        let now = Int(Date().timeIntervalSince1970)
        let header = base64URL(Data(#"{"alg":"HS256","typ":"JWT"}"#.utf8))
        let payloadJSON: [String: Any] = [
            "iss": apiKey,
            "sub": identity,
            "iat": now,
            "nbf": now,
            "exp": now + ttlSeconds,
            "video": [
                "roomJoin": true,
                "room": roomName,
                "canPublish": true,
                "canSubscribe": true,
            ] as [String: Any],
        ]
        let payloadData = try JSONSerialization.data(withJSONObject: payloadJSON)
        let payload = base64URL(payloadData)
        let signingInput = "\(header).\(payload)"
        let key = SymmetricKey(data: Data(apiSecret.utf8))
        let signature = HMAC<SHA256>.authenticationCode(for: Data(signingInput.utf8), using: key)
        return "\(signingInput).\(base64URL(Data(signature)))"
    }

    private static func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
