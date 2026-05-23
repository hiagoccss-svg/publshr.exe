import Foundation
import SQLite3

/// Single source of truth for on-disk layout under `~/Library/Application Support/Publshr/`.
/// GitHub ships the app binary; Supabase is cloud truth; this folder is the Mac cache + offline layer.
enum LocalDataLayout {
    static let rootFolderName = "Publshr"

    static var applicationSupportRoot: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent(rootFolderName, isDirectory: true)
    }

    static func ensureRootExists() {
        try? FileManager.default.createDirectory(at: applicationSupportRoot, withIntermediateDirectories: true)
    }

    // MARK: - SQLite (offline read, fast UI)

    static var chatDatabase: URL {
        applicationSupportRoot.appendingPathComponent("chat-cache.sqlite")
    }

    static var spacesDatabase: URL {
        applicationSupportRoot.appendingPathComponent("spaces-cache.sqlite")
    }

    // MARK: - Auth offline layer (not Keychain)

    static var authOfflineSnapshot: URL {
        applicationSupportRoot.appendingPathComponent("auth-offline-snapshot.json")
    }

    // MARK: - GitHub live channel (app shell only)

    static var updatesDirectory: URL {
        applicationSupportRoot.appendingPathComponent("updates", isDirectory: true)
    }

    static var lastUpdateLog: URL {
        updatesDirectory.appendingPathComponent("last-update.log")
    }

    static var lastSyncLog: URL {
        updatesDirectory.appendingPathComponent("last-sync.log")
    }

    // MARK: - Attachments & diagnostics

    static var voiceNotesDirectory: URL {
        applicationSupportRoot.appendingPathComponent("voice-notes", isDirectory: true)
    }

    static var crashesDirectory: URL {
        applicationSupportRoot.appendingPathComponent("crashes", isDirectory: true)
    }

    static var installSourceMarker: URL {
        applicationSupportRoot.appendingPathComponent("install-source.tree")
    }

    /// Applies SQLite pragmas for WAL + reasonable durability (enterprise cache tier).
    static func configureSQLitePerformance(_ db: OpaquePointer?) {
        guard let db else { return }
        sqlite3_exec(db, "PRAGMA journal_mode=WAL;", nil, nil, nil)
        sqlite3_exec(db, "PRAGMA synchronous=NORMAL;", nil, nil, nil)
        sqlite3_exec(db, "PRAGMA temp_store=MEMORY;", nil, nil, nil)
        sqlite3_exec(db, "PRAGMA mmap_size=268435456;", nil, nil, nil)
    }
}
