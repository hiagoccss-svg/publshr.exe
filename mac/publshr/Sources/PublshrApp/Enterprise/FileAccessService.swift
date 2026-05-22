import Foundation
import AppKit
import UniformTypeIdentifiers

/// Native file access with security-scoped bookmarks for uploads (Chat + Spaces).
@MainActor
enum FileAccessService {
    static func pickFiles(allowedTypes: [UTType] = [.item], allowsMultiple: Bool = false) -> [URL] {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = allowsMultiple
        panel.allowedContentTypes = allowedTypes
        panel.message = "Select files to upload to your workspace"
        guard panel.runModal() == .OK else { return [] }
        return panel.urls
    }

    static func pickFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a folder Publshr can access for exports"
        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }

    /// Read file bytes with security-scoped access when required.
    static func readData(from url: URL) throws -> Data {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed { url.stopAccessingSecurityScopedResource() }
        }
        return try Data(contentsOf: url)
    }

    static func saveBookmark(for url: URL, key: String) {
        do {
            let data = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(data, forKey: "com.publshr.bookmark.\(key)")
        } catch {
            NSLog("Publshr bookmark save failed: \(error)")
        }
    }

    static func resolveBookmark(key: String) -> URL? {
        guard let data = UserDefaults.standard.data(forKey: "com.publshr.bookmark.\(key)") else { return nil }
        var stale = false
        return try? URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &stale
        )
    }

    static var downloadsDirectory: URL {
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
    }

    static func exportText(_ content: String, suggestedName: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = suggestedName
        panel.allowedContentTypes = [.plainText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? content.write(to: url, atomically: true, encoding: .utf8)
    }
}
