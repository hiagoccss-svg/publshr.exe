import Foundation

public enum SupabaseConfig {
    public static var url: URL {
        if let env = ProcessInfo.processInfo.environment["PUBLSHR_SUPABASE_URL"],
           let u = URL(string: env) { return u }
        if let s = plistString("SupabaseURL"), let u = URL(string: s) { return u }
        return URL(string: "https://lboesdtsrqfvosznjpdy.supabase.co")!
    }

    public static var anonKey: String {
        if let env = ProcessInfo.processInfo.environment["PUBLSHR_SUPABASE_KEY"], !env.isEmpty {
            return env
        }
        if let s = plistString("SupabaseKey"), !s.isEmpty { return s }
        return ""
    }

    private static func plistString(_ key: String) -> String? {
        guard let url = Bundle.module.url(forResource: "SupabaseConfig", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let value = plist[key] as? String else { return nil }
        return value
    }
}
