use serde::{Deserialize, Serialize};
use std::collections::HashMap;

pub type SyncStatus = String;

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Workspace {
    pub id: String,
    pub name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub logo_url: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Space {
    pub id: String,
    pub workspace_id: String,
    pub name: String,
    pub description: String,
    #[serde(rename = "type")]
    pub space_type: String,
    pub status: String,
    pub owner_id: String,
    pub color: String,
    pub is_pinned: bool,
    pub is_favourite: bool,
    pub is_archived: bool,
    pub client_mode: bool,
    pub updated_at: String,
    pub created_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SpaceFolder {
    pub id: String,
    pub space_id: String,
    pub name: String,
    pub sort_order: f64,
    pub is_archived: bool,
    pub updated_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SpaceList {
    pub id: String,
    pub space_id: String,
    pub folder_id: Option<String>,
    pub name: String,
    pub sort_order: f64,
    pub is_archived: bool,
    pub updated_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ChecklistItem {
    pub id: String,
    pub title: String,
    pub done: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Task {
    pub id: String,
    pub space_id: String,
    pub list_id: Option<String>,
    pub title: String,
    pub description: String,
    pub status: String,
    pub priority: String,
    pub assignee_id: Option<String>,
    pub start_date: Option<String>,
    pub due_date: Option<String>,
    pub tags: Vec<String>,
    pub parent_task_id: Option<String>,
    pub checklist: Vec<ChecklistItem>,
    pub comment_count: i64,
    pub attachment_count: i64,
    pub linked_doc_ids: Vec<String>,
    pub order: f64,
    pub updated_at: String,
    pub created_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SpaceActivity {
    pub id: String,
    pub space_id: String,
    pub user_id: String,
    pub user_name: String,
    pub action: String,
    pub entity_type: String,
    pub entity_id: String,
    pub created_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SpaceMember {
    pub id: String,
    pub space_id: String,
    pub user_id: String,
    pub role: String,
    pub name: String,
    pub email: String,
    pub avatar_color: String,
    pub is_online: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Approval {
    pub id: String,
    pub space_id: String,
    pub task_id: Option<String>,
    pub document_id: Option<String>,
    pub status: String,
    pub title: String,
    pub updated_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SpaceDocument {
    pub id: String,
    pub space_id: String,
    pub title: String,
    pub doc_type: String,
    pub updated_at: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub space_name: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SpaceDocumentDetail {
    pub id: String,
    pub space_id: String,
    pub title: String,
    pub doc_type: String,
    pub updated_at: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub space_name: Option<String>,
    pub content: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SpaceFile {
    pub id: String,
    pub space_id: String,
    pub file_name: String,
    pub file_url: String,
    pub mime_type: String,
    pub updated_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct WorkspaceActivity {
    pub id: String,
    pub space_id: String,
    pub user_id: String,
    pub user_name: String,
    pub action: String,
    pub entity_type: String,
    pub entity_id: String,
    pub created_at: String,
    pub space_name: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct WorkspaceMember {
    pub id: String,
    pub space_id: String,
    pub user_id: String,
    pub role: String,
    pub name: String,
    pub email: String,
    pub avatar_color: String,
    pub is_online: bool,
    pub space_count: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct WorkspaceTask {
    #[serde(flatten)]
    pub task: Task,
    pub space_name: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct WorkspaceSummary {
    pub space_count: i64,
    pub open_tasks: i64,
    pub overdue_tasks: i64,
    pub pending_approvals: i64,
    pub document_count: i64,
    pub file_count: i64,
    pub online_members: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SpaceComment {
    pub id: String,
    pub space_id: String,
    pub task_id: Option<String>,
    pub document_id: Option<String>,
    pub user_id: String,
    pub user_name: String,
    pub body: String,
    pub created_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CoverageMention {
    pub id: String,
    pub space_id: Option<String>,
    pub headline: String,
    pub publication: String,
    pub sentiment: String,
    pub reach: i64,
    pub pr_value: f64,
    pub url: String,
    pub saved: bool,
    pub published_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct NotificationItem {
    pub id: String,
    pub space_id: Option<String>,
    pub title: String,
    pub body: String,
    pub kind: String,
    pub read: bool,
    pub created_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SearchResult {
    pub id: String,
    #[serde(rename = "type")]
    pub result_type: String,
    pub title: String,
    pub subtitle: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub space_id: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct BootstrapPayload {
    pub workspace: Workspace,
    pub spaces: Vec<Space>,
    pub current_user_id: String,
    pub current_user_name: String,
    pub sync_status: SyncStatus,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CreateSpaceInput {
    pub name: String,
    #[serde(default, rename = "type")]
    pub space_type: Option<String>,
    #[serde(default)]
    pub description: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct UpdateSpacePatch {
    pub name: Option<String>,
    pub description: Option<String>,
    #[serde(default, rename = "type")]
    pub space_type: Option<String>,
    pub status: Option<String>,
    pub color: Option<String>,
    pub is_pinned: Option<bool>,
    pub is_favourite: Option<bool>,
    pub is_archived: Option<bool>,
    pub client_mode: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct UpdateFolderPatch {
    pub name: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct UpdateListPatch {
    pub name: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CreateTaskInput {
    pub space_id: String,
    #[serde(default)]
    pub list_id: Option<String>,
    pub title: String,
    #[serde(default)]
    pub status: Option<String>,
    #[serde(default)]
    pub priority: Option<String>,
    #[serde(default)]
    pub assignee_id: Option<String>,
    #[serde(default)]
    pub due_date: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UpdateTaskInput {
    pub id: String,
    #[serde(default)]
    pub title: Option<String>,
    #[serde(default)]
    pub description: Option<String>,
    #[serde(default)]
    pub status: Option<String>,
    #[serde(default)]
    pub priority: Option<String>,
    #[serde(default)]
    pub assignee_id: Option<Option<String>>,
    #[serde(default)]
    pub list_id: Option<Option<String>>,
    #[serde(default)]
    pub start_date: Option<Option<String>>,
    #[serde(default)]
    pub due_date: Option<Option<String>>,
    #[serde(default)]
    pub tags: Option<Vec<String>>,
    #[serde(default)]
    pub checklist: Option<Vec<ChecklistItem>>,
    #[serde(default)]
    pub order: Option<f64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CreateCommentInput {
    pub space_id: String,
    pub task_id: String,
    pub body: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct UpdateDocumentPatch {
    pub title: Option<String>,
    pub content: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SyncQueueItem {
    pub id: String,
    pub table_name: String,
    pub record_id: String,
    pub operation: String,
    pub payload: String,
}

pub fn load_meta(conn: &rusqlite::Connection) -> Result<HashMap<String, String>, rusqlite::Error> {
    let mut map = HashMap::new();
    let mut stmt = conn.prepare("SELECT key, value FROM meta")?;
    let rows = stmt.query_map([], |row| {
        Ok((row.get::<_, String>(0)?, row.get::<_, String>(1)?))
    })?;
    for row in rows {
        let (key, value) = row?;
        map.insert(key, value);
    }
    Ok(map)
}
