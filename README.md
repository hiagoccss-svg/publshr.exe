# publshr

Cross-platform publisher helper.

| Platform | Location | Install |
|----------|----------|---------|
| **macOS / Linux** | [`native/publshr`](native/publshr) — Swift CLI (not `.exe`) | `./install-local.sh` on **this machine** |
| **Windows** | [`windows/`](windows/) — `publshr.exe` from releases | Download from [Releases](https://github.com/hiagoccss-svg/publshr.exe/releases) |

## Install on this Linux / Mac machine (in this repo)

No sudo. Builds the native app and installs under `.local/` in the project:

```bash
chmod +x install-local.sh
./install-local.sh
```

Use it in your shell:

```bash
export PATH="$(pwd)/.local/bin:$PATH"
publshr --version
```

Or:

```bash
make install-local
export PATH="$(pwd)/.local/bin:$PATH"
publshr --help
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
