# publshr

Native desktop tools for **Publshr** — a Cursor-style macOS IDE with Supabase auth, plus a **ClickUp-style App Space** for project management.

| Platform | Default install | App Space (ClickUp-style) |
|----------|-----------------|---------------------------|
| **macOS** | `mac/publshr` → **Publshr.app** (IDE + auth) | `native/publshr` → `./install-mac-app.sh` |
| **Linux** | CLI via `./install.sh` | — |
| **Windows** | [`windows/`](windows/) — `publshr.exe` from [Releases](https://github.com/hiagoccss-svg/publshr.exe/releases) | — |

## macOS — IDE app (main)

```bash
curl -fsSL https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/main/install-publshr.sh | bash
```

Or from a clone:

```bash
./install.sh
open /Applications/Publshr.app
```

### Features (mac/publshr)

- **Cursor-matched UI** — activity bar, sidebar, editor tabs, AI chat panel, status bar
- **Supabase Auth** — sign up, sign in, 6-digit email OTP, session persistence
- **Profile sync** — `public.profiles` via `handle_new_user` trigger

Redirect URL: `com.publshr.app://auth/callback` in [Auth URL configuration](https://supabase.com/dashboard/project/lboesdtsrqfvosznjpdy/auth/url-configuration).

## macOS — App Space (ClickUp-style)

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

## Desktop — Media Monitoring (Electron)

Enterprise media intelligence module (Phase 1 MVP):

```bash
cd desktop/media-monitoring
npm install
npm run dev
```

Stack: Electron, React, TypeScript, Tailwind, SQLite local cache, Supabase schema. See [`desktop/media-monitoring/README.md`](desktop/media-monitoring/README.md).

## Project layout

```
mac/publshr/                  # Canonical macOS IDE + Supabase (Publshr.app releases)
native/publshr/               # App Space + Git sync shell (install-mac-app.sh)
desktop/media-monitoring/     # Media Monitoring desktop module (Electron)
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
```
