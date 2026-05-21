# publshr

Cross-platform publisher helper.

| Platform | Install |
|----------|---------|
| Windows | `publshr.exe` (release assets) |
| macOS / Linux | `./install.sh` → `/opt/publshr` + `/usr/local/bin/publshr` |

## Install

From **any directory** (Mac or Linux, requires `curl` and `sudo`):

```bash
curl -fsSL https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/cursor/add-mac-publshr-9411/install-publshr.sh | bash
```

Or clone the repo and run:

```bash
git clone https://github.com/hiagoccss-svg/publshr.exe.git
cd publshr.exe
git checkout cursor/add-mac-publshr-9411
./install.sh
```

1. Downloads the matching release from GitHub (`publshr-VERSION-{macos|linux}-{arch}.tar.gz`)
2. If no release exists, builds from source
3. Installs to `/opt/publshr/VERSION` and `/usr/local/bin/publshr`

Verify:

```bash
publshr --version
```

**macOS:** Open **Finder → Applications → Publshr** (also in Launchpad). The installer is not a `.dmg` wizard — it is a command-line installer that places `Publshr.app` in Applications and will prompt for your Mac password.

Uninstall:

```bash
./install.sh --uninstall
```

## macOS app source

Swift package: [`mac/publshr`](mac/publshr)
