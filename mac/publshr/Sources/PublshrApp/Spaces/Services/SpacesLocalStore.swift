import Foundation
import SQLite3

/// Local-first SQLite cache for Spaces — offline read, fast search, resilient sync.
final class SpacesLocalStore {
    private var db: OpaquePointer?
    private let encoder = JSONEncoder()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    init() {
        encoder.dateEncodingStrategy = .iso8601
        openDatabase()
        migrate()
    }

    deinit {
        if db != nil { sqlite3_close(db) }
    }

    private func openDatabase() {
        LocalDataLayout.ensureRootExists()
        let path = LocalDataLayout.spacesDatabase.path
        if sqlite3_open(path, &db) != SQLITE_OK {
            db = nil
        }
        LocalDataLayout.configureSQLitePerformance(db)
    }

    private func migrate() {
        exec("""
        CREATE TABLE IF NOT EXISTS spaces (
            id TEXT PRIMARY KEY,
            workspace_id TEXT NOT NULL,
            payload TEXT NOT NULL,
            updated_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS tasks (
            id TEXT PRIMARY KEY,
            space_id TEXT NOT NULL,
            payload TEXT NOT NULL,
            updated_at REAL NOT NULL
        );
        CREATE INDEX IF NOT EXISTS tasks_space_idx ON tasks(space_id);
        CREATE TABLE IF NOT EXISTS meta (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
        );
        """)
    }

    func setMeta(_ key: String, value: String) {
        exec(
            "INSERT OR REPLACE INTO meta (key, value) VALUES (?, ?);",
            bind: { stmt in
                sqlite3_bind_text(stmt, 1, key, -1, nil)
                sqlite3_bind_text(stmt, 2, value, -1, nil)
            }
        )
    }

    func meta(_ key: String) -> String? {
        querySingleString("SELECT value FROM meta WHERE key = ? LIMIT 1;", key: key)
    }

    func saveSpaces(_ spaces: [SpaceRecord], workspaceId: UUID) {
        setMeta("last_workspace_id", value: workspaceId.uuidString)
        for space in spaces {
            guard let data = try? encoder.encode(space),
                  let json = String(data: data, encoding: .utf8) else { continue }
            exec(
                "INSERT OR REPLACE INTO spaces (id, workspace_id, payload, updated_at) VALUES (?, ?, ?, ?);",
                bind: { stmt in
                    sqlite3_bind_text(stmt, 1, space.id.uuidString, -1, nil)
                    sqlite3_bind_text(stmt, 2, workspaceId.uuidString, -1, nil)
                    sqlite3_bind_text(stmt, 3, json, -1, nil)
                    sqlite3_bind_double(stmt, 4, Date().timeIntervalSince1970)
                }
            )
        }
    }

    func loadSpaces(workspaceId: UUID) -> [SpaceRecord] {
        loadPayloads(
            sql: "SELECT payload FROM spaces WHERE workspace_id = ? ORDER BY payload;",
            bind: { stmt in sqlite3_bind_text(stmt, 1, workspaceId.uuidString, -1, nil) }
        )
    }

    func saveTasks(_ tasks: [SpaceTaskRecord], spaceId: UUID) {
        for task in tasks {
            guard let data = try? encoder.encode(task),
                  let json = String(data: data, encoding: .utf8) else { continue }
            exec(
                "INSERT OR REPLACE INTO tasks (id, space_id, payload, updated_at) VALUES (?, ?, ?, ?);",
                bind: { stmt in
                    sqlite3_bind_text(stmt, 1, task.id.uuidString, -1, nil)
                    sqlite3_bind_text(stmt, 2, spaceId.uuidString, -1, nil)
                    sqlite3_bind_text(stmt, 3, json, -1, nil)
                    sqlite3_bind_double(stmt, 4, Date().timeIntervalSince1970)
                }
            )
        }
    }

    func loadTasks(spaceId: UUID) -> [SpaceTaskRecord] {
        loadPayloads(
            sql: "SELECT payload FROM tasks WHERE space_id = ?;",
            bind: { stmt in sqlite3_bind_text(stmt, 1, spaceId.uuidString, -1, nil) }
        )
    }

    func upsertTask(_ task: SpaceTaskRecord) {
        saveTasks([task], spaceId: task.spaceId)
    }

    func removeTask(id: UUID) {
        exec(
            "DELETE FROM tasks WHERE id = ?;",
            bind: { stmt in sqlite3_bind_text(stmt, 1, id.uuidString, -1, nil) }
        )
    }

    private func loadPayloads<T: Decodable>(
        sql: String,
        bind: (OpaquePointer?) -> Void
    ) -> [T] {
        guard let db else { return [] }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else { return [] }
        defer { sqlite3_finalize(stmt) }
        bind(stmt)
        var rows: [T] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let cString = sqlite3_column_text(stmt, 0) else { continue }
            let json = String(cString: cString)
            guard let data = json.data(using: .utf8),
                  let row = try? decoder.decode(T.self, from: data) else { continue }
            rows.append(row)
        }
        return rows
    }

    private func querySingleString(_ sql: String, key: String) -> String? {
        guard let db else { return nil }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else { return nil }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, key, -1, nil)
        guard sqlite3_step(stmt) == SQLITE_ROW,
              let cString = sqlite3_column_text(stmt, 0) else { return nil }
        return String(cString: cString)
    }

    private func exec(_ sql: String, bind: ((OpaquePointer?) -> Void)? = nil) {
        guard let db else { return }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else { return }
        defer { sqlite3_finalize(stmt) }
        bind?(stmt)
        sqlite3_step(stmt)
    }
}
