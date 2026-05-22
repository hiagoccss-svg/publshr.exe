# App icon

Canonical source: **`icon.png`** in this folder (1024×1024 or larger PNG).

You can also place **`icon.png`** at the repository root; macOS packaging copies it here before build.

CI and local macOS builds generate:

- `AppIcon.icns` → `Publshr.app` (Dock / Finder)
- `PublshrInstaller.app` (installer window + Finder)
- `Publshr Install.command` custom icon in the release zip
