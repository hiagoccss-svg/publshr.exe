import Foundation

/// Parsed from the `live` release `VERSION.txt` asset (CI publishes on every push to main).
struct LiveChannelManifest: Sendable, Equatable {
    let fullVersion: String
    let build: Int
    let commit: String
    let packageDigest: String?

    static func parse(_ text: String) -> LiveChannelManifest? {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map {
            String($0).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard let full = lines.first, !full.isEmpty else { return nil }
        let build = lines.count >= 2 ? Int(lines[1]) : nil
        guard let build else { return nil }
        let commit = lines.count >= 3 ? lines[2] : ""
        let digest = lines.count >= 4 && !lines[3].isEmpty ? lines[3] : nil
        return LiveChannelManifest(fullVersion: full, build: build, commit: commit, packageDigest: digest)
    }

    /// Any change on `main` (icon, UI, features, tarball bytes) produces a new build/commit/digest.
    func isNewerThanInstalled() -> Bool {
        let localBuild = AppReleaseConfig.buildNumber
        let localVersion = AppReleaseConfig.liveFullVersion
        let localCommit = AppReleaseConfig.liveCommit
        let localDigest = AppReleaseConfig.livePackageDigest

        if build > localBuild { return true }
        if fullVersion != localVersion { return true }
        if !commit.isEmpty, !localCommit.isEmpty, commit != localCommit { return true }
        if let remoteDigest = packageDigest, !remoteDigest.isEmpty,
           !localDigest.isEmpty, remoteDigest != localDigest {
            return true
        }
        return false
    }
}
