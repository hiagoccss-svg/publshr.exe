# publshr

Cross-platform publisher helper with a **desktop App Space** modeled after [ClickUp](https://clickup.com) — workspaces, spaces, folders, lists, tasks, and multiple views (List, Board, Calendar, Table).

| Platform | Location | Install |
|----------|----------|---------|
| **macOS / Linux** | [`native/publshr`](native/publshr) — Swift CLI (not `.exe`) | `./install-local.sh` on **this machine** |
| **Windows** | [`windows/`](windows/) — `publshr.exe` from releases | Download from [Releases](https://github.com/hiagoccss-svg/publshr.exe/releases) |

## macOS — real application in **Applications**

**Remove the old fake app first** (if you installed it before): delete `Publshr.app` from Applications, then:

```bash
cd ~/publshr.exe
git pull
chmod +x install-mac-app.sh
./install-mac-app.sh
```

This builds a **real SwiftUI app** (window UI, no Terminal). It installs **`Publshr.app`** to `~/Applications`.

### App Space (ClickUp-style)

The main window is your **App Space**:

| ClickUp concept | In Publshr |
|-----------------|------------|
| Workspace | Workspace with team members |
| Space | Space (sidebar sections) |
| Folder | Folder under a space |
| List | List with custom statuses |
| Task | Tasks with priority, due date, assignees, tags, checklist, comments, subtasks |
| Views | List, Board (drag between columns), Calendar, Table; Timeline/Gantt placeholders |

Data is stored locally at `~/Library/Application Support/Publshr/app-space.json`. Use the gear icon for **Git sync settings** (offline toggle, pull from GitHub).

- Works **offline** (toggle in app)
- When online, **Sync from GitHub** pulls latest from git branch `cursor/add-makefile-and-install-4aa6`
- After we push changes, open the app and tap **Sync from GitHub** (or relaunch)

`install-local.sh` is CLI-only inside `.local/` — **not** the Mac app in Applications.

## Linux / Mac — CLI only (inside this repo)

```bash
chmod +x install-local.sh
./install-local.sh
export PATH="$(pwd)/.local/bin:$PATH"
publshr --version
```

## System-wide install (optional)

```bash
./install.sh
# or: make install
```

Installs to `/opt/publshr` and `/usr/local/bin/publshr` (needs `curl` and `sudo`).

## Project layout

```
native/publshr/   # Mac & Linux Swift CLI (canonical)
windows/          # Windows .exe documentation (exe from releases)
mac/              # Pointer to native/ (legacy path)
```

## Make

```bash
make help
make build
make install-local   # this machine, project .local/
make install         # system-wide
```
