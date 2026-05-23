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
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
