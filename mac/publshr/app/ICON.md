# App icon

Upload **`icon.png`** at the **repository root** (GitHub web UI) or place it here as **`mac/publshr/app/icon.png`**.

Mark-only PNGs (transparent background) get a **white** holder automatically so black logos stay visible in the Dock: run `python3 scripts/apply-premium-icon-background.py` from `mac/publshr/`, or rely on `generate-app-icon.swift` during macOS `icon-build.sh`.

Before every macOS build, `scripts/sync-app-icon.sh` copies root **`icon.png`** into this folder when the files differ (checksum), so CI always picks up a new root upload even if this copy is older or smaller.

CI and local macOS builds generate:

- `AppIcon.icns` → `Publshr.app` (Dock / Finder)
- `PublshrInstaller.app` (installer window + Finder)
- `Publshr Install.command` custom icon in the release zip
