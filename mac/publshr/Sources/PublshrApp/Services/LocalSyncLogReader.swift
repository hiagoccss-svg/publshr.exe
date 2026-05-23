import Foundation

/// Reads recent GitHub live / install log lines for Settings and background sync decisions.
enum LocalSyncLogReader {
    private static let maxLines = 14
    private static let maxChars = 2_400

    struct Summary: Sendable {
        let excerpt: String
        let suggestsAppUpdate: Bool
        let suggestsInstallInProgress: Bool
        let suggestsFailure: Bool
    }

    static func summarize() -> Summary {
        let syncLines = tailLines(at: LocalDataLayout.lastSyncLog)
        let updateLines = tailLines(at: LocalDataLayout.lastUpdateLog)
        let combined = (syncLines + updateLines).suffix(maxLines)
        let excerpt = combined.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        let clipped = String(excerpt.prefix(maxChars))
        let lower = clipped.lowercased()
        let suggestsAppUpdate = lower.contains("update available")
            || lower.contains("downloading")
            || lower.contains("ready to install")
            || lower.contains("new build")
        let suggestsInstallInProgress = lower.contains("installing to")
            || lower.contains("update installed")
            || lower.contains("waiting for pid")
        let suggestsFailure = lower.contains("rollback")
            || lower.contains("error:")
            || lower.contains("failed")
            || lower.contains("sync: ")
        return Summary(
            excerpt: clipped.isEmpty ? "No sync logs yet." : clipped,
            suggestsAppUpdate: suggestsAppUpdate,
            suggestsInstallInProgress: suggestsInstallInProgress,
            suggestsFailure: suggestsFailure
        )
    }

    private static func tailLines(at url: URL) -> [String] {
        guard let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .utf8),
              !text.isEmpty else {
            return []
        }
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { String($0).trimmingCharacters(in: .newlines) }
            .filter { !$0.isEmpty }
            .suffix(maxLines)
            .map { String($0) }
    }
}
