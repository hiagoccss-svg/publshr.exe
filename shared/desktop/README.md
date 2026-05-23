# Shared desktop contracts

Cross-platform types and env conventions for **Publshr Enterprise** (Tauri) and legacy Electron modules.

- Auth snapshots must never use `localStorage` for tokens.
- Session persistence: OS keychain (Tauri `keyring` / Electron `safeStorage` + main-process file).
- SQLite caches live in the app data directory, never inside the install bundle.

See `mac/publshr/docs/DESKTOP_TAURI_PLATFORM.md`.
