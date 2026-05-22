import Foundation

struct GitHubRelease: Decodable, Sendable {
    let tagName: String
    let htmlURL: String
    let publishedAt: String
    let assets: [GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case publishedAt = "published_at"
        case assets
    }
}

struct GitHubAsset: Decodable, Sendable {
    let name: String
    let browserDownloadURL: String
    let size: Int

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
        case size
    }
}

struct AvailableUpdate: Sendable {
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

    var errorDescription: String? {
        switch self {
        case .invalidRepo: return "Invalid GitHub repository configuration."
        case .noReleases: return "No published releases found on GitHub."
        case .noCompatibleAsset: return "No macOS build is available for this Mac."
        case .downloadFailed(let detail): return "Download failed: \(detail)"
        case .extractFailed: return "Could not extract the update package."
        case .applyScriptMissing: return "Update helper script is missing from the app bundle."
        }
    }
}

/// Checks GitHub Releases and installs updates into /Applications/Publshr.app.
final class AppUpdateService: @unchecked Sendable {
    static let shared = AppUpdateService()

    private let session: URLSession
    private let fileManager = FileManager.default

    init(session: URLSession = .shared) {
        self.session = session
    }

    func checkForUpdate() async throws -> AvailableUpdate? {
        guard let url = AppReleaseConfig.releasesURL() else {
            throw AppUpdateError.invalidRepo
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Publshr/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw AppUpdateError.downloadFailed("GitHub API HTTP \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        }

        let releases = try JSONDecoder().decode([GitHubRelease].self, from: data)
        let localBuild = AppReleaseConfig.buildNumber
        var best: AvailableUpdate?

        for release in releases {
            guard let candidate = parseRelease(release) else { continue }
            if candidate.build <= localBuild { continue }
            if let current = best {
                if candidate.build > current.build {
                    best = candidate
                }
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

        let (tempURL, response) = try await session.download(from: update.downloadURL)
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

        let entries = try fileManager.contentsOfDirectory(at: staging, includingPropertiesForKeys: nil)
        if let tree = entries.first(where: { $0.lastPathComponent.hasPrefix("publshr-") }) {
            return tree
        }
        if entries.contains(where: { $0.lastPathComponent == "Publshr.app" }) {
            return staging
        }
        throw AppUpdateError.extractFailed
    }

    func applyUpdate(treeURL: URL, parentPID: Int32) throws {
        guard let script = Bundle.main.url(forResource: "apply-macos-update", withExtension: "sh") else {
            throw AppUpdateError.applyScriptMissing
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

    private func parseRelease(_ release: GitHubRelease) -> AvailableUpdate? {
        let tag = release.tagName
        let trimmed = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
        let parts = trimmed.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count >= 2, let build = Int(parts.last ?? "") else { return nil }

        let version = trimmed
        let assetName = AppReleaseConfig.platformAssetName(version: version)
        guard let asset = release.assets.first(where: { $0.name == assetName }),
              let downloadURL = URL(string: asset.browserDownloadURL),
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
