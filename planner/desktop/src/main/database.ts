import Database from 'better-sqlite3'
import { existsSync, mkdirSync } from 'fs'
import { join } from 'path'

let db: Database.Database | null = null

const SCHEMA = `
CREATE TABLE IF NOT EXISTS sync_queue (
  id TEXT PRIMARY KEY,
  table_name TEXT NOT NULL,
  record_id TEXT NOT NULL,
  operation TEXT NOT NULL,
  payload TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  attempts INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS planner_items_cache (
  id TEXT PRIMARY KEY,
  workspace_id TEXT NOT NULL,
  payload TEXT NOT NULL,
  updated_at INTEGER NOT NULL,
  sync_status TEXT DEFAULT 'synced'
);

CREATE TABLE IF NOT EXISTS editor_drafts_cache (
  id TEXT PRIMARY KEY,
  planner_item_id TEXT,
  payload TEXT NOT NULL,
  updated_at INTEGER NOT NULL,
  sync_status TEXT DEFAULT 'pending'
);

CREATE TABLE IF NOT EXISTS workspaces_cache (
  id TEXT PRIMARY KEY,
  payload TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS user_preferences (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS search_index (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  subtitle TEXT,
  workspace_id TEXT,
  payload TEXT,
  updated_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_planner_items_workspace ON planner_items_cache(workspace_id);
CREATE INDEX IF NOT EXISTS idx_sync_queue_created ON sync_queue(created_at);
`

export function initDatabase(userDataPath: string): Database.Database {
  const dir = join(userDataPath, 'planner-cache')
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true })
  const dbPath = join(dir, 'planner.db')
  db = new Database(dbPath)
  db.pragma('journal_mode = WAL')
  db.exec(SCHEMA)
  return db
}

export function getDb(): Database.Database {
  if (!db) throw new Error('Database not initialized')
  return db
}

export function closeDatabase(): void {
  db?.close()
  db = null
}
