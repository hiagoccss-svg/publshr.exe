# publshr

Cross-platform publisher workspace.

## macOS app (Cursor-style layout + ClickUp-style Chat & Spaces)

Install:

```bash
cd ~/publshr.exe
git pull
./install-mac-app.sh
```

Open **Applications → Publshr**. You get:

| Area | Like |
|------|------|
| Dark layout, icon rail, sidebars | **Cursor** |
| **Chat** — channels, DMs, messages, composer | **ClickUp Chat** |
| **Spaces** — spaces → folders → lists | **ClickUp Spaces** |

- Works **offline** (data in `~/Library/Application Support/Publshr/workspace.json`)
- **Settings (⌘,)** → Updates — Git sync when online (not a separate updater app)

Windows: `publshr.exe` from [Releases](https://github.com/hiagoccss-svg/publshr.exe/releases).

## Layout

```
native/publshr/   # SwiftUI Mac app + CLI
windows/          # Windows .exe docs
```
