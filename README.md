# publshr

Native desktop tools for **Publshr** — a Cursor-style macOS IDE with Supabase auth, plus **Spaces** (enterprise operations hub), **Media Monitoring**, **Planner**, and a legacy Swift App Space.

| Platform | Default install | Spaces (Electron) | Media Monitoring | Legacy App Space (Swift) |
|----------|-----------------|-------------------|------------------|--------------------------|
| **macOS** | `mac/publshr` → **Publshr.app** (IDE + auth) | `desktop/spaces` | `desktop/media-monitoring` | `native/publshr` → `./install-mac-app.sh` |
| **Linux** | CLI via `./install.sh` | `desktop/spaces` | `desktop/media-monitoring` | — |
| **Windows** | [`windows/`](windows/) — `publshr.exe` from [Releases](https://github.com/hiagoccss-svg/publshr.exe/releases) | `desktop/spaces` | `desktop/media-monitoring` | — |

## macOS — native desktop IDE (Swift/SwiftUI, not a web app)

**One install command** (always the same URL):

```bash
curl -fsSL "https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install-publshr-macos.sh" | bash
```

If you still see installer **v8**, GitHub CDN cached the old file — save and run (do not pipe the old URL):

```bash
curl -fsSL "https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install/macos/install-macos.sh" -o /tmp/publshr-install.sh && bash /tmp/publshr-install.sh
```

Opens the **Publshr Installer** window (native UI matching the app). Click **Install**, then sign in with email or biometrics.

**Download installer for your team** (zip — share on a website or drive):

| File | Link |
|------|------|
| **Publshr-Install-macos.zip** | [Releases → live → Publshr-Install-macos.zip](https://github.com/hiagoccss-svg/publshr.exe/releases/download/live/Publshr-Install-macos.zip) |
| **install script only** | [Publshr-install-macos.sh](https://github.com/hiagoccss-svg/publshr.exe/releases/download/live/Publshr-install-macos.sh) |
| **Full app tarball** | [Publshr-macos-aarch64.tar.gz](https://github.com/hiagoccss-svg/publshr.exe/releases/download/live/Publshr-macos-aarch64.tar.gz) |

Unzip **Publshr-Install-macos.zip** and double-click **Publshr Install.command**. See [mac/publshr/docs/INSTALL.md](mac/publshr/docs/INSTALL.md).

Installs **Publshr.app** to `/Applications` — a real macOS desktop application (Launchpad, native windows, offline cache). This is **not** Electron or a browser wrapper.

Or from a clone:

```bash
./install.sh
open /Applications/Publshr.app
```

**Push to `main` → live app updates.** The same install URL always works; GitHub Actions publishes the `live` release and the installed app applies it automatically ([docs](mac/publshr/docs/AUTO_UPDATE.md)).

### Features (mac/publshr)

- **Cursor-matched UI** — activity bar, sidebar, editor tabs, enterprise chat panel, status bar
- **Enterprise chat (Phases 1–4)** — channels, DMs, threads, reactions, files, voice notes, pins, AI summaries, search, planner shares, multi-window, permissions
- **Supabase Auth** — sign up, sign in, 6-digit email OTP, session persistence
- **Profile sync** — `public.profiles` via `handle_new_user` trigger

Redirect URL: `com.publshr.app://auth/callback` in [Auth URL configuration](https://supabase.com/dashboard/project/lboesdtsrqfvosznjpdy/auth/url-configuration).

## Spaces — Enterprise operations module

Cross-platform **Electron** desktop app: project + operations management, local-first SQLite, optional Supabase realtime.

```bash
cd desktop/spaces
npm install
npm run dev
```

See [`desktop/spaces/README.md`](desktop/spaces/README.md) for architecture, Phase 1 features, and Supabase setup.

## Media Monitoring — Enterprise media intelligence (Electron)

Cross-platform desktop module for PR and communications teams: monitor profiles, live coverage feed, saved articles, publication database, Supabase sync.

```bash
cd desktop/media-monitoring
npm install
npm run dev          # hot reload
# OR: npm run build && npm run start
make media-monitoring-start   # from repo root
```

Sign in with your Publshr account (create account + email OTP). Optional Touch ID unlock on macOS. See [`desktop/media-monitoring/README.md`](desktop/media-monitoring/README.md).

## Planner (communications OS)

Electron desktop module for PR, media, and editorial teams — timeline, board, calendar, editor windows, Supabase + SQLite local-first sync.

```bash
cd planner/desktop && npm install && npm run dev
```

See [planner/README.md](planner/README.md).

## macOS — App Space (ClickUp-style, Swift legacy)

Build from repo root (uses `native/publshr`, not the IDE package):

```bash
chmod +x install-mac-app.sh
./install-mac-app.sh
```

| ClickUp concept | In Publshr App Space |
|-----------------|----------------------|
| Workspace | Workspace + team members |
| Space / Folder / List | Sidebar hierarchy |
| Task | Status, priority, due date, assignees, tags, checklist, comments, subtasks |
| Views | List, Board (drag columns), Calendar, Table |

Data: `~/Library/Application Support/Publshr/app-space.json`. Git sync settings: gear icon in App Space.

## Linux / CLI

```bash
chmod +x install-local.sh
./install-local.sh
export PATH="$(pwd)/.local/bin:$PATH"
publshr --version
```

## Project layout

```
mac/publshr/                  # Canonical macOS IDE + Supabase (Publshr.app releases)
desktop/spaces/               # Spaces — Electron operations hub (Phase 1+)
desktop/media-monitoring/     # Media Monitoring desktop module (Electron)
planner/desktop/              # Communications Planner (Electron + React)
native/publshr/               # Legacy Swift App Space + Git sync (install-mac-app.sh)
windows/                      # Windows .exe from releases
```

## Build from source (IDE)

```bash
cd mac/publshr
swift build -c release --product PublshrApp
./scripts/build-macos-app.sh .build/release/PublshrApp 0.2.0 .
open Publshr.app
```

## Make

```bash
make help
make build
make install-local
make install
make media-monitoring-dev    # Media Monitoring Electron app
```
