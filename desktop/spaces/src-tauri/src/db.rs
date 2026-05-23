use crate::models::{
    load_meta, Approval, BootstrapPayload, CreateCommentInput, CreateSpaceInput, CreateTaskInput,
    NotificationItem, SearchResult, Space, SpaceActivity, SpaceComment, SpaceDocument,
    SpaceDocumentDetail, SpaceFile, SpaceFolder, SpaceList, SpaceMember, SyncQueueItem,
    SyncStatus, Task, UpdateDocumentPatch, UpdateFolderPatch, UpdateListPatch, UpdateSpacePatch,
    UpdateTaskInput, Workspace, WorkspaceActivity, WorkspaceMember, WorkspaceSummary,
    WorkspaceTask,
};
use rusqlite::{params, Connection, Row};
use serde::de::DeserializeOwned;
use std::path::Path;
use thiserror::Error;
use uuid::Uuid;

const SCHEMA_SQL: &str = include_str!("../resources/schema.sql");

#[derive(Debug, Error)]
pub enum DbError {
    #[error("SQLite error: {0}")]
    Sqlite(#[from] rusqlite::Error),
    #[error("JSON error: {0}")]
    Json(#[from] serde_json::Error),
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    #[error("{0}")]
    Message(String),
}

pub type DbResult<T> = Result<T, DbError>;

pub struct SpacesDatabase {
    conn: Connection,
    sync_status: SyncStatus,
}

fn now_iso() -> String {
    chrono::Utc::now()
        .to_rfc3339_opts(chrono::SecondsFormat::Millis, true)
}

fn new_uuid() -> String {
    Uuid::new_v4().to_string()
}

fn parse_json<T: DeserializeOwned>(raw: &str, fallback: T) -> T {
    serde_json::from_str(raw).unwrap_or(fallback)
}

fn opt_str(value: Option<String>) -> Option<String> {
    value.filter(|s| !s.is_empty())
}

fn row_bool(row: &Row, col: &str) -> rusqlite::Result<bool> {
    Ok(row.get::<_, i32>(col)? != 0)
}

fn row_to_space(row: &Row) -> rusqlite::Result<Space> {
    Ok(Space {
        id: row.get("id")?,
        workspace_id: row.get("workspace_id")?,
        name: row.get("name")?,
        description: row.get("description")?,
        space_type: row.get("type")?,
        status: row.get("status")?,
        owner_id: row.get("owner_id")?,
        color: row.get("color")?,
        is_pinned: row_bool(row, "is_pinned")?,
        is_favourite: row_bool(row, "is_favourite")?,
        is_archived: row_bool(row, "is_archived")?,
        client_mode: row_bool(row, "client_mode")?,
        updated_at: row.get("updated_at")?,
        created_at: row.get("created_at")?,
    })
}

fn row_to_folder(row: &Row) -> rusqlite::Result<SpaceFolder> {
    Ok(SpaceFolder {
        id: row.get("id")?,
        space_id: row.get("space_id")?,
        name: row.get("name")?,
        sort_order: row.get("sort_order")?,
        is_archived: row_bool(row, "is_archived")?,
        updated_at: row.get("updated_at")?,
    })
}

fn row_to_list(row: &Row) -> rusqlite::Result<SpaceList> {
    Ok(SpaceList {
        id: row.get("id")?,
        space_id: row.get("space_id")?,
        folder_id: opt_str(row.get("folder_id")?),
        name: row.get("name")?,
        sort_order: row.get("sort_order")?,
        is_archived: row_bool(row, "is_archived")?,
        updated_at: row.get("updated_at")?,
    })
}

fn row_to_task(row: &Row) -> rusqlite::Result<Task> {
    let tags_raw: String = row.get("tags")?;
    let checklist_raw: String = row.get("checklist")?;
    let linked_raw: String = row.get("linked_doc_ids")?;
    Ok(Task {
        id: row.get("id")?,
        space_id: row.get("space_id")?,
        list_id: opt_str(row.get("list_id")?),
        title: row.get("title")?,
        description: row.get("description")?,
        status: row.get("status")?,
        priority: row.get("priority")?,
        assignee_id: opt_str(row.get("assignee_id")?),
        start_date: opt_str(row.get("start_date")?),
        due_date: opt_str(row.get("due_date")?),
        tags: parse_json(&tags_raw, Vec::new()),
        parent_task_id: opt_str(row.get("parent_task_id")?),
        checklist: parse_json(&checklist_raw, Vec::new()),
        comment_count: row.get("comment_count")?,
        attachment_count: row.get("attachment_count")?,
        linked_doc_ids: parse_json(&linked_raw, Vec::new()),
        order: row.get("sort_order")?,
        updated_at: row.get("updated_at")?,
        created_at: row.get("created_at")?,
    })
}

fn row_to_document(row: &Row, space_name: Option<String>) -> rusqlite::Result<SpaceDocument> {
    Ok(SpaceDocument {
        id: row.get("id")?,
        space_id: row.get("space_id")?,
        title: row.get("title")?,
        doc_type: row.get("doc_type")?,
        updated_at: row.get("updated_at")?,
        space_name,
    })
}

impl SpacesDatabase {
    pub fn open(path: &Path) -> DbResult<Self> {
        if let Some(parent) = path.parent() {
            std::fs::create_dir_all(parent)?;
        }
        let conn = Connection::open(path)?;
        conn.execute_batch(SCHEMA_SQL)?;
        let mut db = Self {
            conn,
            sync_status: "online".to_string(),
        };
        db.run_migrations()?;
        db.ensure_seed()?;
        Ok(db)
    }

    fn run_migrations(&mut self) -> DbResult<()> {
        let version_row: Option<String> = self
            .conn
            .query_row(
                "SELECT value FROM meta WHERE key = 'schema_version'",
                [],
                |row| row.get(0),
            )
            .ok();
        let version: i64 = version_row
            .as_deref()
            .and_then(|v| v.parse().ok())
            .unwrap_or(0);

        if version < 2 {
            let task_cols: Vec<String> = self
                .conn
                .prepare("PRAGMA table_info(tasks)")?
                .query_map([], |row| row.get(1))?
                .collect::<Result<Vec<_>, _>>()?;
            if !task_cols.iter().any(|c| c == "list_id") {
                self.conn.execute(
                    "ALTER TABLE tasks ADD COLUMN list_id TEXT REFERENCES space_lists(id) ON DELETE SET NULL",
                    [],
                )?;
            }
            self.conn.execute_batch(
                "
                CREATE TABLE IF NOT EXISTS space_folders (
                  id TEXT PRIMARY KEY,
                  space_id TEXT NOT NULL REFERENCES spaces(id) ON DELETE CASCADE,
                  name TEXT NOT NULL,
                  sort_order REAL NOT NULL DEFAULT 0,
                  is_archived INTEGER NOT NULL DEFAULT 0,
                  updated_at TEXT NOT NULL,
                  sync_pending INTEGER NOT NULL DEFAULT 0
                );
                CREATE TABLE IF NOT EXISTS space_lists (
                  id TEXT PRIMARY KEY,
                  space_id TEXT NOT NULL REFERENCES spaces(id) ON DELETE CASCADE,
                  folder_id TEXT REFERENCES space_folders(id) ON DELETE SET NULL,
                  name TEXT NOT NULL,
                  sort_order REAL NOT NULL DEFAULT 0,
                  is_archived INTEGER NOT NULL DEFAULT 0,
                  updated_at TEXT NOT NULL,
                  sync_pending INTEGER NOT NULL DEFAULT 0
                );
                CREATE INDEX IF NOT EXISTS idx_tasks_list ON tasks(list_id);
                CREATE INDEX IF NOT EXISTS idx_folders_space ON space_folders(space_id);
                CREATE INDEX IF NOT EXISTS idx_lists_space ON space_lists(space_id);
                ",
            )?;
            self.ensure_default_lists_for_existing_spaces()?;
            self.conn.execute(
                "INSERT INTO meta (key, value) VALUES ('schema_version', '2')
                 ON CONFLICT(key) DO UPDATE SET value = excluded.value",
                [],
            )?;
        }
        Ok(())
    }

    fn ensure_default_lists_for_existing_spaces(&self) -> DbResult<()> {
        let mut stmt = self
            .conn
            .prepare("SELECT id FROM spaces WHERE is_archived = 0")?;
        let space_ids = stmt
            .query_map([], |row| row.get::<_, String>(0))?
            .collect::<Result<Vec<_>, _>>()?;
        for space_id in space_ids {
            let count: i64 = self.conn.query_row(
                "SELECT COUNT(*) FROM space_lists WHERE space_id = ?1 AND is_archived = 0",
                params![space_id],
                |row| row.get(0),
            )?;
            if count == 0 {
                self.create_list(&space_id, "List", None)?;
            }
        }
        Ok(())
    }

    fn ensure_seed(&self) -> DbResult<()> {
        let count: i64 = self
            .conn
            .query_row("SELECT COUNT(*) FROM spaces", [], |row| row.get(0))?;
        if count > 0 {
            return Ok(());
        }

        let workspace_id = new_uuid();
        let user_id = new_uuid();
        let ts = now_iso();

        self.conn.execute(
            "INSERT INTO workspaces (id, name, updated_at) VALUES (?1, ?2, ?3)",
            params![workspace_id, "Publshr Workspace", ts],
        )?;
        self.conn.execute(
            "INSERT INTO meta (key, value) VALUES (?1, ?2), (?3, ?4)",
            params![
                "workspace_id",
                workspace_id,
                "current_user_id",
                user_id
            ],
        )?;
        self.conn.execute(
            "INSERT INTO meta (key, value) VALUES (?1, ?2)",
            params!["current_user_name", "You"],
        )?;
        Ok(())
    }

    pub fn set_sync_status(&mut self, status: SyncStatus) {
        self.sync_status = status;
    }

    pub fn get_sync_status(&self) -> SyncStatus {
        self.sync_status.clone()
    }

    pub fn get_bootstrap(&self) -> DbResult<BootstrapPayload> {
        let meta = load_meta(&self.conn)?;
        let workspace = self
            .conn
            .query_row("SELECT id, name, logo_url FROM workspaces LIMIT 1", [], |row| {
                Ok(Workspace {
                    id: row.get(0)?,
                    name: row.get(1)?,
                    logo_url: row.get(2)?,
                })
            })
            .unwrap_or_else(|_| Workspace {
                id: meta
                    .get("workspace_id")
                    .cloned()
                    .unwrap_or_else(new_uuid),
                name: "Publshr Workspace".to_string(),
                logo_url: None,
            });

        Ok(BootstrapPayload {
            workspace,
            spaces: self.list_spaces()?,
            current_user_id: meta
                .get("current_user_id")
                .cloned()
                .unwrap_or_else(new_uuid),
            current_user_name: meta
                .get("current_user_name")
                .cloned()
                .unwrap_or_else(|| "You".to_string()),
            sync_status: self.sync_status.clone(),
        })
    }

    pub fn list_spaces(&self) -> DbResult<Vec<Space>> {
        let mut stmt = self.conn.prepare(
            "SELECT * FROM spaces WHERE is_archived = 0
             ORDER BY is_pinned DESC, is_favourite DESC, updated_at DESC",
        )?;
        let rows = stmt.query_map([], row_to_space)?;
        rows.collect::<Result<Vec<_>, _>>().map_err(DbError::from)
    }

    pub fn get_space(&self, id: &str) -> DbResult<Option<Space>> {
        let mut stmt = self.conn.prepare("SELECT * FROM spaces WHERE id = ?1")?;
        let mut rows = stmt.query_map(params![id], row_to_space)?;
        Ok(rows.next().transpose()?)
    }

    pub fn create_space(&self, input: CreateSpaceInput) -> DbResult<Space> {
        let meta = load_meta(&self.conn)?;
        let id = new_uuid();
        let ts = now_iso();
        let space = Space {
            id: id.clone(),
            workspace_id: meta
                .get("workspace_id")
                .cloned()
                .unwrap_or_else(new_uuid),
            name: input.name,
            description: input.description.unwrap_or_default(),
            space_type: input.space_type.unwrap_or_else(|| "general".to_string()),
            status: "active".to_string(),
            owner_id: meta
                .get("current_user_id")
                .cloned()
                .unwrap_or_else(new_uuid),
            color: "#3d5a80".to_string(),
            is_pinned: false,
            is_favourite: false,
            is_archived: false,
            client_mode: false,
            updated_at: ts.clone(),
            created_at: ts,
        };

        self.conn.execute(
            "INSERT INTO spaces (
              id, workspace_id, name, description, type, status, owner_id, color,
              is_pinned, is_favourite, is_archived, client_mode, updated_at, created_at, sync_pending
            ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, 0, 0, 0, 0, ?9, ?10, 1)",
            params![
                space.id,
                space.workspace_id,
                space.name,
                space.description,
                space.space_type,
                space.status,
                space.owner_id,
                space.color,
                space.updated_at,
                space.created_at,
            ],
        )?;

        self.index_search("space", &space.id, Some(&space.id), &space.name, &space.description)?;
        self.log_activity(
            &space.id,
            &space.owner_id,
            "You",
            "created space",
            "space",
            &space.id,
        )?;
        self.enqueue_sync("spaces", &space.id, "insert", &space)?;
        self.create_list(&space.id, "List", None)?;
        Ok(space)
    }

    pub fn update_space(&self, id: &str, patch: UpdateSpacePatch) -> DbResult<Space> {
        let current = self
            .get_space(id)?
            .ok_or_else(|| DbError::Message("Space not found".into()))?;
        let next = Space {
            name: patch.name.unwrap_or(current.name),
            description: patch.description.unwrap_or(current.description),
            space_type: patch.space_type.unwrap_or(current.space_type),
            status: patch.status.unwrap_or(current.status),
            color: patch.color.unwrap_or(current.color),
            is_pinned: patch.is_pinned.unwrap_or(current.is_pinned),
            is_favourite: patch.is_favourite.unwrap_or(current.is_favourite),
            is_archived: patch.is_archived.unwrap_or(current.is_archived),
            client_mode: patch.client_mode.unwrap_or(current.client_mode),
            updated_at: now_iso(),
            ..current
        };

        self.conn.execute(
            "UPDATE spaces SET
              name = ?1, description = ?2, type = ?3, status = ?4, color = ?5,
              is_pinned = ?6, is_favourite = ?7, is_archived = ?8, client_mode = ?9,
              updated_at = ?10, sync_pending = 1
             WHERE id = ?11",
            params![
                next.name,
                next.description,
                next.space_type,
                next.status,
                next.color,
                next.is_pinned as i32,
                next.is_favourite as i32,
                next.is_archived as i32,
                next.client_mode as i32,
                next.updated_at,
                id,
            ],
        )?;
        self.enqueue_sync("spaces", id, "update", &next)?;
        Ok(next)
    }

    pub fn list_folders(&self, space_id: &str) -> DbResult<Vec<SpaceFolder>> {
        let mut stmt = self.conn.prepare(
            "SELECT * FROM space_folders WHERE space_id = ?1 AND is_archived = 0
             ORDER BY sort_order ASC, name ASC",
        )?;
        let rows = stmt.query_map(params![space_id], row_to_folder)?;
        rows.collect::<Result<Vec<_>, _>>().map_err(DbError::from)
    }

    pub fn create_folder(&self, space_id: &str, name: &str) -> DbResult<SpaceFolder> {
        let id = new_uuid();
        let ts = now_iso();
        let max_order: f64 = self.conn.query_row(
            "SELECT COALESCE(MAX(sort_order), 0) FROM space_folders WHERE space_id = ?1",
            params![space_id],
            |row| row.get(0),
        )?;
        let folder = SpaceFolder {
            id: id.clone(),
            space_id: space_id.to_string(),
            name: name.to_string(),
            sort_order: max_order + 1.0,
            is_archived: false,
            updated_at: ts,
        };
        self.conn.execute(
            "INSERT INTO space_folders (id, space_id, name, sort_order, is_archived, updated_at, sync_pending)
             VALUES (?1, ?2, ?3, ?4, 0, ?5, 1)",
            params![
                folder.id,
                folder.space_id,
                folder.name,
                folder.sort_order,
                folder.updated_at
            ],
        )?;
        self.create_list(space_id, "List", Some(&folder.id))?;
        self.log_activity(space_id, "", "You", &format!("created folder \"{name}\""), "folder", &folder.id)?;
        self.enqueue_sync("space_folders", &folder.id, "insert", &folder)?;
        Ok(folder)
    }

    pub fn update_folder(&self, id: &str, patch: UpdateFolderPatch) -> DbResult<SpaceFolder> {
        let current = self
            .conn
            .query_row("SELECT * FROM space_folders WHERE id = ?1", params![id], row_to_folder)
            .map_err(|_| DbError::Message("Folder not found".into()))?;
        let next = SpaceFolder {
            name: patch.name.unwrap_or(current.name),
            updated_at: now_iso(),
            ..current
        };
        self.conn.execute(
            "UPDATE space_folders SET name = ?1, updated_at = ?2, sync_pending = 1 WHERE id = ?3",
            params![next.name, next.updated_at, id],
        )?;
        self.enqueue_sync("space_folders", id, "update", &next)?;
        Ok(next)
    }

    pub fn list_lists(&self, space_id: &str) -> DbResult<Vec<SpaceList>> {
        let mut stmt = self.conn.prepare(
            "SELECT * FROM space_lists WHERE space_id = ?1 AND is_archived = 0
             ORDER BY sort_order ASC, name ASC",
        )?;
        let rows = stmt.query_map(params![space_id], row_to_list)?;
        rows.collect::<Result<Vec<_>, _>>().map_err(DbError::from)
    }

    pub fn create_list(
        &self,
        space_id: &str,
        name: &str,
        folder_id: Option<&str>,
    ) -> DbResult<SpaceList> {
        let id = new_uuid();
        let ts = now_iso();
        let max_order: f64 = self.conn.query_row(
            "SELECT COALESCE(MAX(sort_order), 0) FROM space_lists
             WHERE space_id = ?1 AND COALESCE(folder_id, '') = COALESCE(?2, '')",
            params![space_id, folder_id],
            |row| row.get(0),
        )?;
        let list = SpaceList {
            id: id.clone(),
            space_id: space_id.to_string(),
            folder_id: folder_id.map(str::to_string),
            name: name.to_string(),
            sort_order: max_order + 1.0,
            is_archived: false,
            updated_at: ts,
        };
        self.conn.execute(
            "INSERT INTO space_lists (id, space_id, folder_id, name, sort_order, is_archived, updated_at, sync_pending)
             VALUES (?1, ?2, ?3, ?4, ?5, 0, ?6, 1)",
            params![
                list.id,
                list.space_id,
                list.folder_id,
                list.name,
                list.sort_order,
                list.updated_at
            ],
        )?;
        self.log_activity(space_id, "", "You", &format!("created list \"{name}\""), "list", &list.id)?;
        self.enqueue_sync("space_lists", &list.id, "insert", &list)?;
        Ok(list)
    }

    pub fn update_list(&self, id: &str, patch: UpdateListPatch) -> DbResult<SpaceList> {
        let current = self
            .conn
            .query_row("SELECT * FROM space_lists WHERE id = ?1", params![id], row_to_list)
            .map_err(|_| DbError::Message("List not found".into()))?;
        let next = SpaceList {
            name: patch.name.unwrap_or(current.name),
            updated_at: now_iso(),
            ..current
        };
        self.conn.execute(
            "UPDATE space_lists SET name = ?1, updated_at = ?2, sync_pending = 1 WHERE id = ?3",
            params![next.name, next.updated_at, id],
        )?;
        self.enqueue_sync("space_lists", id, "update", &next)?;
        Ok(next)
    }

    pub fn list_tasks(&self, space_id: &str, list_id: Option<&str>) -> DbResult<Vec<Task>> {
        if let Some(list_id) = list_id {
            let mut stmt = self.conn.prepare(
                "SELECT * FROM tasks WHERE space_id = ?1 AND list_id = ?2 AND status != 'archived'
                 ORDER BY sort_order ASC, updated_at DESC",
            )?;
            let rows = stmt
                .query_map(params![space_id, list_id], row_to_task)?
                .collect::<Result<Vec<_>, _>>()?;
            Ok(rows)
        } else {
            let mut stmt = self.conn.prepare(
                "SELECT * FROM tasks WHERE space_id = ?1 AND status != 'archived'
                 ORDER BY sort_order ASC, updated_at DESC",
            )?;
            let rows = stmt
                .query_map(params![space_id], row_to_task)?
                .collect::<Result<Vec<_>, _>>()?;
            Ok(rows)
        }
    }

    pub fn create_task(&self, input: CreateTaskInput) -> DbResult<Task> {
        let id = new_uuid();
        let ts = now_iso();
        let max_order: f64 = self.conn.query_row(
            "SELECT COALESCE(MAX(sort_order), 0) FROM tasks WHERE space_id = ?1",
            params![input.space_id],
            |row| row.get(0),
        )?;
        let task = Task {
            id: id.clone(),
            space_id: input.space_id.clone(),
            list_id: input.list_id,
            title: input.title.clone(),
            description: String::new(),
            status: input.status.unwrap_or_else(|| "todo".to_string()),
            priority: input.priority.unwrap_or_else(|| "normal".to_string()),
            assignee_id: input.assignee_id,
            start_date: None,
            due_date: input.due_date,
            tags: Vec::new(),
            parent_task_id: None,
            checklist: Vec::new(),
            comment_count: 0,
            attachment_count: 0,
            linked_doc_ids: Vec::new(),
            order: max_order + 1.0,
            updated_at: ts.clone(),
            created_at: ts,
        };

        self.conn.execute(
            "INSERT INTO tasks (
              id, space_id, list_id, title, description, status, priority, assignee_id,
              start_date, due_date, tags, parent_task_id, checklist, comment_count,
              attachment_count, linked_doc_ids, sort_order, updated_at, created_at, sync_pending
            ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, '[]', NULL, '[]', 0, 0, '[]', ?11, ?12, ?13, 1)",
            params![
                task.id,
                task.space_id,
                task.list_id,
                task.title,
                task.description,
                task.status,
                task.priority,
                task.assignee_id,
                task.start_date,
                task.due_date,
                task.order,
                task.updated_at,
                task.created_at,
            ],
        )?;

        self.index_search("task", &task.id, Some(&task.space_id), &task.title, &task.description)?;
        self.log_activity(
            &task.space_id,
            "",
            "You",
            &format!("created task \"{}\"", task.title),
            "task",
            &task.id,
        )?;
        self.enqueue_sync("tasks", &task.id, "insert", &task)?;
        Ok(task)
    }

    pub fn update_task(&self, input: UpdateTaskInput) -> DbResult<Task> {
        let current = self
            .conn
            .query_row("SELECT * FROM tasks WHERE id = ?1", params![input.id], row_to_task)
            .map_err(|_| DbError::Message("Task not found".into()))?;

        let status_changed = input
            .status
            .as_ref()
            .is_some_and(|status| status != &current.status);

        let next = Task {
            title: input.title.unwrap_or(current.title.clone()),
            description: input.description.unwrap_or(current.description.clone()),
            status: input.status.unwrap_or(current.status.clone()),
            priority: input.priority.unwrap_or(current.priority.clone()),
            assignee_id: match input.assignee_id {
                Some(v) => v,
                None => current.assignee_id.clone(),
            },
            list_id: match input.list_id {
                Some(v) => v,
                None => current.list_id.clone(),
            },
            start_date: match input.start_date {
                Some(v) => v,
                None => current.start_date.clone(),
            },
            due_date: match input.due_date {
                Some(v) => v,
                None => current.due_date.clone(),
            },
            tags: input.tags.unwrap_or(current.tags.clone()),
            checklist: input.checklist.unwrap_or(current.checklist.clone()),
            order: input.order.unwrap_or(current.order),
            updated_at: now_iso(),
            ..current
        };

        self.conn.execute(
            "UPDATE tasks SET
              title = ?1, description = ?2, status = ?3, priority = ?4, assignee_id = ?5, list_id = ?6,
              start_date = ?7, due_date = ?8, tags = ?9, checklist = ?10, sort_order = ?11,
              updated_at = ?12, sync_pending = 1
             WHERE id = ?13",
            params![
                next.title,
                next.description,
                next.status,
                next.priority,
                next.assignee_id,
                next.list_id,
                next.start_date,
                next.due_date,
                serde_json::to_string(&next.tags)?,
                serde_json::to_string(&next.checklist)?,
                next.order,
                next.updated_at,
                input.id,
            ],
        )?;

        if status_changed {
            let action = format!(
                "changed status to {}",
                next.status.replace('_', " ")
            );
            self.log_activity(&next.space_id, "", "You", &action, "task", &next.id)?;
        }

        self.index_search("task", &next.id, Some(&next.space_id), &next.title, &next.description)?;
        self.enqueue_sync("tasks", &next.id, "update", &next)?;
        Ok(next)
    }

    pub fn delete_task(&self, id: &str) -> DbResult<()> {
        let space_id: Option<String> = self
            .conn
            .query_row("SELECT space_id FROM tasks WHERE id = ?1", params![id], |row| {
                row.get(0)
            })
            .ok();
        self.conn
            .execute("DELETE FROM tasks WHERE id = ?1", params![id])?;
        self.conn
            .execute("DELETE FROM search_index WHERE entity_id = ?1", params![id])?;
        if let Some(space_id) = space_id {
            let payload = serde_json::json!({ "id": id, "spaceId": space_id });
            self.enqueue_sync("tasks", id, "delete", &payload)?;
        }
        Ok(())
    }

    pub fn list_activity(&self, space_id: &str, limit: i64) -> DbResult<Vec<SpaceActivity>> {
        let mut stmt = self.conn.prepare(
            "SELECT * FROM space_activity WHERE space_id = ?1 ORDER BY created_at DESC LIMIT ?2",
        )?;
        let rows = stmt.query_map(params![space_id, limit], |row| {
            Ok(SpaceActivity {
                id: row.get("id")?,
                space_id: row.get("space_id")?,
                user_id: row.get("user_id")?,
                user_name: row.get("user_name")?,
                action: row.get("action")?,
                entity_type: row.get("entity_type")?,
                entity_id: row.get("entity_id")?,
                created_at: row.get("created_at")?,
            })
        })?;
        rows.collect::<Result<Vec<_>, _>>().map_err(DbError::from)
    }

    pub fn list_members(&self, space_id: &str) -> DbResult<Vec<SpaceMember>> {
        let mut stmt = self
            .conn
            .prepare("SELECT * FROM space_members WHERE space_id = ?1")?;
        let rows: Vec<SpaceMember> = stmt
            .query_map(params![space_id], |row| {
                Ok(SpaceMember {
                    id: row.get("id")?,
                    space_id: row.get("space_id")?,
                    user_id: row.get("user_id")?,
                    role: row.get("role")?,
                    name: row.get("name")?,
                    email: row.get("email")?,
                    avatar_color: row.get("avatar_color")?,
                    is_online: row_bool(row, "is_online")?,
                })
            })?
            .collect::<Result<Vec<_>, _>>()?;

        if rows.is_empty() {
            let meta = load_meta(&self.conn)?;
            return Ok(vec![SpaceMember {
                id: new_uuid(),
                space_id: space_id.to_string(),
                user_id: meta
                    .get("current_user_id")
                    .cloned()
                    .unwrap_or_else(new_uuid),
                role: "owner".to_string(),
                name: meta
                    .get("current_user_name")
                    .cloned()
                    .unwrap_or_else(|| "You".to_string()),
                email: String::new(),
                avatar_color: "#3d5a80".to_string(),
                is_online: true,
            }]);
        }
        Ok(rows)
    }

    pub fn list_approvals(&self, space_id: &str) -> DbResult<Vec<Approval>> {
        let mut stmt = self
            .conn
            .prepare("SELECT * FROM approvals WHERE space_id = ?1")?;
        let rows = stmt.query_map(params![space_id], |row| {
            Ok(Approval {
                id: row.get("id")?,
                space_id: row.get("space_id")?,
                task_id: opt_str(row.get("task_id")?),
                document_id: opt_str(row.get("document_id")?),
                status: row.get("status")?,
                title: row.get("title")?,
                updated_at: row.get("updated_at")?,
            })
        })?;
        rows.collect::<Result<Vec<_>, _>>().map_err(DbError::from)
    }

    pub fn list_documents(&self, space_id: &str) -> DbResult<Vec<SpaceDocument>> {
        let mut stmt = self
            .conn
            .prepare("SELECT * FROM documents WHERE space_id = ?1")?;
        let rows = stmt.query_map(params![space_id], |row| row_to_document(row, None))?;
        rows.collect::<Result<Vec<_>, _>>().map_err(DbError::from)
    }

    pub fn get_document(&self, id: &str) -> DbResult<Option<SpaceDocumentDetail>> {
        let mut stmt = self.conn.prepare(
            "SELECT d.*, s.name as space_name FROM documents d
             JOIN spaces s ON s.id = d.space_id WHERE d.id = ?1",
        )?;
        let mut rows = stmt.query_map(params![id], |row| {
            let doc = row_to_document(row, Some(row.get("space_name")?))?;
            Ok(SpaceDocumentDetail {
                id: doc.id,
                space_id: doc.space_id,
                title: doc.title,
                doc_type: doc.doc_type,
                updated_at: doc.updated_at,
                space_name: doc.space_name,
                content: row.get::<_, Option<String>>("content")?.unwrap_or_default(),
            })
        })?;
        Ok(rows.next().transpose()?)
    }

    pub fn create_document(
        &self,
        space_id: &str,
        title: &str,
        content: &str,
    ) -> DbResult<SpaceDocumentDetail> {
        let meta = load_meta(&self.conn)?;
        let id = new_uuid();
        let ts = now_iso();
        self.conn.execute(
            "INSERT INTO documents (id, space_id, title, doc_type, content, updated_at, sync_pending)
             VALUES (?1, ?2, ?3, 'brief', ?4, ?5, 1)",
            params![id, space_id, title, content, ts],
        )?;
        let user_id = meta
            .get("current_user_id")
            .cloned()
            .unwrap_or_else(new_uuid);
        let user_name = meta
            .get("current_user_name")
            .cloned()
            .unwrap_or_else(|| "You".to_string());
        self.log_activity(space_id, &user_id, &user_name, "created document", "document", &id)?;
        self.index_search("doc", &id, Some(space_id), title, content)?;
        let doc = self
            .get_document(&id)?
            .ok_or_else(|| DbError::Message("Document not found".into()))?;
        self.enqueue_sync("documents", &id, "insert", &doc)?;
        Ok(doc)
    }

    pub fn update_document(&self, id: &str, patch: UpdateDocumentPatch) -> DbResult<SpaceDocumentDetail> {
        let existing = self
            .get_document(id)?
            .ok_or_else(|| DbError::Message("Document not found".into()))?;
        let title = patch.title.unwrap_or(existing.title.clone());
        let content = patch.content.unwrap_or(existing.content.clone());
        let ts = now_iso();
        self.conn.execute(
            "UPDATE documents SET title = ?1, content = ?2, updated_at = ?3, sync_pending = 1 WHERE id = ?4",
            params![title, content, ts, id],
        )?;
        self.index_search("doc", id, Some(&existing.space_id), &title, &content)?;
        let doc = self
            .get_document(id)?
            .ok_or_else(|| DbError::Message("Document not found".into()))?;
        self.enqueue_sync("documents", id, "update", &doc)?;
        Ok(doc)
    }

    pub fn list_workspace_documents(&self) -> DbResult<Vec<SpaceDocument>> {
        let mut stmt = self.conn.prepare(
            "SELECT d.*, s.name as space_name FROM documents d
             JOIN spaces s ON s.id = d.space_id
             WHERE s.is_archived = 0
             ORDER BY d.updated_at DESC",
        )?;
        let rows = stmt.query_map([], |row| {
            row_to_document(row, Some(row.get("space_name")?))
        })?;
        rows.collect::<Result<Vec<_>, _>>().map_err(DbError::from)
    }

    pub fn list_workspace_approvals(&self) -> DbResult<Vec<Approval>> {
        let mut stmt = self.conn.prepare(
            "SELECT a.* FROM approvals a
             JOIN spaces s ON s.id = a.space_id
             WHERE s.is_archived = 0
             ORDER BY a.updated_at DESC",
        )?;
        let rows = stmt.query_map([], |row| {
            Ok(Approval {
                id: row.get("id")?,
                space_id: row.get("space_id")?,
                task_id: opt_str(row.get("task_id")?),
                document_id: opt_str(row.get("document_id")?),
                status: row.get("status")?,
                title: row.get("title")?,
                updated_at: row.get("updated_at")?,
            })
        })?;
        rows.collect::<Result<Vec<_>, _>>().map_err(DbError::from)
    }

    pub fn list_workspace_files(&self) -> DbResult<Vec<SpaceFile>> {
        let mut stmt = self.conn.prepare(
            "SELECT f.* FROM space_files f
             JOIN spaces s ON s.id = f.space_id
             WHERE s.is_archived = 0
             ORDER BY f.updated_at DESC",
        )?;
        let rows = stmt.query_map([], |row| {
            Ok(SpaceFile {
                id: row.get("id")?,
                space_id: row.get("space_id")?,
                file_name: row.get("file_name")?,
                file_url: row.get("file_url")?,
                mime_type: row.get("mime_type")?,
                updated_at: row.get("updated_at")?,
            })
        })?;
        rows.collect::<Result<Vec<_>, _>>().map_err(DbError::from)
    }

    pub fn create_file(&self, space_id: &str, file_name: &str, file_url: &str) -> DbResult<SpaceFile> {
        let id = new_uuid();
        let ts = now_iso();
        self.conn.execute(
            "INSERT INTO space_files (id, space_id, file_name, file_url, mime_type, updated_at)
             VALUES (?1, ?2, ?3, ?4, 'application/octet-stream', ?5)",
            params![id, space_id, file_name, file_url, ts],
        )?;
        let meta = load_meta(&self.conn)?;
        let user_id = meta
            .get("current_user_id")
            .cloned()
            .unwrap_or_else(new_uuid);
        let user_name = meta
            .get("current_user_name")
            .cloned()
            .unwrap_or_else(|| "You".to_string());
        self.log_activity(space_id, &user_id, &user_name, "added file", "file", &id)?;
        Ok(SpaceFile {
            id,
            space_id: space_id.to_string(),
            file_name: file_name.to_string(),
            file_url: file_url.to_string(),
            mime_type: "application/octet-stream".to_string(),
            updated_at: ts,
        })
    }

    pub fn list_workspace_tasks(&self) -> DbResult<Vec<WorkspaceTask>> {
        let mut stmt = self.conn.prepare(
            "SELECT t.*, s.name as space_name FROM tasks t
             JOIN spaces s ON s.id = t.space_id
             WHERE s.is_archived = 0 AND t.status NOT IN ('archived')
             ORDER BY t.updated_at DESC LIMIT 500",
        )?;
        let rows = stmt.query_map([], |row| {
            Ok(WorkspaceTask {
                task: row_to_task(row)?,
                space_name: row.get("space_name")?,
            })
        })?;
        rows.collect::<Result<Vec<_>, _>>().map_err(DbError::from)
    }

    pub fn list_workspace_members(&self) -> DbResult<Vec<WorkspaceMember>> {
        let mut stmt = self.conn.prepare(
            "SELECT user_id, name, email, role, avatar_color,
                    MAX(is_online) as is_online,
                    COUNT(DISTINCT space_id) as space_count
             FROM space_members
             GROUP BY user_id, name, email, role, avatar_color
             ORDER BY name ASC",
        )?;
        let rows = stmt.query_map([], |row| {
            Ok(WorkspaceMember {
                id: row.get("user_id")?,
                space_id: String::new(),
                user_id: row.get("user_id")?,
                role: row.get("role")?,
                name: row.get("name")?,
                email: row.get("email")?,
                avatar_color: row.get("avatar_color")?,
                is_online: row_bool(row, "is_online")?,
                space_count: row.get("space_count")?,
            })
        })?;
        rows.collect::<Result<Vec<_>, _>>().map_err(DbError::from)
    }

    pub fn list_workspace_activity(&self, limit: i64) -> DbResult<Vec<WorkspaceActivity>> {
        let mut stmt = self.conn.prepare(
            "SELECT a.*, s.name as space_name FROM space_activity a
             JOIN spaces s ON s.id = a.space_id
             WHERE s.is_archived = 0
             ORDER BY a.created_at DESC LIMIT ?1",
        )?;
        let rows = stmt.query_map(params![limit], |row| {
            Ok(WorkspaceActivity {
                id: row.get("id")?,
                space_id: row.get("space_id")?,
                user_id: row.get("user_id")?,
                user_name: row.get("user_name")?,
                action: row.get("action")?,
                entity_type: row.get("entity_type")?,
                entity_id: row.get("entity_id")?,
                created_at: row.get("created_at")?,
                space_name: row.get("space_name")?,
            })
        })?;
        rows.collect::<Result<Vec<_>, _>>().map_err(DbError::from)
    }

    pub fn list_notifications(&self, limit: i64) -> DbResult<Vec<NotificationItem>> {
        let mut stmt = self
            .conn
            .prepare("SELECT * FROM notifications ORDER BY created_at DESC LIMIT ?1")?;
        let rows = stmt.query_map(params![limit], |row| {
            Ok(NotificationItem {
                id: row.get("id")?,
                space_id: opt_str(row.get("space_id")?),
                title: row.get("title")?,
                body: row.get("body")?,
                kind: row.get("kind")?,
                read: row_bool(row, "read")?,
                created_at: row.get("created_at")?,
            })
        })?;
        rows.collect::<Result<Vec<_>, _>>().map_err(DbError::from)
    }

    pub fn get_workspace_summary(&self) -> DbResult<WorkspaceSummary> {
        let space_count: i64 = self.conn.query_row(
            "SELECT COUNT(*) FROM spaces WHERE is_archived = 0",
            [],
            |row| row.get(0),
        )?;
        let open_tasks: i64 = self.conn.query_row(
            "SELECT COUNT(*) FROM tasks t
             JOIN spaces s ON s.id = t.space_id
             WHERE s.is_archived = 0 AND t.status NOT IN ('completed', 'archived')",
            [],
            |row| row.get(0),
        )?;
        let overdue_tasks: i64 = self.conn.query_row(
            "SELECT COUNT(*) FROM tasks t
             JOIN spaces s ON s.id = t.space_id
             WHERE s.is_archived = 0 AND t.due_date IS NOT NULL AND t.due_date < ?1
             AND t.status NOT IN ('completed', 'archived')",
            params![now_iso()],
            |row| row.get(0),
        )?;
        let pending_approvals: i64 = self.conn.query_row(
            "SELECT COUNT(*) FROM approvals a
             JOIN spaces s ON s.id = a.space_id
             WHERE s.is_archived = 0 AND a.status IN ('requested', 'in_review')",
            [],
            |row| row.get(0),
        )?;
        let document_count: i64 = self.conn.query_row(
            "SELECT COUNT(*) FROM documents d JOIN spaces s ON s.id = d.space_id WHERE s.is_archived = 0",
            [],
            |row| row.get(0),
        )?;
        let file_count: i64 = self.conn.query_row(
            "SELECT COUNT(*) FROM space_files f JOIN spaces s ON s.id = f.space_id WHERE s.is_archived = 0",
            [],
            |row| row.get(0),
        )?;
        let online_members: i64 = self.conn.query_row(
            "SELECT COUNT(DISTINCT user_id) FROM space_members WHERE is_online = 1",
            [],
            |row| row.get(0),
        )?;
        Ok(WorkspaceSummary {
            space_count,
            open_tasks,
            overdue_tasks,
            pending_approvals,
            document_count,
            file_count,
            online_members,
        })
    }

    pub fn list_comments(&self, task_id: &str) -> DbResult<Vec<SpaceComment>> {
        let mut stmt = self.conn.prepare(
            "SELECT * FROM space_comments WHERE task_id = ?1 ORDER BY created_at ASC",
        )?;
        let rows = stmt.query_map(params![task_id], |row| {
            Ok(SpaceComment {
                id: row.get("id")?,
                space_id: row.get("space_id")?,
                task_id: opt_str(row.get("task_id")?),
                document_id: opt_str(row.get("document_id")?),
                user_id: row.get("user_id")?,
                user_name: row.get("user_name")?,
                body: row.get("body")?,
                created_at: row.get("created_at")?,
            })
        })?;
        rows.collect::<Result<Vec<_>, _>>().map_err(DbError::from)
    }

    pub fn create_comment(&self, input: CreateCommentInput) -> DbResult<SpaceComment> {
        let meta = load_meta(&self.conn)?;
        let id = new_uuid();
        let ts = now_iso();
        let comment = SpaceComment {
            id: id.clone(),
            space_id: input.space_id.clone(),
            task_id: Some(input.task_id.clone()),
            document_id: None,
            user_id: meta
                .get("current_user_id")
                .cloned()
                .unwrap_or_else(new_uuid),
            user_name: meta
                .get("current_user_name")
                .cloned()
                .unwrap_or_else(|| "You".to_string()),
            body: input.body.clone(),
            created_at: ts.clone(),
        };
        self.conn.execute(
            "INSERT INTO space_comments (id, space_id, task_id, document_id, user_id, user_name, body, created_at, sync_pending)
             VALUES (?1, ?2, ?3, NULL, ?4, ?5, ?6, ?7, 1)",
            params![
                comment.id,
                comment.space_id,
                comment.task_id,
                comment.user_id,
                comment.user_name,
                comment.body,
                comment.created_at
            ],
        )?;
        self.conn.execute(
            "UPDATE tasks SET comment_count = comment_count + 1, updated_at = ?1 WHERE id = ?2",
            params![ts, input.task_id],
        )?;
        self.log_activity(
            &input.space_id,
            &comment.user_id,
            &comment.user_name,
            "commented on task",
            "task",
            &input.task_id,
        )?;
        self.enqueue_sync("space_comments", &comment.id, "insert", &comment)?;
        Ok(comment)
    }

    pub fn list_files(&self, space_id: &str) -> DbResult<Vec<SpaceFile>> {
        let mut stmt = self
            .conn
            .prepare("SELECT * FROM space_files WHERE space_id = ?1")?;
        let rows = stmt.query_map(params![space_id], |row| {
            Ok(SpaceFile {
                id: row.get("id")?,
                space_id: row.get("space_id")?,
                file_name: row.get("file_name")?,
                file_url: row.get("file_url")?,
                mime_type: row.get("mime_type")?,
                updated_at: row.get("updated_at")?,
            })
        })?;
        rows.collect::<Result<Vec<_>, _>>().map_err(DbError::from)
    }

    pub fn search(&self, query: &str) -> DbResult<Vec<SearchResult>> {
        let trimmed = query.trim();
        if trimmed.is_empty() {
            return Ok(Vec::new());
        }
        let q = format!("%{}%", trimmed.to_lowercase());
        let mut stmt = self.conn.prepare(
            "SELECT * FROM search_index
             WHERE lower(title) LIKE ?1 OR lower(body) LIKE ?2
             ORDER BY updated_at DESC LIMIT 40",
        )?;
        let rows = stmt.query_map(params![q, q], |row| {
            let body: String = row.get("body")?;
            let subtitle = if body.chars().count() > 80 {
                body.chars().take(80).collect()
            } else {
                body
            };
            Ok(SearchResult {
                id: row.get("entity_id")?,
                result_type: row.get("entity_type")?,
                title: row.get("title")?,
                subtitle,
                space_id: opt_str(row.get("space_id")?),
            })
        })?;
        rows.collect::<Result<Vec<_>, _>>().map_err(DbError::from)
    }

    pub fn list_sync_queue(&self, limit: i64) -> DbResult<Vec<SyncQueueItem>> {
        let mut stmt = self.conn.prepare(
            "SELECT id, table_name, record_id, operation, payload FROM sync_queue
             ORDER BY created_at ASC LIMIT ?1",
        )?;
        let rows = stmt.query_map(params![limit], |row| {
            Ok(SyncQueueItem {
                id: row.get("id")?,
                table_name: row.get("table_name")?,
                record_id: row.get("record_id")?,
                operation: row.get("operation")?,
                payload: row.get("payload")?,
            })
        })?;
        rows.collect::<Result<Vec<_>, _>>().map_err(DbError::from)
    }

    pub fn remove_sync_queue_item(&self, id: &str) -> DbResult<()> {
        self.conn
            .execute("DELETE FROM sync_queue WHERE id = ?1", params![id])?;
        Ok(())
    }

    pub fn close(self) -> DbResult<()> {
        Ok(())
    }

    fn index_search(
        &self,
        entity_type: &str,
        entity_id: &str,
        space_id: Option<&str>,
        title: &str,
        body: &str,
    ) -> DbResult<()> {
        let id = format!("{entity_type}:{entity_id}");
        self.conn.execute(
            "INSERT INTO search_index (id, entity_type, entity_id, space_id, title, body, updated_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)
             ON CONFLICT(id) DO UPDATE SET title = excluded.title, body = excluded.body, updated_at = excluded.updated_at",
            params![
                id,
                entity_type,
                entity_id,
                space_id,
                title,
                body,
                now_iso()
            ],
        )?;
        Ok(())
    }

    fn log_activity(
        &self,
        space_id: &str,
        user_id: &str,
        user_name: &str,
        action: &str,
        entity_type: &str,
        entity_id: &str,
    ) -> DbResult<()> {
        self.conn.execute(
            "INSERT INTO space_activity (id, space_id, user_id, user_name, action, entity_type, entity_id, created_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)",
            params![
                new_uuid(),
                space_id,
                user_id,
                user_name,
                action,
                entity_type,
                entity_id,
                now_iso()
            ],
        )?;
        Ok(())
    }

    fn enqueue_sync(
        &self,
        table_name: &str,
        record_id: &str,
        operation: &str,
        payload: &impl serde::Serialize,
    ) -> DbResult<()> {
        self.conn.execute(
            "INSERT INTO sync_queue (id, table_name, record_id, operation, payload, created_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
            params![
                new_uuid(),
                table_name,
                record_id,
                operation,
                serde_json::to_string(payload)?,
                now_iso()
            ],
        )?;
        Ok(())
    }
}
