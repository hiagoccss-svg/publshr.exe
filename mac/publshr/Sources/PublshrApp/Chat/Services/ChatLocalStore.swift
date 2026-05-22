import Foundation
import SQLite3

/// Local-first SQLite cache for chat: messages, channels, drafts, unread counts, presence.
final class ChatLocalStore {
    private var db: OpaquePointer?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
        openDatabase()
        migrate()
    }

    deinit {
        if db != nil { sqlite3_close(db) }
    }

    private func openDatabase() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Publshr", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let path = dir.appendingPathComponent("chat-cache.sqlite").path
        if sqlite3_open(path, &db) != SQLITE_OK {
            db = nil
        }
    }

    private func migrate() {
        exec("""
        CREATE TABLE IF NOT EXISTS channels (
            id TEXT PRIMARY KEY,
            workspace_id TEXT NOT NULL,
            payload TEXT NOT NULL,
            updated_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS messages (
            id TEXT PRIMARY KEY,
            channel_id TEXT NOT NULL,
            workspace_id TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at REAL NOT NULL
        );
        CREATE INDEX IF NOT EXISTS messages_channel_idx ON messages(channel_id, created_at);
        CREATE TABLE IF NOT EXISTS drafts (
            channel_id TEXT PRIMARY KEY,
            body TEXT NOT NULL,
            updated_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS unread (
            channel_id TEXT PRIMARY KEY,
            count INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE IF NOT EXISTS presence (
            user_id TEXT PRIMARY KEY,
            workspace_id TEXT NOT NULL,
            payload TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS meta (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS search_index (
            message_id TEXT PRIMARY KEY,
            channel_id TEXT NOT NULL,
            channel_name TEXT NOT NULL,
            snippet TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS scheduled_local (
            id TEXT PRIMARY KEY,
            workspace_id TEXT NOT NULL,
            channel_id TEXT NOT NULL,
            user_id TEXT NOT NULL,
            body TEXT NOT NULL,
            thread_parent_id TEXT,
            send_at REAL NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending'
        );
        """)
    }

    struct LocalSearchRow {
        let messageId: String
        let channelId: UUID
        let channelName: String
        let snippet: String
    }

    func indexMessageForSearch(messageId: UUID, channelId: UUID, channelName: String, body: String) {
        let snippet = String(body.prefix(200))
        exec(
            "INSERT OR REPLACE INTO search_index (message_id, channel_id, channel_name, snippet) VALUES (?, ?, ?, ?);",
            messageId.uuidString, channelId.uuidString, channelName, snippet
        )
    }

    func searchMessages(query searchQuery: String) -> [LocalSearchRow] {
        let q = "%\(searchQuery.lowercased())%"
        return fetchRows("SELECT message_id, channel_id, channel_name, snippet FROM search_index WHERE LOWER(snippet) LIKE ? LIMIT 50;", q)
            .compactMap { row -> LocalSearchRow? in
                guard let mid = row["message_id"],
                      let cid = row["channel_id"], let uuid = UUID(uuidString: cid),
                      let name = row["channel_name"], let snippet = row["snippet"] else { return nil }
                return LocalSearchRow(messageId: mid, channelId: uuid, channelName: name, snippet: snippet)
            }
    }

    func cacheChannels(_ channels: [ChatChannel]) {
        for ch in channels {
            guard let json = encode(ch) else { continue }
            exec(
                "INSERT OR REPLACE INTO channels (id, workspace_id, payload, updated_at) VALUES (?, ?, ?, ?);",
                ch.id.uuidString, ch.workspaceId.uuidString, json, String(ch.updatedAt.timeIntervalSince1970)
            )
        }
    }

    func loadChannels(workspaceId: UUID) -> [ChatChannel] {
        let rows = fetchRows(
            "SELECT payload FROM channels WHERE workspace_id = ? ORDER BY updated_at DESC;",
            workspaceId.uuidString
        )
        return rows.compactMap { decode(ChatChannel.self, from: $0["payload"]) }
    }

    func cacheMessages(_ messages: [ChatMessage], channelId: UUID, channelName: String = "") {
        for msg in messages {
            guard let json = encode(msg) else { continue }
            exec(
                """
                INSERT OR REPLACE INTO messages (id, channel_id, workspace_id, payload, created_at)
                VALUES (?, ?, ?, ?, ?);
                """,
                msg.id.uuidString, channelId.uuidString, msg.workspaceId.uuidString, json, String(msg.createdAt.timeIntervalSince1970)
            )
            if let body = msg.body, !body.isEmpty {
                indexMessageForSearch(
                    messageId: msg.id,
                    channelId: channelId,
                    channelName: channelName.isEmpty ? channelId.uuidString : channelName,
                    body: body
                )
            }
        }
    }

    func loadMessages(channelId: UUID, limit: Int = 200) -> [ChatMessage] {
        let rows = fetchRows(
            """
            SELECT payload FROM messages WHERE channel_id = ?
            ORDER BY created_at DESC LIMIT ?;
            """,
            channelId.uuidString, String(limit)
        )
        let decoded = rows.compactMap { decode(ChatMessage.self, from: $0["payload"]) }
        return decoded.sorted { $0.createdAt < $1.createdAt }
    }

    func loadMessagesInPeriod(channelId: UUID, from start: Date, to end: Date) -> [ChatMessage] {
        let calendar = Calendar.current
        let rangeStart = calendar.startOfDay(for: start).timeIntervalSince1970
        let rangeEnd = (calendar.date(bySettingHour: 23, minute: 59, second: 59, of: end) ?? end).timeIntervalSince1970
        let rows = fetchRows(
            """
            SELECT payload FROM messages
            WHERE channel_id = ? AND created_at >= ? AND created_at <= ?
            ORDER BY created_at ASC;
            """,
            channelId.uuidString, String(rangeStart), String(rangeEnd)
        )
        return rows.compactMap { decode(ChatMessage.self, from: $0["payload"]) }
    }

    func upsertMessage(_ message: ChatMessage) {
        guard let json = encode(message) else { return }
        exec(
            """
            INSERT OR REPLACE INTO messages (id, channel_id, workspace_id, payload, created_at)
            VALUES (?, ?, ?, ?, ?);
            """,
            message.id.uuidString, message.channelId.uuidString, message.workspaceId.uuidString,
            json, String(message.createdAt.timeIntervalSince1970)
        )
    }

    func saveDraft(_ draft: ChatDraft) {
        exec(
            "INSERT OR REPLACE INTO drafts (channel_id, body, updated_at) VALUES (?, ?, ?);",
            draft.channelId.uuidString, draft.body, String(draft.updatedAt.timeIntervalSince1970)
        )
    }

    func loadDraft(channelId: UUID) -> ChatDraft? {
        let rows = fetchRows("SELECT body, updated_at FROM drafts WHERE channel_id = ?;", channelId.uuidString)
        guard let row = rows.first,
              let body = row["body"],
              let ts = Double(row["updated_at"] ?? "") else { return nil }
        return ChatDraft(channelId: channelId, body: body, updatedAt: Date(timeIntervalSince1970: ts))
    }

    func loadAllDrafts() -> [ChatDraft] {
        fetchRows("SELECT channel_id, body, updated_at FROM drafts WHERE TRIM(body) != '' ORDER BY updated_at DESC;")
            .compactMap { row -> ChatDraft? in
                guard let cid = row["channel_id"], let uuid = UUID(uuidString: cid),
                      let body = row["body"],
                      let ts = Double(row["updated_at"] ?? "") else { return nil }
                return ChatDraft(channelId: uuid, body: body, updatedAt: Date(timeIntervalSince1970: ts))
            }
    }

    func saveLocalScheduled(_ item: ChatScheduledMessage) {
        exec(
            """
            INSERT OR REPLACE INTO scheduled_local
            (id, workspace_id, channel_id, user_id, body, thread_parent_id, send_at, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?);
            """,
            item.id.uuidString,
            item.workspaceId.uuidString,
            item.channelId.uuidString,
            item.userId.uuidString,
            item.body,
            item.threadParentId?.uuidString ?? "",
            String(item.sendAt.timeIntervalSince1970),
            item.status
        )
    }

    func loadPendingLocalScheduled(workspaceId: UUID, userId: UUID) -> [ChatScheduledMessage] {
        fetchRows(
            """
            SELECT id, workspace_id, channel_id, user_id, body, thread_parent_id, send_at, status
            FROM scheduled_local
            WHERE workspace_id = ? AND user_id = ? AND status = 'pending'
            ORDER BY send_at ASC;
            """,
            workspaceId.uuidString,
            userId.uuidString
        ).compactMap { row -> ChatScheduledMessage? in
            guard let id = row["id"], let uuid = UUID(uuidString: id),
                  let ws = row["workspace_id"], let wsId = UUID(uuidString: ws),
                  let cid = row["channel_id"], let chId = UUID(uuidString: cid),
                  let uid = row["user_id"], let userUuid = UUID(uuidString: uid),
                  let body = row["body"],
                  let sendTs = Double(row["send_at"] ?? ""),
                  let status = row["status"] else { return nil }
            let parent: UUID? = {
                guard let raw = row["thread_parent_id"], !raw.isEmpty else { return nil }
                return UUID(uuidString: raw)
            }()
            return ChatScheduledMessage(
                id: uuid,
                workspaceId: wsId,
                channelId: chId,
                userId: userUuid,
                body: body,
                threadParentId: parent,
                sendAt: Date(timeIntervalSince1970: sendTs),
                status: status,
                createdAt: Date(timeIntervalSince1970: sendTs),
                updatedAt: Date(timeIntervalSince1970: sendTs)
            )
        }
    }

    func updateLocalScheduledStatus(id: UUID, status: String) {
        exec("UPDATE scheduled_local SET status = ? WHERE id = ?;", status, id.uuidString)
    }

    func deleteLocalScheduled(id: UUID) {
        exec("DELETE FROM scheduled_local WHERE id = ?;", id.uuidString)
    }

    func unreadCount(channelId: UUID) -> Int {
        Int(fetchRows("SELECT count FROM unread WHERE channel_id = ?;", channelId.uuidString).first?["count"] ?? "0") ?? 0
    }

    func setUnreadCount(channelId: UUID, count: Int) {
        exec("INSERT OR REPLACE INTO unread (channel_id, count) VALUES (?, ?);", channelId.uuidString, String(count))
    }

    func cachePresence(_ items: [ChatPresence]) {
        for p in items {
            guard let json = encode(p) else { continue }
            exec(
                "INSERT OR REPLACE INTO presence (user_id, workspace_id, payload) VALUES (?, ?, ?);",
                p.userId.uuidString, p.workspaceId.uuidString, json
            )
        }
    }

    func loadPresence(workspaceId: UUID) -> [ChatPresence] {
        fetchRows("SELECT payload FROM presence WHERE workspace_id = ?;", workspaceId.uuidString)
            .compactMap { decode(ChatPresence.self, from: $0["payload"]) }
    }

    func setMeta(_ key: String, value: String) {
        exec("INSERT OR REPLACE INTO meta (key, value) VALUES (?, ?);", key, value)
    }

    func meta(_ key: String) -> String? {
        fetchRows("SELECT value FROM meta WHERE key = ?;", key).first?["value"]
    }

    // MARK: - SQLite helpers

    private func exec(_ sql: String, _ args: String...) {
        guard let db else { return }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }
        for (i, arg) in args.enumerated() {
            sqlite3_bind_text(stmt, Int32(i + 1), arg, -1, SQLITE_TRANSIENT)
        }
        sqlite3_step(stmt)
    }

    private func fetchRows(_ sql: String, _ args: String...) -> [[String: String]] {
        guard let db else { return [] }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }
        for (i, arg) in args.enumerated() {
            sqlite3_bind_text(stmt, Int32(i + 1), arg, -1, SQLITE_TRANSIENT)
        }
        var rows: [[String: String]] = []
        let colCount = sqlite3_column_count(stmt)
        while sqlite3_step(stmt) == SQLITE_ROW {
            var row: [String: String] = [:]
            for i in 0..<colCount {
                let name = String(cString: sqlite3_column_name(stmt, i))
                if let cstr = sqlite3_column_text(stmt, i) {
                    row[name] = String(cString: cstr)
                }
            }
            rows.append(row)
        }
        return rows
    }

    private func encode<T: Encodable>(_ value: T) -> String? {
        guard let data = try? encoder.encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func decode<T: Decodable>(_ type: T.Type, from json: String?) -> T? {
        guard let json, let data = json.data(using: .utf8) else { return nil }
        return try? decoder.decode(type, from: data)
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
