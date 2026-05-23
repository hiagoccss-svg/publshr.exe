# Download Publshr for Mac

Every merge to `main` publishes a fresh build on the **`live`** release. Use the disk image or zip — not a Terminal one-liner.

## Download (recommended)

**[Publshr-Install-macos.dmg](https://github.com/hiagoccss-svg/publshr.exe/releases/download/live/Publshr-Install-macos.dmg)**

(GitHub → Releases → tag **`live`** → asset **`Publshr-Install-macos.dmg`**)

## Install

1. Open **`Publshr-Install-macos.dmg`**
2. Double-click **`PublshrInstaller.app`**
3. If macOS blocks it: **right-click** → **Open** → **Open**
4. Click **Install** — Publshr goes to **`~/Applications/Publshr.app`** and launches

The disk image includes the full app and the native installer UI. No second download.

## Zip alternative

**[Publshr-Install-macos.zip](https://github.com/hiagoccss-svg/publshr.exe/releases/download/live/Publshr-Install-macos.zip)**

1. Unzip  
2. Double-click **`Publshr Install.command`** (opens the same GUI installer)

## What’s inside

| Item | Purpose |
|------|---------|
| `PublshrInstaller.app` | Branded install wizard (recommended) |
| `Publshr.app` | Full native IDE (Chat, Spaces, Settings) |
| `Applications` | Drag-to-install shortcut (optional) |
| `VERSION.txt` | Build label shown in the installer |

## Updates

After install, Publshr polls the **`live`** channel every 30 seconds, verifies SHA-256, and applies updates in place. See [mac/publshr/docs/AUTO_UPDATE.md](mac/publshr/docs/AUTO_UPDATE.md).

## Terminal (optional)

```bash
./install-macos.sh
```

Downloads the live DMG and opens **PublshrInstaller.app**. For IT scripting, use **`Publshr-macos-aarch64.tar.gz`** on the same release.

## Apple signing

When GitHub Actions secrets `DEVELOPER_ID_APPLICATION`, `APPLE_ID`, and `APPLE_APP_SPECIFIC_PASSWORD` are configured, CI signs and notarizes the DMG. Without them, use **right-click → Open** on first launch.
