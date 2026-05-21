# publshr

Cross-platform publisher helper.

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

This installs **`Publshr.app`** to `~/Applications` — a native macOS workspace app (sidebar, editor, toolbar), not a separate updater.

- **Main window:** drafts library + editor (like a lightweight Cursor-style workspace)
- **Updates:** `Publshr → Settings (⌘,)` → **Updates** tab (background sync on launch)
- **Menu:** `Check for Updates…` under the app menu

Do **not** use `install-publshr.sh` on Mac — that installs the CLI to `/opt`, not this app.

`install-local.sh` is CLI-only in `.local/` — not the Mac app in Applications.

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
