import Foundation

/// Parsed from the `live` release `VERSION.txt` asset (CI publishes on every push to main).
struct LiveChannelManifest: Sendable, Equatable {
    let fullVersion: String
    let build: Int
    let commit: String
    let packageDigest: String?
    /// Enterprise shell marker (`PublshrEnterpriseShell-N`) — line 5 of `VERSION.txt`.
    let shellTag: String?

    static func parse(_ text: String) -> LiveChannelManifest? {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map {
            String($0).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard let full = lines.first, !full.isEmpty else { return nil }
        let build = lines.count >= 2 ? Int(lines[1]) : nil
        guard let build else { return nil }
        let commit = lines.count >= 3 ? lines[2] : ""
        let digest = lines.count >= 4 && !lines[3].isEmpty ? lines[3] : nil
        let shell = lines.count >= 5 && !lines[4].isEmpty ? lines[4] : nil
        return LiveChannelManifest(
            fullVersion: full,
            build: build,
            commit: commit,
            packageDigest: digest,
            shellTag: shell
        )
    }

    /// Any change on `main` (icon, UI, shell, features) produces a new build/commit/digest/shell.
    func isNewerThanInstalled() -> Bool {
        let localBuild = AppReleaseConfig.buildNumber
        let localVersion = AppReleaseConfig.liveFullVersion
        let localCommit = AppReleaseConfig.liveCommit
        let localShell = AppReleaseConfig.liveShellTag

        if build > localBuild { return true }
        if fullVersion != localVersion { return true }
        if !commit.isEmpty, !localCommit.isEmpty, commit != localCommit { return true }
        if let shellTag, !shellTag.isEmpty, shellTag != localShell { return true }
        if let packageDigest, !packageDigest.isEmpty {
            let localDigest = AppReleaseConfig.livePackageDigest
            if !localDigest.isEmpty, packageDigest != localDigest {
                return true
            }
        }
        return false
    }

    var detailLabel: String {
        var parts = ["build \(build)", fullVersion]
        if let shellTag, !shellTag.isEmpty { parts.append(shellTag) }
        if !commit.isEmpty { parts.append("commit \(commit.prefix(7))") }
        if let packageDigest, !packageDigest.isEmpty { parts.append("sha \(packageDigest.prefix(12))") }
        return parts.joined(separator: " · ")
    }
}
