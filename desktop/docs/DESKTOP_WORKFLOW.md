# Desktop app workflow — dev hot reload + installed auto-update

**Tauri-first:** new work uses Tauri 2 (Rust + OS webview). See [TAURI_DESKTOP.md](./TAURI_DESKTOP.md). **Spaces** ships on Tauri by default; Media Monitoring and Planner still use legacy Electron until migrated.

The native **Publshr macOS IDE** (`mac/publshr`) uses its own `live` channel — see [AUTO_UPDATE.md](../../mac/publshr/docs/AUTO_UPDATE.md).

## Two modes

| Mode | When | What happens |
|------|------|----------------|
| **Development** | Daily work in Cursor | `npm run dev` opens a **native window** (Tauri or legacy Electron) with Vite HMR. No install, no GitHub release. |
| **Installed test** | QA / staging on Mac or Windows | Install once. Tauri: `tauri-plugin-updater` (planned). Legacy Electron: app bundle + shell split — see below. |

Supabase handles auth, data, and realtime only — **not** desktop installation.

## Development (hot reload)

From the app directory:

```bash
# Spaces (Tauri — default)
cd desktop/spaces && npm install && npm run dev
# Legacy: npm run dev:electron

# Media Monitoring
cd desktop/media-monitoring && npm install && npm run dev
# or: make media-monitoring-dev

# Planner
cd planner/desktop && npm install && npm run dev
```

- Opens a native desktop window (not a browser tab).
- **Spaces:** `tauri dev` runs Vite + Rust; SQLite lives in app data via Rust (`spaces-cache/spaces.db`).
- **Legacy Electron apps:** `electron-vite dev`; SQLite and sessions under `userData`.
- Optional: `PUBLSHR_UPDATE_CHANNEL=dev` when testing update logic in a packaged build.

## Installed test (auto-update)

### Install once (shell)

Build or download the installer for your product and OS:

```bash
cd desktop/spaces
npm run tauri:build   # Tauri installers (preferred)
npm run dist:shell    # legacy Electron shell only
```

Install the `.dmg` / `.exe` / `.AppImage` once. User data lives in:

- macOS: `~/Library/Application Support/<app>/`
- Windows: `%APPDATA%/<app>/`

Sessions (`supabase-session.json`), biometric tokens, and SQLite DBs are **never** removed by app-bundle updates.

### Update channels (GitHub)

| Channel | Release tag pattern | Use |
|---------|---------------------|-----|
| **dev** | `{product}-dev` | Fast iteration on installed build |
| **staging** | `{product}-staging` | Realistic pre-production testing (default on `main` CI) |
| **production** | `{product}-production` | End users |

Products: `spaces`, `media-monitoring`, `planner`.

Set channel on the installed app:

```bash
export PUBLSHR_UPDATE_CHANNEL=staging   # dev | staging | production
```

### What gets updated

1. **App bundle (frontend)** — `Publshr-{product}-app-*.zip`  
   - React UI, assets, renderer only.  
   - Downloaded to `userData/app-bundles/`, verified with SHA-256.  
   - **Restart** the app to load the new bundle (no reinstall).

2. **Shell (native)** — `Publshr-{product}-shell-*.zip` / `.dmg` / `.exe`  
   - Electron main, preload, native deps.  
   - Via `electron-updater` when the shell release changes.  
   - Rebuild installers only when this layer changes.

Manifest per channel: `https://github.com/hiagoccss-svg/publshr.exe/releases/download/{product}-{channel}/{product}-desktop-manifest.json`

### Logs

`~/Library/Application Support/<Product>/updates/last-update.log` (or Windows equivalent).

IPC from renderer (optional UI):

- `desktop:getUpdateStatus`
- `desktop:checkForUpdates`
- `desktop:restartToUpdate`
- `desktop:rollbackAppBundle`

## CI pipeline

Workflow: [`.github/workflows/deliver-desktop.yml`](../../.github/workflows/deliver-desktop.yml)

On push to `main` (desktop paths) or manual dispatch:

1. Build renderer (`npm run build`).
2. Zip **app bundle** and upload to `{product}-staging` (or selected channel).
3. On macOS runners, optionally build **shell** zip.
4. Write `{product}-desktop-manifest.json` with versions and checksums.

## Native macOS IDE (separate product)

```bash
curl -fsSL "https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install-macos.sh" | bash
```

Uses the **`live`** channel (full `Publshr.app` tarball). Same idea: install once, auto-update in place, user data preserved.

## Checklist for contributors

- [ ] Daily UI work → `npm run dev` only.
- [ ] Changed **renderer only** → push to `main`; staging app bundle updates automatically.
- [ ] Changed **main/preload/Electron** → bump shell, run `npm run dist:shell`, ensure CI publishes shell asset.
- [ ] Never store auth tokens in `localStorage`; use main-process session store + `safeStorage` for biometrics (Media Monitoring pattern).

## Related

- [TAURI_DESKTOP.md](./TAURI_DESKTOP.md)
- [ENTERPRISE_DESKTOP.md](../../mac/publshr/docs/ENTERPRISE_DESKTOP.md)
- [AUTO_UPDATE.md](../../mac/publshr/docs/AUTO_UPDATE.md)
- Shared updater: [`shared/electron/updater/`](../../shared/electron/updater/)
