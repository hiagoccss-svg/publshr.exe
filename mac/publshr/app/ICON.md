# App icon (single source of truth)

Upload **`icon.png`** at the **repository root** only:

```text
publshr.exe/icon.png   ← edit / replace this file
```

Every macOS build runs `scripts/sync-app-icon.sh`, which normalizes that file onto a **full white** 1024×1024 canvas at `mac/publshr/app/icon.png`, then generates:

- `AppIcon.icns` → `Publshr.app` (Dock / Finder)
- `icon.png` in the app bundle → sign-in, sidebar, installer UI

There is no separate `logo.png`. Do not commit duplicate marks under `mac/publshr/app/` unless you are testing locally; CI always reads the repo root.

**Tip:** Use a mark on a **transparent** background at the root so the white canvas shows cleanly. Opaque dark fills in the PNG will stay visible on top of white.

Manual normalize (optional):

```bash
bash mac/publshr/scripts/sync-app-icon.sh
# or: swift mac/publshr/scripts/normalize-brand-icon.swift icon.png mac/publshr/app/icon.png 1024
```
