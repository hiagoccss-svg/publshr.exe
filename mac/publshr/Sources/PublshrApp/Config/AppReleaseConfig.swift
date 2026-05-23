import Foundation

/// GitHub `live` release channel — same URLs as install-publshr.sh.
enum AppReleaseConfig {
    static let defaultRepo = "hiagoccss-svg/publshr.exe"
    static let liveTag = "live"
    static let minAppAssetBytes = 5_000_000

    /// Poll GitHub `live` + run Supabase sync on this interval (also on wake / app active / Sync now).
    static let livePollIntervalSeconds: UInt64 = 30

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

    /// Full live label baked at build time (e.g. 0.2.0.57).
    static var liveFullVersion: String {
        let embedded = Bundle.main.object(forInfoDictionaryKey: "PublshrLiveVersion") as? String
        if let embedded, !embedded.isEmpty { return embedded }
        return "\(shortVersion).\(buildNumber)"
    }

    /// Git commit embedded at CI build time.
    static var liveCommit: String {
        Bundle.main.object(forInfoDictionaryKey: "PublshrLiveCommit") as? String ?? ""
    }

    /// SHA-256 of the live tarball (line 4 of VERSION.txt). Plist when CI embeds it; else last successful install.
    static var livePackageDigest: String {
        if let embedded = Bundle.main.object(forInfoDictionaryKey: "PublshrLivePackageDigest") as? String,
           !embedded.isEmpty {
            return embedded
        }
        return UserDefaults.standard.string(forKey: "publshr.installedLiveDigest") ?? ""
    }

    /// Called before in-place install so post-relaunch update detection matches `live/VERSION.txt`.
    static func recordInstalledLiveManifest(version: String, build: Int, digest: String?) {
        UserDefaults.standard.set(version, forKey: "publshr.appliedLiveVersion")
        UserDefaults.standard.set(build, forKey: "publshr.appliedLiveBuild")
        if let digest, !digest.isEmpty {
            UserDefaults.standard.set(digest, forKey: "publshr.installedLiveDigest")
        }
    }

    /// Enterprise shell distribution tag baked at build time (matches `AppShellIdentity` / VERSION.txt line 5).
    static var liveShellTag: String {
        if let embedded = Bundle.main.object(forInfoDictionaryKey: "PublshrShellDistribution") as? String,
           !embedded.isEmpty {
            return embedded
        }
        return AppShellIdentity.distributionTag
    }

    /// Clears stale "applied update" markers when an install was recorded but the running bundle did not change.
    static func reconcileAppliedManifestWithBundle() {
        let bundleBuild = buildNumber
        let storedBuild = UserDefaults.standard.integer(forKey: "publshr.appliedLiveBuild")
        guard storedBuild > 0, storedBuild > bundleBuild else { return }
        UserDefaults.standard.removeObject(forKey: "publshr.appliedLiveVersion")
        UserDefaults.standard.removeObject(forKey: "publshr.appliedLiveBuild")
        UserDefaults.standard.removeObject(forKey: "publshr.appliedLiveDigest")
        AppUpdateService.shared.appendSyncLog(
            "cleared stale applied manifest (recorded build \(storedBuild), running build \(bundleBuild))"
        )
    }

    static var installedLabel: String {
        "\(liveFullVersion) · build \(buildNumber) · \(liveShellTag)"
    }

    /// Where this instance runs from (used for in-place live updates).
    static var installedAppPath: String {
        Bundle.main.bundleURL.standardizedFileURL.path
    }

    static var preferredInstallPath: String {
        InstallPathPolicy.userApplicationsApp.path
    }

    /// Where live updates install (migrates off system /Applications without admin prompts).
    static var liveUpdateTargetPath: String {
        InstallPathPolicy.resolvedLiveUpdateTarget(runningBundlePath: installedAppPath)
    }

    static func releasesURL() -> URL? {
        let parts = githubRepo.split(separator: "/", omittingEmptySubsequences: true)
        guard parts.count == 2 else { return nil }
        return URL(string: "https://api.github.com/repos/\(parts[0])/\(parts[1])/releases?per_page=30")
    }

    /// Single-release endpoint — reliable for the `live` channel (not paginated).
    static func liveReleaseURL() -> URL? {
        let parts = githubRepo.split(separator: "/", omittingEmptySubsequences: true)
        guard parts.count == 2 else { return nil }
        return URL(string: "https://api.github.com/repos/\(parts[0])/\(parts[1])/releases/tags/live")
    }

    static func liveAssetName() -> String {
        #if arch(arm64)
        return "Publshr-macos-aarch64.tar.gz"
        #else
        return "Publshr-macos-x86_64.tar.gz"
        #endif
    }

    /// Same URL as install-macos.sh — avoids GitHub API asset endpoints that return 403 without special headers.
    static func releaseDownloadURL(tag: String, assetName: String) -> URL? {
        let parts = githubRepo.split(separator: "/", omittingEmptySubsequences: true)
        guard parts.count == 2 else { return nil }
        let encodedTag = tag.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? tag
        let encodedAsset = assetName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? assetName
        return URL(string: "https://github.com/\(parts[0])/\(parts[1])/releases/download/\(encodedTag)/\(encodedAsset)")
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
