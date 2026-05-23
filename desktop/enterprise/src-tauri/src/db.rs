use tauri_plugin_sql::{Migration, MigrationKind};

pub fn enterprise_migrations() -> Vec<Migration> {
    vec![Migration {
        version: 1,
        description: "enterprise_core_tables",
        sql: r#"
CREATE TABLE IF NOT EXISTS app_kv (
  key TEXT PRIMARY KEY NOT NULL,
  value TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS sync_queue (
  id TEXT PRIMARY KEY NOT NULL,
  table_name TEXT NOT NULL,
  record_id TEXT NOT NULL,
  operation TEXT NOT NULL,
  payload TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  attempts INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS window_states (
  label TEXT PRIMARY KEY NOT NULL,
  payload TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_sync_queue_created ON sync_queue(created_at);
"#,
        kind: MigrationKind::Up,
    }]
}
