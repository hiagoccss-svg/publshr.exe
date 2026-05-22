import Foundation

/// GitHub `live` release channel — same URLs as install-publshr.sh.
enum AppReleaseConfig {
    static let defaultRepo = "hiagoccss-svg/publshr.exe"
    static let liveTag = "live"
    static let minAppAssetBytes = 5_000_000

    static var githubRepo: String {
        Bundle.main.object(forInfoDictionaryKey: "PublshrGitHubRepo") as? String ?? defaultRepo
    }

    static var shortVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    static var buildNumber: Int {
        let raw = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return Int(raw) ?? 0
    }

    static var installedLabel: String {
        "\(shortVersion) (\(buildNumber))"
    }

    static func releasesURL() -> URL? {
        let parts = githubRepo.split(separator: "/", omittingEmptySubsequences: true)
        guard parts.count == 2 else { return nil }
        return URL(string: "https://api.github.com/repos/\(parts[0])/\(parts[1])/releases?per_page=30")
    }

    static func liveAssetName() -> String {
        #if arch(arm64)
        return "Publshr-macos-aarch64.tar.gz"
        #else
        return "Publshr-macos-x86_64.tar.gz"
        #endif
    }

    static func platformAssetName(version: String) -> String {
        #if arch(arm64)
        let arch = "aarch64"
        #else
        let arch = "x86_64"
        #endif
        return "publshr-\(version)-macos-\(arch).tar.gz"
    }
}
