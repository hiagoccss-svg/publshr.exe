# publshr

Cross-platform publisher helper.

| Platform | Location | Install |
|----------|----------|---------|
| **macOS / Linux** | [`native/publshr`](native/publshr) — Swift CLI (not `.exe`) | `./install-local.sh` on **this machine** |
| **Windows** | [`windows/`](windows/) — `publshr.exe` from releases | Download from [Releases](https://github.com/hiagoccss-svg/publshr.exe/releases) |

## macOS — install in **Applications** (shows in Apps / Spotlight)

`install-local.sh` only puts the CLI inside the project folder (`.local/`). It does **not** appear in Applications.

On your Mac, run:

```bash
chmod +x install-mac-app.sh
./install-mac-app.sh
```

That installs **`Publshr.app`** to `~/Applications` (or use `--applications` for `/Applications` with sudo). Then open **Finder → Applications** or press **Cmd+Space** and type **Publshr**.

```bash
open ~/Applications/Publshr.app
```

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
