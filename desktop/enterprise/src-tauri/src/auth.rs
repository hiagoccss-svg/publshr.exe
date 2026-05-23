use keyring::Entry;
use serde::{Deserialize, Serialize};
use std::sync::Mutex;
use tauri::State;

const SERVICE: &str = "com.publshr.enterprise";
const SESSION_ACCOUNT: &str = "supabase_session";

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AuthUser {
    pub id: String,
    pub email: String,
    pub display_name: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct StoredSession {
    pub access_token: String,
    pub refresh_token: String,
    pub expires_at: Option<i64>,
    pub user: AuthUser,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AuthSnapshot {
    pub user: Option<AuthUser>,
    pub access_token: Option<String>,
    pub refresh_token: Option<String>,
    pub expires_at: Option<i64>,
    pub workspace_id: Option<String>,
    pub cloud_validated: bool,
    pub biometric_enabled: bool,
}

pub struct AuthState {
    pub session: Mutex<Option<StoredSession>>,
    pub workspace_id: Mutex<Option<String>>,
    pub biometric_enabled: Mutex<bool>,
}

impl AuthState {
    pub fn new() -> Self {
        let session = load_session_from_keychain().ok().flatten();
        Self {
            session: Mutex::new(session),
            workspace_id: Mutex::new(None),
            biometric_enabled: Mutex::new(false),
        }
    }

    pub fn snapshot(&self) -> AuthSnapshot {
        let session = self.session.lock().unwrap();
        let workspace_id = self.workspace_id.lock().unwrap().clone();
        let biometric_enabled = *self.biometric_enabled.lock().unwrap();
        match session.as_ref() {
            Some(s) => AuthSnapshot {
                user: Some(s.user.clone()),
                access_token: Some(s.access_token.clone()),
                refresh_token: Some(s.refresh_token.clone()),
                expires_at: s.expires_at,
                workspace_id,
                cloud_validated: true,
                biometric_enabled,
            },
            None => AuthSnapshot {
                user: None,
                access_token: None,
                refresh_token: None,
                expires_at: None,
                workspace_id,
                cloud_validated: false,
                biometric_enabled,
            },
        }
    }
}

fn load_session_from_keychain() -> Result<Option<StoredSession>, String> {
    let entry = Entry::new(SERVICE, SESSION_ACCOUNT).map_err(|e| e.to_string())?;
    match entry.get_password() {
        Ok(raw) if !raw.is_empty() => serde_json::from_str(&raw)
            .map(Some)
            .map_err(|e| e.to_string()),
        Ok(_) => Ok(None),
        Err(keyring::Error::NoEntry) => Ok(None),
        Err(e) => Err(e.to_string()),
    }
}

fn save_session_to_keychain(session: &StoredSession) -> Result<(), String> {
    let entry = Entry::new(SERVICE, SESSION_ACCOUNT).map_err(|e| e.to_string())?;
    let raw = serde_json::to_string(session).map_err(|e| e.to_string())?;
    entry.set_password(&raw).map_err(|e| e.to_string())
}

fn clear_session_from_keychain() -> Result<(), String> {
    let entry = Entry::new(SERVICE, SESSION_ACCOUNT).map_err(|e| e.to_string())?;
    match entry.delete_password() {
        Ok(()) | Err(keyring::Error::NoEntry) => Ok(()),
        Err(e) => Err(e.to_string()),
    }
}

#[tauri::command]
pub fn auth_get_state(state: State<'_, AuthState>) -> AuthSnapshot {
    state.snapshot()
}

#[tauri::command]
pub fn auth_save_session(
    session: StoredSession,
    workspace_id: Option<String>,
    state: State<'_, AuthState>,
) -> Result<AuthSnapshot, String> {
    save_session_to_keychain(&session)?;
    {
        let mut guard = state.session.lock().unwrap();
        *guard = Some(session);
    }
    if let Some(ws) = workspace_id {
        *state.workspace_id.lock().unwrap() = Some(ws);
    }
    Ok(state.snapshot())
}

#[tauri::command]
pub fn auth_clear_session(state: State<'_, AuthState>) -> Result<AuthSnapshot, String> {
    clear_session_from_keychain()?;
    *state.session.lock().unwrap() = None;
    *state.workspace_id.lock().unwrap() = None;
    Ok(state.snapshot())
}

#[tauri::command]
pub fn auth_set_biometric_enabled(
    enabled: bool,
    state: State<'_, AuthState>,
) -> Result<AuthSnapshot, String> {
    *state.biometric_enabled.lock().unwrap() = enabled;
    Ok(state.snapshot())
}

#[tauri::command]
pub fn auth_set_workspace(workspace_id: String, state: State<'_, AuthState>) -> AuthSnapshot {
    *state.workspace_id.lock().unwrap() = Some(workspace_id);
    state.snapshot()
}
