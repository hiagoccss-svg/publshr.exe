import Foundation

public struct SyncResult: Sendable {
    public let message: String
    public let commit: String?
    public let updated: Bool
}

public enum GitSyncError: Error, LocalizedError {
    case gitMissing
    case commandFailed(String)

    public var errorDescription: String? {
        switch self {
        case .gitMissing:
            return "git is not installed. Install Xcode Command Line Tools: xcode-select --install"
        case .commandFailed(let detail):
            return detail
        }
    }
}

public struct GitSync: Sendable {
    public let branch: String

    public init(branch: String = AppConfig.defaultBranch) {
        self.branch = branch
    }

    public func sync(offline: Bool) async -> Result<SyncResult, Error> {
        if offline {
            return .success(SyncResult(
                message: "Offline — using installed app. Last synced copy stays in Application Support.",
                commit: try? await currentCommit(),
                updated: false
            ))
        }

        do {
            try FileManager.default.createDirectory(at: AppConfig.supportDirectory, withIntermediateDirectories: true)

            if !FileManager.default.fileExists(atPath: AppConfig.cloneDirectory.path) {
                try await runGit(["clone", "--branch", branch, "--depth", "1", AppConfig.repoHTTPS, AppConfig.cloneDirectory.path])
                let commit = try await currentCommit()
                return .success(SyncResult(
                    message: "Downloaded project from GitHub.",
                    commit: commit,
                    updated: true
                ))
            }

            try await runGit(["-C", AppConfig.cloneDirectory.path, "fetch", "origin", branch])
            try await runGit(["-C", AppConfig.cloneDirectory.path, "reset", "--hard", "origin/\(branch)"])
            let commit = try await currentCommit()
            return .success(SyncResult(
                message: "Synced with GitHub (\(branch)).",
                commit: commit,
                updated: true
            ))
        } catch {
            return .failure(error)
        }
    }

    private func currentCommit() async throws -> String? {
        let output = try await runGitCapture(["-C", AppConfig.cloneDirectory.path, "rev-parse", "--short", "HEAD"])
        return output.isEmpty ? nil : output
    }

    private func runGit(_ args: [String]) async throws {
        _ = try await runGitCapture(args)
    }

    private func runGitCapture(_ args: [String]) async throws -> String {
        try await Task.detached {
            guard FileManager.default.fileExists(atPath: "/usr/bin/git") else {
                throw GitSyncError.gitMissing
            }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            process.arguments = args

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            guard process.terminationStatus == 0 else {
                throw GitSyncError.commandFailed(text.isEmpty ? "git failed" : text)
            }
            return text
        }.value
    }
}
