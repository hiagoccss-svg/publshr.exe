# publshr — Mac & Linux (native CLI)

Swift CLI for **macOS and Linux**. This is **not** the Windows `.exe`; that stays under [`windows/`](../windows/).

## Build

```bash
cd native/publshr
swift build
```

## Install on this machine (project-local, no sudo)

From the **repository root**:

```bash
./install-local.sh
```

Installs to `.local/` in the repo:

- `.local/publshr/<version>/bin/publshr`
- `.local/bin/publshr` (wrapper on your PATH for this shell)

Then:

```bash
export PATH="$(pwd)/.local/bin:$PATH"
publshr --version
```

## System-wide install (optional, needs sudo)

```bash
./install.sh
```
