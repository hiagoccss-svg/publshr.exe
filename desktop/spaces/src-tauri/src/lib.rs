pub mod commands;
pub mod db;
pub mod models;

use commands::DbState;
use db::SpacesDatabase;
use std::sync::Mutex;
use tauri::Manager;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .setup(|app| {
            if cfg!(debug_assertions) {
                app.handle().plugin(
                    tauri_plugin_log::Builder::default()
                        .level(log::LevelFilter::Info)
                        .build(),
                )?;
            }

            let app_data_dir = app
                .path()
                .app_data_dir()
                .expect("failed to resolve app data directory");
            let db_path = app_data_dir.join("spaces-cache").join("spaces.db");
            let database =
                SpacesDatabase::open(&db_path).expect("failed to open spaces sqlite database");
            app.manage(DbState(Mutex::new(database)));

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            commands::spaces_get_bootstrap,
            commands::spaces_list_spaces,
            commands::spaces_get_space,
            commands::spaces_create_space,
            commands::spaces_update_space,
            commands::spaces_list_folders,
            commands::spaces_create_folder,
            commands::spaces_update_folder,
            commands::spaces_list_lists,
            commands::spaces_create_list,
            commands::spaces_update_list,
            commands::spaces_list_tasks,
            commands::spaces_create_task,
            commands::spaces_update_task,
            commands::spaces_delete_task,
            commands::spaces_list_activity,
            commands::spaces_list_members,
            commands::spaces_list_approvals,
            commands::spaces_list_documents,
            commands::spaces_get_document,
            commands::spaces_create_document,
            commands::spaces_update_document,
            commands::spaces_list_files,
            commands::spaces_create_file,
            commands::spaces_list_workspace_documents,
            commands::spaces_list_workspace_approvals,
            commands::spaces_list_workspace_files,
            commands::spaces_list_workspace_tasks,
            commands::spaces_list_workspace_members,
            commands::spaces_list_workspace_activity,
            commands::spaces_list_coverage,
            commands::spaces_list_notifications,
            commands::spaces_get_workspace_summary,
            commands::spaces_list_comments,
            commands::spaces_create_comment,
            commands::spaces_search,
            commands::spaces_get_sync_status,
            commands::spaces_open_document_window,
            commands::spaces_open_space_window,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
