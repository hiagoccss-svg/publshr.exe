# App icon

Upload **`icon.png`** at the **repository root** (GitHub web UI) or place it here as **`mac/publshr/app/icon.png`**.

Upload your **mark-only** PNG (transparent background). Builds keep your logo colors and composite onto a **white** holder by default. Do not run `apply-premium-icon-background.py` unless you intentionally want a baked-in dark background (that script overwrites `icon.png`).

Optional: `PUBLSHR_ICON_PREMIUM_BG=1` during `icon-build.sh` adds the dark metallic holder without changing the mark asset on disk.

Before every macOS build, `scripts/sync-app-icon.sh` copies root **`icon.png`** into this folder when the files differ (checksum), so CI always picks up a new root upload even if this copy is older or smaller.

CI and local macOS builds generate:

- `AppIcon.icns` → `Publshr.app` (Dock / Finder)
- `PublshrInstaller.app` (installer window + Finder)
- `Publshr Install.command` custom icon in the release zip
