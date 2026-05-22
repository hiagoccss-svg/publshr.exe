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
        }
    }
}

/// Checks GitHub `live` release (same as install-publshr.sh) and installs updates in place.
final class AppUpdateService: @unchecked Sendable {
    static let shared = AppUpdateService()

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

    private func headAssetRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.setValue("Publshr/1.0", forHTTPHeaderField: "User-Agent")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        return request
    }

    private func resolvedDownloadURL(for update: AvailableUpdate) -> URL {
        AppReleaseConfig.releaseDownloadURL(tag: update.tag, assetName: update.assetName)
            ?? update.downloadURL
    }

    /// Primary path: fixed `releases/download/live/...` URLs only (no GitHub REST API).
    func checkForUpdate() async throws -> AvailableUpdate? {
        if let update = try await checkLiveChannelViaDirectURLs() {
            return update
        }
        return await checkVersionedFallbackSilently()
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

        progress(1.0)
        try fileManager.moveItem(at: tempURL, to: archiveURL)
        appendSyncLog("download ok bytes=\(bytes) build=\(update.build)")
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
        guard let script = resolveApplyUpdateScript() else {
            throw AppUpdateError.applyScriptMissing
        }

        let bundlePath = Bundle.main.bundleURL.standardizedFileURL.path
        appendSyncLog("apply update in place: \(bundlePath)")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [script.path, treeURL.path, String(parentPID), bundlePath]
        var env = ProcessInfo.processInfo.environment
        env["PUBLSHR_MAC_APP"] = bundlePath
        process.environment = env
        process.standardOutput = nil
        process.standardError = nil
        try process.run()
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

    private func supportUpdatesDirectory() -> URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("Publshr/updates", isDirectory: true)
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

    // MARK: - Live channel (direct download URLs)

    private func checkLiveChannelViaDirectURLs() async throws -> AvailableUpdate? {
        guard let manifest = await fetchLiveManifestDirect() else {
            appendSyncLog("live check: VERSION.txt unavailable or invalid")
            return nil
        }

        appendSyncLog(
            "live check: local=\(AppReleaseConfig.installedLabel) "
                + "remote=\(manifest.fullVersion) build=\(manifest.build) "
                + "commit=\(manifest.commit.prefix(7)) digest=\(manifest.packageDigest?.prefix(12) ?? "—")"
        )

        guard manifest.isNewerThanInstalled() else {
            appendSyncLog("live check: up to date")
            return nil
        }

        let assetName = AppReleaseConfig.liveAssetName()
        guard let downloadURL = AppReleaseConfig.releaseDownloadURL(tag: AppReleaseConfig.liveTag, assetName: assetName) else {
            throw AppUpdateError.invalidRepo
        }

        let assetBytes = await headAssetByteCount(url: downloadURL)
        if let assetBytes, assetBytes < AppReleaseConfig.minAppAssetBytes {
            appendSyncLog("live check: asset too small (\(assetBytes) bytes)")
            return nil
        }

        let pageURL = URL(string: "https://github.com/\(AppReleaseConfig.githubRepo)/releases/tag/live")
            ?? downloadURL

        appendSyncLog("live check: update available → in-place install")
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

    private func fetchLiveManifestDirect() async -> LiveChannelManifest? {
        guard let url = AppReleaseConfig.releaseDownloadURL(tag: AppReleaseConfig.liveTag, assetName: "VERSION.txt") else {
            return nil
        }
        do {
            let (data, response) = try await session.data(for: assetDownloadRequest(url: url))
            guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                appendSyncLog("VERSION.txt HTTP \(code)")
                return nil
            }
            guard let text = String(data: data, encoding: .utf8),
                  let manifest = LiveChannelManifest.parse(text) else {
                return nil
            }
            return manifest
        } catch {
            appendSyncLog("VERSION.txt fetch failed: \(error.localizedDescription)")
            return nil
        }
    }

    private func headAssetByteCount(url: URL) async -> Int? {
        do {
            let (_, response) = try await session.data(for: headAssetRequest(url: url))
            guard let http = response as? HTTPURLResponse, (200 ... 399).contains(http.statusCode) else {
                return nil
            }
            if let length = http.value(forHTTPHeaderField: "Content-Length"), let bytes = Int(length) {
                return bytes
            }
            return nil
        } catch {
            appendSyncLog("HEAD asset skipped: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Optional API fallback (never surfaces to UI)

    private func githubRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Publshr/1.0", forHTTPHeaderField: "User-Agent")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        return request
    }

    private func checkVersionedFallbackSilently() async -> AvailableUpdate? {
        do {
            let releases = try await fetchRecentReleases()
            let localBuild = AppReleaseConfig.buildNumber
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
                appendSyncLog("fallback versioned update build=\(best.build)")
            }
            return best
        } catch {
            appendSyncLog("versioned fallback skipped: \(error.localizedDescription)")
            return nil
        }
    }

    private func fetchRecentReleases() async throws -> [GitHubRelease] {
        guard let url = AppReleaseConfig.releasesURL() else {
            throw AppUpdateError.invalidRepo
        }
        let (data, response) = try await session.data(for: githubRequest(url: url))
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw AppUpdateError.downloadFailed
        }
        return try decoder.decode([GitHubRelease].self, from: data)
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

    func recordAppliedLiveManifest(_ update: AvailableUpdate) {
        UserDefaults.standard.set(update.version, forKey: "publshr.appliedLiveVersion")
        UserDefaults.standard.set(update.build, forKey: "publshr.appliedLiveBuild")
        if let digest = update.packageDigest, !digest.isEmpty {
            UserDefaults.standard.set(digest, forKey: "publshr.appliedLiveDigest")
        }
    }
}
