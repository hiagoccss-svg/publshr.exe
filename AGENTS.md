# AGENTS.md

## Cursor Cloud specific instructions

### Project overview

`publshr` is a cross-platform CLI tool (matching Windows `publshr.exe`). The main code lives under `mac/publshr/` as a Swift Package Manager project requiring Swift >= 5.9.

### Swift toolchain

The update script installs Swift 5.10.1 to `/opt/swift/usr/bin` and adds it to PATH via `~/.bashrc`. Verify with `swift --version`.

### Build and run

```bash
cd mac/publshr
swift build              # debug build
swift build -c release   # release build
.build/debug/publshr --help
.build/debug/publshr --version
```

### Enterprise chat (mac IDE)

Chat lives under `mac/publshr/Sources/PublshrApp/Chat/`. See `mac/publshr/docs/CHAT_SYSTEM.md` and `mac/publshr/docs/CHAT_CLICKUP_UI.md` (ClickUp-style sidebar, filters, badges). Supabase migrations: `20260521180000_chat_presence_and_members.sql`, `20260521200000_chat_phases_2_4.sql`.

### Enterprise platform (mac IDE)

Subscriptions, onboarding, devices, privacy, files, and call signaling: `mac/publshr/Sources/PublshrApp/Enterprise/` and `Views/Settings/`. See `mac/publshr/docs/ENTERPRISE_PLATFORM.md`. Migration: `mac/publshr/supabase/migrations/002_enterprise_platform.sql`.

### Tests

No automated test suite exists yet (`swift test` reports "no tests found"). If tests are added later, run them with `swift test` from `mac/publshr/`.

### Lint

No dedicated linter is configured. Swift compiler warnings serve as the primary code quality check during `swift build`.

### Release packaging

```bash
cd mac/publshr
chmod +x scripts/package-release.sh
bash scripts/package-release.sh <version>
```

Produces `dist/publshr-<version>-<os>-<arch>.tar.gz`.

### macOS install and live updates

Every push to **`main`** publishes a new **`live`** build (icons, UI, shell, features, colors — full `Publshr.app` tarball). Installed apps check `VERSION.txt` via fixed download URLs every **30s** (build + version + commit + package digest + shell tag), auto-install **in place**, and refresh Chat/Spaces from Supabase on the same schedule. Settings → **Sync now** runs GitHub live + Supabase together. See `mac/publshr/docs/ENTERPRISE_INSTALL_AND_LIVE.md`.

Stable installer (single file, fixed URL):

```bash
curl -fsSL "https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install-macos.sh" | bash
```

Every push to `main` runs `.github/workflows/deliver-macos.yml`, publishing the **`live`** release asset `Publshr-macos-aarch64.tar.gz`. The installed app auto-updates from that channel. See `mac/publshr/docs/AUTO_UPDATE.md`.

### Desktop transparency (Electron + macOS IDE)

Translucent **shell** (wallpaper bleeds through) vs solid **content** (cards, editors, tables). Shared CSS: `shared/design/desktop-transparency.css` (via `library-glass.css`). Electron windows: `shared/electron/glass-window.ts`. Docs: `shared/design/DESKTOP_TRANSPARENCY.md`. macOS IDE: `WorkspaceDesktopBackdrop`, `MainWindowChrome`.

### Desktop workflow (dev + installed auto-update)

See **`desktop/docs/DESKTOP_WORKFLOW.md`**. Summary:

- **Dev:** `npm run dev` (or `make spaces-dev` / `planner-dev` / `media-monitoring-dev`) — native Electron window + Vite HMR; no reinstall.
- **Installed:** Install shell once; **app bundle** updates from GitHub (`dev` / `staging` / `production`); **shell** installer only when main/preload changes.
- Shared updater: `shared/electron/updater/`; CI: `.github/workflows/deliver-desktop.yml`.

### Spaces (macOS IDE + Electron)

The **native Spaces** module lives in `mac/publshr/Sources/PublshrApp/Spaces/` (SwiftUI + Supabase + SQLite cache). See `mac/publshr/docs/SPACES_SYSTEM.md`. Schema: `mac/publshr/supabase/migrations/001_spaces_schema.sql`.

The standalone **Spaces** Electron app lives in `desktop/spaces/` (React + TypeScript + Tailwind + SQLite + Supabase). Enterprise modules (Chat, Spaces, Whiteboard, Media Monitoring, Planner) ship **inside `Publshr.app`** first — see `mac/publshr/docs/ENTERPRISE_DESKTOP.md`. The renderer (Electron) and macOS IDE Spaces module must stay identical — see `shared/spaces/PARITY.md` and `shared/spaces/view-modes.ts`.

```bash
cd desktop/spaces
npm install
npm run dev         # native window + hot reload
npm run build       # production bundle
npm run dist:shell  # installer when Electron shell changed
npm run typecheck
```

No demo seed data on first run. Configure optional Supabase via `.env` from `.env.example`.

### Gotchas

- On Ubuntu, Swift requires `libncurses6`, `libcurl4`, and `libxml2` runtime libraries. The update script installs these automatically.
- The `@main` attribute in `main.swift` uses Swift's entry-point API; this requires Swift >= 5.3 but the package declares `swift-tools-version: 5.9`.
- macOS IDE + chat ship on `main`; CI publishes the `live` release for install and in-app updates.
- **Media Monitoring** desktop app: `desktop/media-monitoring/` — `npm run dev` or `make media-monitoring-dev`. Dark three-column shell (activity bar, workspace sidebar, coverage detail panel); Supabase auth + optional Touch ID on macOS.
- **Planner module** lives in `planner/desktop/` (Electron + React + TypeScript + Tailwind + Supabase + SQLite). Run `npm run dev` from that directory after `npm install`.
