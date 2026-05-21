# publshr

CLI matching Windows `publshr.exe`. Installs to **`/opt/publshr/<version>`** with **`/usr/local/bin/publshr`**.

## Install

```bash
./install.sh
```

Uses `sudo` automatically. Downloads a GitHub release when available; otherwise builds via `scripts/package-release.sh`.

## Package a release tarball

```bash
chmod +x scripts/package-release.sh
./scripts/package-release.sh 0.1.0
```

Produces `dist/publshr-0.1.0-<os>-<arch>.tar.gz`.
