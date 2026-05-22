import Foundation

enum SupabaseConfig {
    static let url = URL(string: "https://lboesdtsrqfvosznjpdy.supabase.co")!
    static let publishableKey = "sb_publishable_mHARlRkK4iHkkn9wn_-uAw_EkW-jRXP"
    static let authRedirect = URL(string: "com.publshr.app://auth/callback")!

    static var displayHost: String {
        url.host ?? "supabase.co"
    }

    static var publishableKeySuffix: String {
        let key = publishableKey
        guard key.count > 8 else { return "••••" }
        return "…" + key.suffix(8)
    }
}
