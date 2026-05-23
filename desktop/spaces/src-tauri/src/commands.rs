use crate::db::{DbError, SpacesDatabase};
use crate::models::{
    Approval, BootstrapPayload, CoverageMention, CreateCommentInput, CreateSpaceInput,
    CreateTaskInput, NotificationItem, SearchResult, Space, SpaceActivity, SpaceComment,
    SpaceDocument,
    SpaceDocumentDetail, SpaceFile, SpaceFolder, SpaceList, SpaceMember, SyncStatus, Task,
    UpdateDocumentPatch, UpdateFolderPatch, UpdateListPatch, UpdateSpacePatch, UpdateTaskInput,
    WorkspaceActivity, WorkspaceMember, WorkspaceSummary, WorkspaceTask,
};
use std::sync::Mutex;
use tauri::{AppHandle, Emitter, Manager, State, WebviewUrl, WebviewWindowBuilder};

pub struct DbState(pub Mutex<SpacesDatabase>);

fn db_err(err: DbError) -> String {
    err.to_string()
}

pub fn emit_spaces_refresh(app: &AppHandle) {
    let _ = app.emit("spaces:refresh", ());
}

fn hash_url(app: &AppHandle, hash: &str) -> Result<WebviewUrl, String> {
    if cfg!(debug_assertions) {
        let dev_url = app
            .config()
            .build
            .dev_url
            .clone()
            .unwrap_or_else(|| "http://localhost:5173".parse().unwrap());
        let url = format!("{dev_url}/#{hash}");
        url.parse::<url::Url>()
            .map(WebviewUrl::External)
            .map_err(|e| e.to_string())
    } else {
        Ok(WebviewUrl::App(format!("/index.html#{hash}").into()))
    }
}

#[tauri::command]
pub fn spaces_get_bootstrap(state: State<'_, DbState>) -> Result<BootstrapPayload, String> {
    state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .get_bootstrap()
        .map_err(db_err)
}

#[tauri::command]
pub fn spaces_list_spaces(state: State<'_, DbState>) -> Result<Vec<Space>, String> {
    state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .list_spaces()
        .map_err(db_err)
}

#[tauri::command]
pub fn spaces_get_space(state: State<'_, DbState>, id: String) -> Result<Option<Space>, String> {
    state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .get_space(&id)
        .map_err(db_err)
}

#[tauri::command]
pub fn spaces_create_space(
    app: AppHandle,
    state: State<'_, DbState>,
    input: CreateSpaceInput,
) -> Result<Space, String> {
    let space = state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .create_space(input)
        .map_err(db_err)?;
    emit_spaces_refresh(&app);
    Ok(space)
}

#[tauri::command]
pub fn spaces_update_space(
    app: AppHandle,
    state: State<'_, DbState>,
    id: String,
    patch: UpdateSpacePatch,
) -> Result<Space, String> {
    let space = state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .update_space(&id, patch)
        .map_err(db_err)?;
    emit_spaces_refresh(&app);
    Ok(space)
}

#[tauri::command]
pub fn spaces_list_folders(
    state: State<'_, DbState>,
    space_id: String,
) -> Result<Vec<SpaceFolder>, String> {
    state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .list_folders(&space_id)
        .map_err(db_err)
}

#[tauri::command]
pub fn spaces_create_folder(
    app: AppHandle,
    state: State<'_, DbState>,
    space_id: String,
    name: String,
) -> Result<SpaceFolder, String> {
    let folder = state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .create_folder(&space_id, &name)
        .map_err(db_err)?;
    emit_spaces_refresh(&app);
    Ok(folder)
}

#[tauri::command]
pub fn spaces_update_folder(
    app: AppHandle,
    state: State<'_, DbState>,
    id: String,
    patch: UpdateFolderPatch,
) -> Result<SpaceFolder, String> {
    let folder = state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .update_folder(&id, patch)
        .map_err(db_err)?;
    emit_spaces_refresh(&app);
    Ok(folder)
}

#[tauri::command]
pub fn spaces_list_lists(
    state: State<'_, DbState>,
    space_id: String,
) -> Result<Vec<SpaceList>, String> {
    state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .list_lists(&space_id)
        .map_err(db_err)
}

#[tauri::command]
pub fn spaces_create_list(
    app: AppHandle,
    state: State<'_, DbState>,
    space_id: String,
    name: String,
    folder_id: Option<String>,
) -> Result<SpaceList, String> {
    let list = state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .create_list(&space_id, &name, folder_id.as_deref())
        .map_err(db_err)?;
    emit_spaces_refresh(&app);
    Ok(list)
}

#[tauri::command]
pub fn spaces_update_list(
    app: AppHandle,
    state: State<'_, DbState>,
    id: String,
    patch: UpdateListPatch,
) -> Result<SpaceList, String> {
    let list = state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .update_list(&id, patch)
        .map_err(db_err)?;
    emit_spaces_refresh(&app);
    Ok(list)
}

#[tauri::command]
pub fn spaces_list_tasks(
    state: State<'_, DbState>,
    space_id: String,
    list_id: Option<String>,
) -> Result<Vec<Task>, String> {
    state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .list_tasks(&space_id, list_id.as_deref())
        .map_err(db_err)
}

#[tauri::command]
pub fn spaces_create_task(
    app: AppHandle,
    state: State<'_, DbState>,
    input: CreateTaskInput,
) -> Result<Task, String> {
    let task = state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .create_task(input)
        .map_err(db_err)?;
    emit_spaces_refresh(&app);
    Ok(task)
}

#[tauri::command]
pub fn spaces_update_task(
    app: AppHandle,
    state: State<'_, DbState>,
    input: UpdateTaskInput,
) -> Result<Task, String> {
    let task = state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .update_task(input)
        .map_err(db_err)?;
    emit_spaces_refresh(&app);
    Ok(task)
}

#[tauri::command]
pub fn spaces_delete_task(app: AppHandle, state: State<'_, DbState>, id: String) -> Result<(), String> {
    state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .delete_task(&id)
        .map_err(db_err)?;
    emit_spaces_refresh(&app);
    Ok(())
}

#[tauri::command]
pub fn spaces_list_activity(
    state: State<'_, DbState>,
    space_id: String,
    limit: Option<i64>,
) -> Result<Vec<SpaceActivity>, String> {
    state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .list_activity(&space_id, limit.unwrap_or(30))
        .map_err(db_err)
}

#[tauri::command]
pub fn spaces_list_members(
    state: State<'_, DbState>,
    space_id: String,
) -> Result<Vec<SpaceMember>, String> {
    state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .list_members(&space_id)
        .map_err(db_err)
}

#[tauri::command]
pub fn spaces_list_approvals(
    state: State<'_, DbState>,
    space_id: String,
) -> Result<Vec<Approval>, String> {
    state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .list_approvals(&space_id)
        .map_err(db_err)
}

#[tauri::command]
pub fn spaces_list_documents(
    state: State<'_, DbState>,
    space_id: String,
) -> Result<Vec<SpaceDocument>, String> {
    state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .list_documents(&space_id)
        .map_err(db_err)
}

#[tauri::command]
pub fn spaces_get_document(
    state: State<'_, DbState>,
    id: String,
) -> Result<Option<SpaceDocumentDetail>, String> {
    state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .get_document(&id)
        .map_err(db_err)
}

#[tauri::command]
pub fn spaces_create_document(
    app: AppHandle,
    state: State<'_, DbState>,
    space_id: String,
    title: String,
    content: Option<String>,
) -> Result<SpaceDocumentDetail, String> {
    let doc = state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .create_document(&space_id, &title, content.as_deref().unwrap_or(""))
        .map_err(db_err)?;
    emit_spaces_refresh(&app);
    Ok(doc)
}

#[tauri::command]
pub fn spaces_update_document(
    app: AppHandle,
    state: State<'_, DbState>,
    id: String,
    patch: UpdateDocumentPatch,
) -> Result<SpaceDocumentDetail, String> {
    let doc = state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .update_document(&id, patch)
        .map_err(db_err)?;
    emit_spaces_refresh(&app);
    Ok(doc)
}

#[tauri::command]
pub fn spaces_list_files(
    state: State<'_, DbState>,
    space_id: String,
) -> Result<Vec<SpaceFile>, String> {
    state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .list_files(&space_id)
        .map_err(db_err)
}

#[tauri::command]
pub fn spaces_create_file(
    app: AppHandle,
    state: State<'_, DbState>,
    space_id: String,
    file_name: String,
    file_url: String,
) -> Result<SpaceFile, String> {
    let file = state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .create_file(&space_id, &file_name, &file_url)
        .map_err(db_err)?;
    emit_spaces_refresh(&app);
    Ok(file)
}

#[tauri::command]
pub fn spaces_list_workspace_documents(
    state: State<'_, DbState>,
) -> Result<Vec<SpaceDocument>, String> {
    state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .list_workspace_documents()
        .map_err(db_err)
}

#[tauri::command]
pub fn spaces_list_workspace_approvals(state: State<'_, DbState>) -> Result<Vec<Approval>, String> {
    state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .list_workspace_approvals()
        .map_err(db_err)
}

#[tauri::command]
pub fn spaces_list_workspace_files(state: State<'_, DbState>) -> Result<Vec<SpaceFile>, String> {
    state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .list_workspace_files()
        .map_err(db_err)
}

#[tauri::command]
pub fn spaces_list_workspace_tasks(state: State<'_, DbState>) -> Result<Vec<WorkspaceTask>, String> {
    state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .list_workspace_tasks()
        .map_err(db_err)
}

#[tauri::command]
pub fn spaces_list_workspace_members(
    state: State<'_, DbState>,
) -> Result<Vec<WorkspaceMember>, String> {
    state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .list_workspace_members()
        .map_err(db_err)
}

#[tauri::command]
pub fn spaces_list_workspace_activity(
    state: State<'_, DbState>,
    limit: Option<i64>,
) -> Result<Vec<WorkspaceActivity>, String> {
    state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .list_workspace_activity(limit.unwrap_or(40))
        .map_err(db_err)
}

#[tauri::command]
pub fn spaces_list_coverage(
    state: State<'_, DbState>,
    limit: Option<i64>,
) -> Result<Vec<CoverageMention>, String> {
    state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .list_coverage_mentions(limit.unwrap_or(100))
        .map_err(db_err)
}

#[tauri::command]
pub fn spaces_list_notifications(
    state: State<'_, DbState>,
    limit: Option<i64>,
) -> Result<Vec<NotificationItem>, String> {
    state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .list_notifications(limit.unwrap_or(30))
        .map_err(db_err)
}

#[tauri::command]
pub fn spaces_get_workspace_summary(state: State<'_, DbState>) -> Result<WorkspaceSummary, String> {
    state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .get_workspace_summary()
        .map_err(db_err)
}

#[tauri::command]
pub fn spaces_list_comments(
    state: State<'_, DbState>,
    task_id: String,
) -> Result<Vec<SpaceComment>, String> {
    state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .list_comments(&task_id)
        .map_err(db_err)
}

#[tauri::command]
pub fn spaces_create_comment(
    app: AppHandle,
    state: State<'_, DbState>,
    input: CreateCommentInput,
) -> Result<SpaceComment, String> {
    let comment = state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .create_comment(input)
        .map_err(db_err)?;
    emit_spaces_refresh(&app);
    Ok(comment)
}

#[tauri::command]
pub fn spaces_search(state: State<'_, DbState>, query: String) -> Result<Vec<SearchResult>, String> {
    state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .search(&query)
        .map_err(db_err)
}

#[tauri::command]
pub fn spaces_get_sync_status(state: State<'_, DbState>) -> Result<SyncStatus, String> {
    Ok(state
        .0
        .lock()
        .map_err(|e| e.to_string())?
        .get_sync_status())
}

#[tauri::command]
pub fn spaces_open_document_window(
    app: AppHandle,
    document_id: String,
    title: String,
) -> Result<(), String> {
    let label = format!("doc-{document_id}");
    if let Some(win) = app.get_webview_window(&label) {
        let _ = win.set_focus();
        return Ok(());
    }

    let url = hash_url(&app, &format!("/document/{document_id}"))?;
    WebviewWindowBuilder::new(&app, label, url)
        .title(title)
        .inner_size(960.0, 720.0)
        .min_inner_size(640.0, 480.0)
        .build()
        .map_err(|e| e.to_string())?;
    Ok(())
}

#[tauri::command]
pub fn spaces_open_space_window(app: AppHandle, space_id: String) -> Result<(), String> {
    let label = format!("space-{space_id}");
    if let Some(win) = app.get_webview_window(&label) {
        let _ = win.set_focus();
        return Ok(());
    }

    let url = hash_url(&app, &format!("/space/{space_id}"))?;
    WebviewWindowBuilder::new(&app, label, url)
        .title("Space — Publshr")
        .inner_size(1280.0, 800.0)
        .min_inner_size(900.0, 600.0)
        .build()
        .map_err(|e| e.to_string())?;
    Ok(())
}
