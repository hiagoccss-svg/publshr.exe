# Download Publshr for Mac (one file)

This is the **only** installer you need. Every change merged to `main` is built into this zip automatically.

## Download

**[Publshr-Install-macos.zip](https://github.com/hiagoccss-svg/publshr.exe/releases/download/live/Publshr-Install-macos.zip)**  
(GitHub → Releases → tag **`live`** → asset **`Publshr-Install-macos.zip`**)

## Install

1. Download **`Publshr-Install-macos.zip`**
2. Double-click to unzip
3. Double-click **`Publshr Install.command`**
4. If macOS says the app is from an unidentified developer: **right-click** `Publshr Install.command` → **Open** → **Open**
5. Publshr installs to **`~/Applications/Publshr.app`** and launches

The zip contains the full **`Publshr.app`** — no extra download during install.

## What’s inside

| Item | Purpose |
|------|---------|
| `Publshr.app` | Native Mac IDE (Chat, Spaces, Settings) |
| `Publshr Install.command` | Double-click installer |
| `install-macos.sh` | Terminal install (same result) |
| `README.txt` | Quick steps |

## Supabase

The app ships connected to your Publshr Supabase project. Sign in, confirm email if needed, select or create a **workspace**, then use **Chat** and **Spaces**.

## Updates

Installed apps update from the same **`live`** release on GitHub. You can also download a fresh zip anytime and run **Publshr Install.command** again.

## Alternative (Terminal)

```bash
curl -fsSL "https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install-macos.sh" | bash
```
