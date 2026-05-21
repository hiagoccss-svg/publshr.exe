# publshr

Cross-platform publisher helper.

| Platform | Install |
|----------|---------|
| Windows | `publshr.exe` (release assets) |
| macOS / Linux | `./install.sh` → `/opt/publshr` + `/usr/local/bin/publshr` |

## Install on your computer (macOS / Linux)

No clone required — downloads the release and installs to `/opt/publshr` and `/usr/local/bin/publshr` (needs `curl` and `sudo`):

```bash
curl -fsSL https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/cursor/add-mac-publshr-9411/install-publshr.sh | bash
```

Verify:

```bash
publshr --version
```

## Install from a git clone

```bash
git clone https://github.com/hiagoccss-svg/publshr.exe.git
cd publshr.exe
git checkout cursor/add-mac-publshr-9411   # branch with mac app + Makefile
./install.sh
```

Or with Make (requires [Swift](https://www.swift.org/install/) if the release download fails):

```bash
make install
```

`./install.sh` will:

1. Download the matching release from GitHub (`publshr-VERSION-{macos|linux}-{arch}.tar.gz`)
2. If no release exists, build from source under `mac/publshr`
3. Install to `/opt/publshr/VERSION` and `/usr/local/bin/publshr`

Uninstall:

```bash
./install.sh --uninstall
```

## Windows

Use `publshr.exe` from [GitHub Releases](https://github.com/hiagoccss-svg/publshr.exe/releases) (the `.exe` is not removed from this repo).

## macOS app source

Swift package: [`mac/publshr`](mac/publshr)

## Make targets

```bash
make help        # list targets
make build       # debug build
make install     # package + install system-wide
make clean       # remove build artifacts
```
