import CryptoKit
import Foundation

struct GitHubRelease: Decodable, Sendable {
    let tagName: String
    let name: String?
    let body: String?
    let htmlURL: String
    let publishedAt: String
    let assets: [GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlURL = "html_url"
        case publishedAt = "published_at"
        case assets
    }
}

struct GitHubAsset: Decodable, Sendable {
    let name: String
    let browserDownloadUrl: String
    let size: Int

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadUrl = "browser_download_url"
        case size
    }
}

struct AvailableUpdate: Sendable, Equatable {
    let version: String
    let build: Int
    let tag: String
    let downloadURL: URL
    let releasePage: URL
    let assetName: String
    let packageDigest: String?
}

enum AppUpdateError: LocalizedError {
    case invalidRepo
    case noReleases
    case noCompatibleAsset
    case downloadFailed
    case extractFailed
    case applyScriptMissing
    case updateCheckUnavailable

    /// Enterprise-facing copy — no HTTP codes, hosts, or delivery channel names.
    var errorDescription: String? {
        switch self {
        case .invalidRepo, .noReleases, .noCompatibleAsset:
            return "Software updates are not available for this installation."
        case .downloadFailed:
            return "The update could not be downloaded. Check your connection and try again."
        case .extractFailed:
            return "The update package could not be prepared. Try again from Settings."
        case .applyScriptMissing:
            return "This installation cannot apply updates automatically. Reinstall from your IT team."
        case .updateCheckUnavailable:
            return "Could not reach the update server. Check your connection and tap Sync now."
        }
    }
}

/// Checks GitHub `live` release (same as install-publshr.sh) and installs updates.
final class AppUpdateService: @unchecked Sendable {
    static let shared = AppUpdateService()

    /// Last `live/VERSION.txt` successfully read (used by Settings for remote detail).
    private(set) var lastRemoteManifest: LiveChannelManifest?

    private let session: URLSession
    private let fileManager = FileManager.default
    private let decoder = JSONDecoder()

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 180
            config.timeoutIntervalForResource = 600
            config.waitsForConnectivity = true
            self.session = URLSession(configuration: config)
        }
    }

    private func assetDownloadRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("application/octet-stream", forHTTPHeaderField: "Accept")
        request.setValue("Publshr/1.0", forHTTPHeaderField: "User-Agent")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        return request
    }

    private func resolvedDownloadURL(for update: AvailableUpdate) -> URL {
        AppReleaseConfig.releaseDownloadURL(tag: update.tag, assetName: update.assetName)
            ?? update.downloadURL
    }

    private enum LiveManifestCheck {
        case updateAvailable(AvailableUpdate)
        case confirmedUpToDate
        case unavailable
    }

    private enum FallbackCheck {
        case updateAvailable(AvailableUpdate)
        case confirmedUpToDate
        case unavailable
    }

    func checkForUpdate() async throws -> AvailableUpdate? {
        switch await evaluateLiveManifest() {
        case .updateAvailable(let update):
            return update
        case .confirmedUpToDate:
            return nil
        case .unavailable:
            break
        }
        switch await evaluateVersionedFallback() {
        case .updateAvailable(let update):
            return update
        case .confirmedUpToDate:
            return nil
        case .unavailable:
            throw AppUpdateError.updateCheckUnavailable
        }
    }

    /// Compares installed build/version/commit/digest against `live/VERSION.txt` (published on every push to main).
    private func evaluateLiveManifest() async -> LiveManifestCheck {
        guard let manifest = await fetchLiveManifestFromURL() else {
            appendSyncLog("VERSION.txt check: unavailable")
            return .unavailable
        }

        lastRemoteManifest = manifest
        appendSyncLog(
            "VERSION.txt check: local=\(AppReleaseConfig.installedLabel) "
                + "remote=\(manifest.detailLabel)"
        )

        guard manifest.isNewerThanInstalled() else {
            return .confirmedUpToDate
        }

        guard let update = availableUpdate(from: manifest) else {
            return .unavailable
        }
        return .updateAvailable(update)
    }

    private func availableUpdate(from manifest: LiveChannelManifest) -> AvailableUpdate? {
        let assetName = AppReleaseConfig.liveAssetName()
        guard let downloadURL = AppReleaseConfig.releaseDownloadURL(
            tag: AppReleaseConfig.liveTag,
            assetName: assetName
        ),
        let pageURL = URL(string: "https://github.com/\(AppReleaseConfig.githubRepo)/releases/tag/live") else {
            appendSyncLog("live download URL unavailable")
            return nil
        }

        return AvailableUpdate(
            version: manifest.fullVersion,
            build: manifest.build,
            tag: AppReleaseConfig.liveTag,
            downloadURL: downloadURL,
            releasePage: pageURL,
            assetName: assetName,
            packageDigest: manifest.packageDigest
        )
    }

    func download(
        _ update: AvailableUpdate,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        let updatesRoot = supportUpdatesDirectory()
        try fileManager.createDirectory(at: updatesRoot, withIntermediateDirectories: true)

        try? fileManager.removeItem(at: updatesRoot.appendingPathComponent("staging-\(update.version)", isDirectory: true))
        let archiveURL = updatesRoot.appendingPathComponent("\(update.build)-\(update.assetName)")
        try? fileManager.removeItem(at: archiveURL)

        let downloadURL = resolvedDownloadURL(for: update)
        let (tempURL, response) = try await session.download(for: assetDownloadRequest(url: downloadURL))
        let http = response as? HTTPURLResponse
        let bytes = (try? fileManager.attributesOfItem(atPath: tempURL.path)[.size] as? Int) ?? 0

        if bytes < AppReleaseConfig.minAppAssetBytes {
            let code = http?.statusCode ?? -1
            appendSyncLog("download failed status=\(code) bytes=\(bytes) url=\(downloadURL.absoluteString)")
            throw AppUpdateError.downloadFailed
        }

        if update.tag == AppReleaseConfig.liveTag {
            guard let expected = update.packageDigest?.lowercased(), !expected.isEmpty else {
                appendSyncLog("download rejected: live update missing VERSION.txt digest")
                throw AppUpdateError.downloadFailed
            }
            guard let actual = sha256Hex(of: tempURL)?.lowercased(), actual == expected else {
                appendSyncLog(
                    "download digest mismatch expected=\(expected.prefix(12)) "
                        + "actual=\(sha256Hex(of: tempURL)?.prefix(12) ?? "nil")"
                )
                throw AppUpdateError.downloadFailed
            }
        } else if let expected = update.packageDigest?.lowercased(),
                  !expected.isEmpty,
                  let actual = sha256Hex(of: tempURL)?.lowercased(),
                  actual != expected {
            appendSyncLog("download digest mismatch expected=\(expected.prefix(12)) actual=\(actual.prefix(12))")
            throw AppUpdateError.downloadFailed
        }

        progress(1.0)
        try fileManager.moveItem(at: tempURL, to: archiveURL)
        appendSyncLog("download ok bytes=\(bytes) build=\(update.build)")
        return archiveURL
    }

    private func sha256Hex(of fileURL: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: fileURL) else { return nil }
        defer { try? handle.close() }
        var hasher = SHA256()
        while true {
            let chunk = (try? handle.read(upToCount: 1_048_576)) ?? Data()
            if chunk.isEmpty { break }
            hasher.update(data: chunk)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    func extract(archiveURL: URL, version: String) throws -> URL {
        let staging = supportUpdatesDirectory()
            .appendingPathComponent("staging-\(version)", isDirectory: true)
        try? fileManager.removeItem(at: staging)
        try fileManager.createDirectory(at: staging, withIntermediateDirectories: true)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        process.arguments = ["-xzf", archiveURL.path, "-C", staging.path]
        let pipe = Pipe()
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw AppUpdateError.extractFailed
        }

        if let bundle = findAppBundle(under: staging) {
            let flatApp = staging.appendingPathComponent("Publshr.app", isDirectory: true)
            if bundle != flatApp {
                try? fileManager.removeItem(at: flatApp)
                try fileManager.moveItem(at: bundle, to: flatApp)
            }
            return staging
        }
        throw AppUpdateError.extractFailed
    }

    private func findAppBundle(under root: URL) -> URL? {
        let direct = root.appendingPathComponent("Publshr.app", isDirectory: true)
        if fileManager.fileExists(atPath: direct.path) { return direct }
        guard let entries = try? fileManager.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }
        for entry in entries {
            var isDir: ObjCBool = false
            guard fileManager.fileExists(atPath: entry.path, isDirectory: &isDir), isDir.boolValue else {
                continue
            }
            let nested = entry.appendingPathComponent("Publshr.app", isDirectory: true)
            if fileManager.fileExists(atPath: nested.path) { return nested }
        }
        return nil
    }

    func applyUpdate(treeURL: URL, parentPID: Int32) throws {
        guard let script = resolveApplyUpdateScript() else {
            throw AppUpdateError.applyScriptMissing
        }

        let bundlePath = Bundle.main.bundleURL.standardizedFileURL.path
        let targetPath = AppReleaseConfig.liveUpdateTargetPath
        appendSyncLog("apply update: running=\(bundlePath) target=\(targetPath)")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [script.path, treeURL.path, String(parentPID), targetPath]
        var env = ProcessInfo.processInfo.environment
        env["PUBLSHR_MAC_APP"] = targetPath
        process.environment = env
        let logURL = supportUpdatesDirectory().appendingPathComponent("last-update.log")
        if let logHandle = try? FileHandle(forWritingTo: logURL) {
            logHandle.seekToEndOfFile()
            process.standardOutput = logHandle
            process.standardError = logHandle
        } else {
            try? Data().write(to: logURL)
            if let logHandle = try? FileHandle(forWritingTo: logURL) {
                process.standardOutput = logHandle
                process.standardError = logHandle
            }
        }
        try process.run()
    }

    private func supportUpdatesDirectory() -> URL {
        LocalDataLayout.ensureRootExists()
        return LocalDataLayout.updatesDirectory
    }

    private func resolveApplyUpdateScript() -> URL? {
        if let url = Bundle.main.url(forResource: "apply-macos-update", withExtension: "sh") {
            return url
        }
        let resources = Bundle.main.resourceURL?
            .appendingPathComponent("apply-macos-update.sh")
        if let resources, fileManager.fileExists(atPath: resources.path) {
            return resources
        }
        return nil
    }

    func appendSyncLog(_ line: String) {
        let log = supportUpdatesDirectory().appendingPathComponent("last-sync.log")
        try? fileManager.createDirectory(at: log.deletingLastPathComponent(), withIntermediateDirectories: true)
        let stamp = ISO8601DateFormatter().string(from: Date())
        let msg = "[\(stamp)] \(line)\n"
        if fileManager.fileExists(atPath: log.path),
           let handle = try? FileHandle(forWritingTo: log) {
            handle.seekToEndOfFile()
            handle.write(Data(msg.utf8))
            try? handle.close()
        } else {
            try? Data(msg.utf8).write(to: log)
        }
    }

    private func githubRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Publshr/1.0", forHTTPHeaderField: "User-Agent")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        return request
    }

    private func fetchLiveRelease() async throws -> GitHubRelease? {
        guard let url = AppReleaseConfig.liveReleaseURL() else {
            throw AppUpdateError.invalidRepo
        }
        let (data, response) = try await session.data(for: githubRequest(url: url))
        guard let http = response as? HTTPURLResponse else {
            appendSyncLog("live release: no HTTP response")
            throw AppUpdateError.downloadFailed
        }
        if http.statusCode == 404 { return nil }
        guard (200 ... 299).contains(http.statusCode) else {
            appendSyncLog("live release metadata HTTP \(http.statusCode)")
            throw AppUpdateError.downloadFailed
        }
        return try decoder.decode(GitHubRelease.self, from: data)
    }

    private func fetchRecentReleases() async throws -> [GitHubRelease] {
        guard let url = AppReleaseConfig.releasesURL() else {
            throw AppUpdateError.invalidRepo
        }
        let (data, response) = try await session.data(for: githubRequest(url: url))
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            appendSyncLog("releases list HTTP \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            throw AppUpdateError.downloadFailed
        }
        return try decoder.decode([GitHubRelease].self, from: data)
    }

    private func parseLiveRelease(_ live: GitHubRelease) async throws -> AvailableUpdate? {
        let assetName = AppReleaseConfig.liveAssetName()
        guard let asset = live.assets.first(where: { $0.name == assetName }),
              asset.size >= AppReleaseConfig.minAppAssetBytes,
              let downloadURL = AppReleaseConfig.releaseDownloadURL(tag: AppReleaseConfig.liveTag, assetName: assetName),
              let pageURL = URL(string: live.htmlURL) else {
            throw AppUpdateError.noCompatibleAsset
        }

        let manifest = await fetchLiveManifestFromURL()
            ?? manifestFromReleaseNotes(live)

        guard let manifest else {
            appendSyncLog("live check: could not parse VERSION.txt or release notes")
            return nil
        }

        lastRemoteManifest = manifest
        appendSyncLog(
            "live check: local=\(AppReleaseConfig.installedLabel) "
                + "remote=\(manifest.detailLabel) asset=\(asset.size)"
        )

        guard manifest.isNewerThanInstalled() else { return nil }

        return availableUpdate(from: manifest)
    }

    private func evaluateVersionedFallback() async -> FallbackCheck {
        do {
            guard let live = try await fetchLiveRelease() else {
                appendSyncLog("live release: not found")
                return .unavailable
            }
            if let update = try await parseLiveRelease(live) {
                appendSyncLog("live check: update available via GitHub API fallback")
                return .updateAvailable(update)
            }
            let manifest = await fetchLiveManifestFromURL() ?? manifestFromReleaseNotes(live)
            if manifest != nil {
                appendSyncLog("live check: confirmed up to date via GitHub API")
                return .confirmedUpToDate
            }
        } catch {
            appendSyncLog("API fallback skipped: \(error.localizedDescription)")
        }
        do {
            let localBuild = AppReleaseConfig.buildNumber
            let releases = try await fetchRecentReleases()
            var best: AvailableUpdate?
            for release in releases where release.tagName != AppReleaseConfig.liveTag {
                guard let candidate = parseVersionedRelease(release) else { continue }
                if candidate.build <= localBuild { continue }
                if let current = best {
                    if candidate.build > current.build { best = candidate }
                } else {
                    best = candidate
                }
            }
            if let best {
                return .updateAvailable(best)
            }
        } catch {
            appendSyncLog("versioned fallback skipped: \(error.localizedDescription)")
        }
        return .unavailable
    }

    private func manifestFromReleaseNotes(_ live: GitHubRelease) -> LiveChannelManifest? {
        guard let build = parseBuildNumber(from: live) else { return nil }
        let version = parseVersionLabel(from: live) ?? "\(AppReleaseConfig.shortVersion).\(build)"
        let commit = parseCommitSha(from: live) ?? ""
        let shell = parseShellTag(from: live) ?? AppShellIdentity.distributionTag
        return LiveChannelManifest(
            fullVersion: version,
            build: build,
            commit: commit,
            packageDigest: nil,
            shellTag: shell
        )
    }

    private func parseShellTag(from release: GitHubRelease) -> String? {
        let text = release.body ?? ""
        for line in text.split(separator: "\n") {
            let s = String(line)
            guard s.contains("shell:") else { continue }
            let value = s.split(separator: ":", maxSplits: 1).last?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !value.isEmpty { return value }
        }
        return nil
    }

    private func parseCommitSha(from release: GitHubRelease) -> String? {
        let text = release.body ?? ""
        for line in text.split(separator: "\n") {
            let s = String(line)
            guard s.contains("commit:") else { continue }
            let value = s.split(separator: ":", maxSplits: 1).last?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !value.isEmpty { return value }
        }
        return nil
    }

    private func parseBuildNumber(from release: GitHubRelease) -> Int? {
        let text = "\(release.body ?? "")\n\(release.name ?? "")"
        for line in text.split(separator: "\n") {
            let s = String(line)
            guard s.contains("build_number:") else { continue }
            let value = s.split(separator: ":", maxSplits: 1).last?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if let n = Int(value) { return n }
        }
        return nil
    }

    /// Reads `VERSION.txt` from the live release (version, build, commit, package digest).
    private func fetchLiveManifestFromURL() async -> LiveChannelManifest? {
        guard let url = AppReleaseConfig.releaseDownloadURL(tag: AppReleaseConfig.liveTag, assetName: "VERSION.txt") else {
            return nil
        }
        do {
            let (data, response) = try await session.data(for: assetDownloadRequest(url: url))
            guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
                appendSyncLog("VERSION.txt HTTP \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                return nil
            }
            guard let text = String(data: data, encoding: .utf8),
                  let manifest = LiveChannelManifest.parse(text) else {
                appendSyncLog("VERSION.txt parse failed")
                return nil
            }
            return manifest
        } catch {
            appendSyncLog("VERSION.txt fetch failed: \(error.localizedDescription)")
            return nil
        }
    }

    private func parseVersionLabel(from release: GitHubRelease) -> String? {
        if let body = release.body,
           let line = body.split(separator: "\n").first(where: { $0.contains("version:") }) {
            let value = line.split(separator: ":").last.map { $0.trimmingCharacters(in: .whitespaces) }
            if let value, !value.isEmpty { return value }
        }
        return release.name?
            .replacingOccurrences(of: "Publshr live (", with: "")
            .replacingOccurrences(of: ")", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    private func parseVersionedRelease(_ release: GitHubRelease) -> AvailableUpdate? {
        let tag = release.tagName
        let trimmed = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
        let parts = trimmed.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count >= 2, let build = Int(parts.last ?? "") else { return nil }

        let version = trimmed
        let assetName = AppReleaseConfig.platformAssetName(version: version)
        guard let asset = release.assets.first(where: { $0.name == assetName }),
              asset.size >= AppReleaseConfig.minAppAssetBytes,
              let downloadURL = AppReleaseConfig.releaseDownloadURL(tag: tag, assetName: assetName),
              let pageURL = URL(string: release.htmlURL) else {
            return nil
        }

        return AvailableUpdate(
            version: version,
            build: build,
            tag: tag,
            downloadURL: downloadURL,
            releasePage: pageURL,
            assetName: assetName,
            packageDigest: nil
        )
    }

}
