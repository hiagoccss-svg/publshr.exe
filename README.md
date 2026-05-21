# publshr

Cross-platform publisher helper.

| Platform | Install |
|----------|---------|
| Windows | `publshr.exe` (release assets) |
| macOS / Linux | `./install.sh` → `/opt/publshr` + `/usr/local/bin/publshr` |

## Install

Requires `curl` and `sudo` (installs system-wide):

```bash
./install.sh
```

1. Downloads the matching release from GitHub (`publshr-VERSION-{macos|linux}-{arch}.tar.gz`)
2. If no release exists, builds from source
3. Installs to `/opt/publshr/VERSION` and `/usr/local/bin/publshr`

Verify:

```bash
publshr --version
```

Uninstall:

```bash
./install.sh --uninstall
```

## macOS app source

Swift package: [`mac/publshr`](mac/publshr)
