# Install Publshr on macOS

Publshr is a **native Swift/SwiftUI desktop app**. Users install once; updates apply automatically.

## Download files (share these links)

| File | Purpose | URL pattern |
|------|---------|-------------|
| **Publshr-Install-macos.dmg** | Recommended — disk image + GUI installer | `https://github.com/hiagoccss-svg/publshr.exe/releases/download/live/Publshr-Install-macos.dmg` |
| **Publshr-Install-macos.zip** | Same payload as DMG | `https://github.com/hiagoccss-svg/publshr.exe/releases/download/live/Publshr-Install-macos.zip` |
| **Publshr-macos-aarch64.tar.gz** | In-app updater / IT | `https://github.com/hiagoccss-svg/publshr.exe/releases/download/live/Publshr-macos-aarch64.tar.gz` |

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

### Disk image (GUI installer)

1. Download **Publshr-Install-macos.dmg** from [Releases](https://github.com/hiagoccss-svg/publshr.exe/releases/tag/live)  
2. Open the disk image  
3. Double-click **PublshrInstaller.app**  
4. Click **Install** — app installs to `~/Applications/Publshr.app` and opens  

### Zip (same installer)

1. Download **Publshr-Install-macos.zip**  
2. Unzip and double-click **Publshr Install.command** (opens **PublshrInstaller.app**)  

### Terminal helper

```bash
./install-macos.sh
```

Downloads the live DMG and opens **PublshrInstaller.app** (no `curl | bash` pipe).

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

See [APPLE_MAC_DISTRIBUTION.md](./APPLE_MAC_DISTRIBUTION.md) for Developer ID + notarization (normal open without Right-click → Open). See [ENTERPRISE_DESKTOP.md](./ENTERPRISE_DESKTOP.md) for MDM notes.
