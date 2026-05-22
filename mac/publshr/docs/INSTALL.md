# Install Publshr on macOS

Publshr is a **native Swift/SwiftUI desktop app**. Users install once; updates apply automatically.

## Download files (share these links)

| File | Purpose | URL pattern |
|------|---------|-------------|
| **Publshr-Install-macos.zip** | Lightweight installer for your team (script + double-click) | `https://github.com/hiagoccss-svg/publshr.exe/releases/download/live/Publshr-Install-macos.zip` |
| **Publshr-install-macos.sh** | Shell script only | `https://github.com/hiagoccss-svg/publshr.exe/releases/download/live/Publshr-install-macos.sh` |
| **Publshr-macos-aarch64.tar.gz** | Full app bundle (advanced / IT) | `https://github.com/hiagoccss-svg/publshr.exe/releases/download/live/Publshr-macos-aarch64.tar.gz` |

If the app opens like a broken web/CLI bundle, the `live` release may be outdated. Re-run the installer (it will rebuild a correct native app from source), or merge latest `main` and wait for CI to republish `live`.

Until the `live` release is published, use the **main** branch script:

```bash
curl -fsSL "https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install-publshr-macos.sh" | bash
```

Or download and run:

```bash
curl -fsSL "https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install-publshr-macos.sh" -o ~/Downloads/Publshr-install-macos.sh
chmod +x ~/Downloads/Publshr-install-macos.sh
bash ~/Downloads/Publshr-install-macos.sh
```

## For end users (recommended)

### One-line install

```bash
curl -fsSL "https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install-publshr-macos.sh" | bash
```

If Terminal shows **installer v8**, save the uncached script instead:

```bash
curl -fsSL "https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install/macos/install-macos.sh" -o /tmp/publshr-install.sh && bash /tmp/publshr-install.sh
```

1. Downloads the current **live** build from GitHub Releases  
2. Opens **Publshr Installer** (native UI with app icon)  
3. Installs to `/Applications/Publshr.app` and launches the app  

### Zip installer (for a download page)

1. Download **Publshr-Install-macos.zip** from [Releases](https://github.com/hiagoccss-svg/publshr.exe/releases) (tag `live`)  
2. Unzip  
3. Double-click **Publshr Install.command**  
4. Follow prompts  

## From a git clone

```bash
./install-macos.sh
# or
./install/macos/Publshr\ Install.command
```

## Requirements

- macOS 14+  
- Apple Silicon (aarch64) build on `live` channel today  
- Network access to `github.com`  
- Admin password for `/Applications` (one time)  

## After install

- App: `/Applications/Publshr.app`  
- CLI (optional): `/usr/local/bin/publshr`  
- Updates: automatic — see [AUTO_UPDATE.md](./AUTO_UPDATE.md)  

## Enterprise checklist

See [ENTERPRISE_DESKTOP.md](./ENTERPRISE_DESKTOP.md) for signing, notarization, and MDM notes.
