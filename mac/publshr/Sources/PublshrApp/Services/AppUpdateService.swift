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
}

enum AppUpdateError: LocalizedError {
    case invalidRepo
    case noReleases
    case noCompatibleAsset
    case downloadFailed(String)
    case extractFailed
    case applyScriptMissing
    case notInstalledInApplications

    var errorDescription: String? {
        switch self {
        case .invalidRepo: return "Invalid GitHub repository configuration."
        case .noReleases: return "No published releases found on GitHub."
        case .noCompatibleAsset: return "No macOS build is available for this Mac."
        case .downloadFailed(let detail): return "Download failed: \(detail)"
        case .extractFailed: return "Could not extract the update package."
        case .applyScriptMissing: return "Update helper script is missing from the app bundle."
        case .notInstalledInApplications:
            return "Install Publshr to /Applications/Publshr.app to enable automatic updates."
        }
    }
}

/// Checks GitHub `live` release (same as install-publshr.sh) and installs updates.
final class AppUpdateService: @unchecked Sendable {
    static let shared = AppUpdateService()

    private let session: URLSession
    private let fileManager = FileManager.default
    private let decoder = JSONDecoder()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func checkForUpdate() async throws -> AvailableUpdate? {
        let localBuild = AppReleaseConfig.buildNumber
        guard let live = try await fetchLiveRelease() else {
            throw AppUpdateError.noReleases
        }

        if let update = try await parseLiveRelease(live, localBuild: localBuild) {
            return update
        }

        // Fallback: newest versioned tag (e.g. v0.2.0.51) when live metadata is stale.
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
        return best
    }

    func download(
        _ update: AvailableUpdate,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        let updatesRoot = supportUpdatesDirectory()
        try fileManager.createDirectory(at: updatesRoot, withIntermediateDirectories: true)

        let archiveURL = updatesRoot.appendingPathComponent(update.assetName)
        try? fileManager.removeItem(at: archiveURL)

        var request = URLRequest(url: update.downloadURL)
        request.setValue("Publshr/1.0", forHTTPHeaderField: "User-Agent")

        let (tempURL, response) = try await session.download(for: request)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw AppUpdateError.downloadFailed("HTTP \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        }

        progress(1.0)
        try fileManager.moveItem(at: tempURL, to: archiveURL)
        return archiveURL
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
        guard let script = Bundle.main.url(forResource: "apply-macos-update", withExtension: "sh") else {
            throw AppUpdateError.applyScriptMissing
        }

        let installed = URL(fileURLWithPath: "/Applications/Publshr.app")
        let bundlePath = Bundle.main.bundleURL.standardizedFileURL
        if bundlePath != installed.standardizedFileURL && !bundlePath.path.hasPrefix(installed.path) {
            // Allow dev builds but warn in logs; still attempt install to /Applications.
            appendSyncLog("WARN: running from \(bundlePath.path); update target is /Applications/Publshr.app")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [script.path, treeURL.path, String(parentPID)]
        process.standardOutput = nil
        process.standardError = nil
        try process.run()
    }

    private func supportUpdatesDirectory() -> URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("Publshr/updates", isDirectory: true)
    }

    private func appendSyncLog(_ line: String) {
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
            throw AppUpdateError.downloadFailed("No HTTP response")
        }
        if http.statusCode == 404 { return nil }
        guard (200 ... 299).contains(http.statusCode) else {
            throw AppUpdateError.downloadFailed("GitHub live release HTTP \(http.statusCode)")
        }
        return try decoder.decode(GitHubRelease.self, from: data)
    }

    private func fetchRecentReleases() async throws -> [GitHubRelease] {
        guard let url = AppReleaseConfig.releasesURL() else {
            throw AppUpdateError.invalidRepo
        }
        let (data, response) = try await session.data(for: githubRequest(url: url))
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw AppUpdateError.downloadFailed("GitHub releases HTTP \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        }
        return try decoder.decode([GitHubRelease].self, from: data)
    }

    private func parseLiveRelease(_ live: GitHubRelease, localBuild: Int) async throws -> AvailableUpdate? {
        let assetName = AppReleaseConfig.liveAssetName()
        guard let asset = live.assets.first(where: { $0.name == assetName }),
              asset.size >= AppReleaseConfig.minAppAssetBytes,
              let downloadURL = URL(string: asset.browserDownloadUrl),
              let pageURL = URL(string: live.htmlURL) else {
            throw AppUpdateError.noCompatibleAsset
        }

        let build = parseBuildNumber(from: live)
            ?? await fetchBuildFromVersionAsset(in: live.assets)
            ?? 0

        appendSyncLog("live check: local=\(localBuild) remote=\(build) asset=\(assetName) size=\(asset.size)")

        guard build > localBuild else { return nil }

        let version = parseVersionLabel(from: live) ?? "live.\(build)"
        return AvailableUpdate(
            version: version,
            build: build,
            tag: AppReleaseConfig.liveTag,
            downloadURL: downloadURL,
            releasePage: pageURL,
            assetName: assetName
        )
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

    /// Reads `VERSION.txt` from the live release (line 2 = CI build number).
    private func fetchBuildFromVersionAsset(in assets: [GitHubAsset]) async -> Int? {
        guard let asset = assets.first(where: { $0.name == "VERSION.txt" }),
              let url = URL(string: asset.browserDownloadUrl) else {
            return nil
        }
        do {
            let (data, response) = try await session.data(for: githubRequest(url: url))
            guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
                return nil
            }
            guard let text = String(data: data, encoding: .utf8) else { return nil }
            let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
            guard lines.count >= 2 else { return nil }
            return Int(lines[1].trimmingCharacters(in: .whitespacesAndNewlines))
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
              let downloadURL = URL(string: asset.browserDownloadUrl),
              let pageURL = URL(string: release.htmlURL) else {
            return nil
        }

        return AvailableUpdate(
            version: version,
            build: build,
            tag: tag,
            downloadURL: downloadURL,
            releasePage: pageURL,
            assetName: assetName
        )
    }
}
