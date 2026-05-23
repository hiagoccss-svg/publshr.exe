import Foundation

/// Tracks the two cloud dependencies the app actually needs: GitHub (app delivery) and Supabase (data).
/// Local Application Support is a performance cache only — not required for online operation.
@MainActor
final class CloudPlatformHealth: ObservableObject {
    static let shared = CloudPlatformHealth()

    @Published private(set) var isGitHubReachable = true
    @Published private(set) var isSupabaseReachable = true
    @Published private(set) var liveVersionLine: String?
    @Published private(set) var lastCheckedAt: Date?
    @Published private(set) var lastErrorLine: String?

    var isFullyOperational: Bool {
        isGitHubReachable && isSupabaseReachable
    }

    var summaryLine: String {
        let gh = isGitHubReachable ? "GitHub OK" : "GitHub unreachable"
        let sb = isSupabaseReachable ? "Supabase OK" : "Supabase unreachable"
        if let liveVersionLine, isGitHubReachable {
            return "\(gh) · \(sb) · live \(liveVersionLine)"
        }
        return "\(gh) · \(sb)"
    }

    private var pollTask: Task<Void, Never>?

    private init() {}

    func startPolling(intervalSeconds: UInt64 = 30) {
        pollTask?.cancel()
        pollTask = Task {
            await refresh()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: intervalSeconds * 1_000_000_000)
                await refresh()
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    func refresh() async {
        async let github = checkGitHubLive()
        async let supabase = checkSupabase()
        let (gh, sb) = await (github, supabase)
        isGitHubReachable = gh.reachable
        isSupabaseReachable = sb.reachable
        liveVersionLine = gh.liveVersion
        lastCheckedAt = Date()
        if !gh.reachable || !sb.reachable {
            var parts: [String] = []
            if let m = gh.message { parts.append(m) }
            if let m = sb.message { parts.append(m) }
            lastErrorLine = parts.joined(separator: " · ")
        } else {
            lastErrorLine = nil
        }
    }

    private struct ProbeResult {
        let reachable: Bool
        let liveVersion: String?
        let message: String?
    }

    private func checkGitHubLive() async -> ProbeResult {
        guard let versionURL = AppReleaseConfig.releaseDownloadURL(
            tag: AppReleaseConfig.liveTag,
            assetName: "VERSION.txt"
        ) else {
            return ProbeResult(reachable: false, liveVersion: nil, message: "GitHub: invalid repo config")
        }
        var request = URLRequest(url: versionURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 12
        request.setValue("Publshr/1.0", forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return ProbeResult(reachable: false, liveVersion: nil, message: "GitHub live VERSION.txt HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            }
            let line = String(data: data, encoding: .utf8)?
                .split(separator: "\n", omittingEmptySubsequences: true)
                .first
                .map(String.init)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return ProbeResult(reachable: true, liveVersion: line, message: nil)
        } catch {
            return ProbeResult(reachable: false, liveVersion: nil, message: "GitHub: \(error.localizedDescription)")
        }
    }

    private func checkSupabase() async -> ProbeResult {
        var request = URLRequest(url: SupabaseConfig.url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 8
        request.setValue(SupabaseConfig.publishableKey, forHTTPHeaderField: "apikey")
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return ProbeResult(reachable: false, liveVersion: nil, message: "Supabase: bad response")
            }
            let ok = (200 ... 499).contains(http.statusCode)
            return ProbeResult(
                reachable: ok,
                liveVersion: nil,
                message: ok ? nil : "Supabase HTTP \(http.statusCode)"
            )
        } catch {
            return ProbeResult(reachable: false, liveVersion: nil, message: "Supabase: \(error.localizedDescription)")
        }
    }
}
