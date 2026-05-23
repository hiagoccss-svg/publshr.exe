mod auth;
mod commands;
mod db;
mod platform;

use auth::{
    auth_clear_session, auth_get_state, auth_save_session, auth_set_biometric_enabled,
    auth_set_workspace, AuthState,
};
use db::enterprise_migrations;
use platform::platform_get_info;
use publshr_spaces_lib::commands::DbState as SpacesDbState;
use publshr_spaces_lib::db::SpacesDatabase;
use std::sync::Mutex;
use tauri::Manager;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_process::init())
        .plugin(
            tauri_plugin_sql::Builder::default()
                .add_migrations("sqlite:enterprise.db", enterprise_migrations())
                .build(),
        )
        .plugin(tauri_plugin_store::Builder::new().build())
        .plugin(tauri_plugin_notification::init())
        .plugin(tauri_plugin_opener::init())
        .setup(|app| {
            #[cfg(desktop)]
            app.handle()
                .plugin(tauri_plugin_updater::Builder::new().build())?;

            let app_data_dir = app
                .path()
                .app_data_dir()
                .expect("failed to resolve app data directory");
            let db_path = app_data_dir.join("spaces-cache").join("spaces.db");
            let database =
                SpacesDatabase::open(&db_path).expect("failed to open spaces sqlite database");
            app.manage(SpacesDbState(Mutex::new(database)));

            Ok(())
        })
        .manage(AuthState::new())
        .invoke_handler(tauri::generate_handler![
            platform_get_info,
            auth_get_state,
            auth_save_session,
            auth_clear_session,
            auth_set_biometric_enabled,
            auth_set_workspace,
            publshr_spaces_lib::commands::spaces_get_bootstrap,
            publshr_spaces_lib::commands::spaces_list_spaces,
            publshr_spaces_lib::commands::spaces_get_space,
            publshr_spaces_lib::commands::spaces_create_space,
            publshr_spaces_lib::commands::spaces_update_space,
            publshr_spaces_lib::commands::spaces_list_folders,
            publshr_spaces_lib::commands::spaces_create_folder,
            publshr_spaces_lib::commands::spaces_update_folder,
            publshr_spaces_lib::commands::spaces_list_lists,
            publshr_spaces_lib::commands::spaces_create_list,
            publshr_spaces_lib::commands::spaces_update_list,
            publshr_spaces_lib::commands::spaces_list_tasks,
            publshr_spaces_lib::commands::spaces_create_task,
            publshr_spaces_lib::commands::spaces_update_task,
            publshr_spaces_lib::commands::spaces_delete_task,
            publshr_spaces_lib::commands::spaces_list_activity,
            publshr_spaces_lib::commands::spaces_list_members,
            publshr_spaces_lib::commands::spaces_list_approvals,
            publshr_spaces_lib::commands::spaces_list_documents,
            publshr_spaces_lib::commands::spaces_get_document,
            publshr_spaces_lib::commands::spaces_create_document,
            publshr_spaces_lib::commands::spaces_update_document,
            publshr_spaces_lib::commands::spaces_list_files,
            publshr_spaces_lib::commands::spaces_create_file,
            publshr_spaces_lib::commands::spaces_list_workspace_documents,
            publshr_spaces_lib::commands::spaces_list_workspace_approvals,
            publshr_spaces_lib::commands::spaces_list_workspace_files,
            publshr_spaces_lib::commands::spaces_list_workspace_tasks,
            publshr_spaces_lib::commands::spaces_list_workspace_members,
            publshr_spaces_lib::commands::spaces_list_workspace_activity,
            publshr_spaces_lib::commands::spaces_list_notifications,
            publshr_spaces_lib::commands::spaces_list_coverage,
            publshr_spaces_lib::commands::spaces_get_workspace_summary,
            publshr_spaces_lib::commands::spaces_list_comments,
            publshr_spaces_lib::commands::spaces_create_comment,
            publshr_spaces_lib::commands::spaces_search,
            publshr_spaces_lib::commands::spaces_get_sync_status,
            publshr_spaces_lib::commands::spaces_open_document_window,
            publshr_spaces_lib::commands::spaces_open_space_window,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
