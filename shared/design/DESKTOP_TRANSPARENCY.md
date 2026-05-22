# Desktop transparency system

Native-feeling translucent shells for Publshr desktop apps. The **OS wallpaper** shows through frame chrome; **content** stays readable.

## Layer model

| Layer | What | Electron CSS | macOS Swift |
|-------|------|----------------|-------------|
| 0 | Wallpaper (behind window) | Transparent `BrowserWindow` + vibrancy/Mica | `WorkspaceDesktopBackdrop` |
| 1 | App shell (title bar, sidebars, nav) | `.dt-chrome`, `.dt-chrome-sidebar`, `.dt-chrome-toolbar` | `LibraryGlassDesign.sidebarGlassFill` + materials |
| 2 | Floating panels (context, command palette) | `.dt-glass-panel`, `.dt-glass-overlay` | `LibraryFloatingPanel` |
| 3 | Working content (cards, editors, tables) | `.dt-content-surface`, `.library-card` | `LibraryCardStyle` / solid fills |

## Rules

- **Transparent:** app background, navigation shell, sidebars, toolbars, empty spacing, overlays.
- **Solid / semi-solid:** editors, text fields, cards, messages, tables.
- **Separators:** `1px` optical lines (`--dt-divider`), stronger than shell fill — not heavy shadows.
- **No fake gradients** pretending to be transparency; use `backdrop-filter` + native window materials.

## Electron

- Shared window helper: `shared/electron/glass-window.ts`
- Shared CSS: `shared/design/desktop-transparency.css` (imported via `library-glass.css`)
- Set `data-glass-theme="light"` or `"dark"` on `<html>` (done in `configureGlassWindow` on load)

### Apps

| App | Theme | Main entry |
|-----|-------|------------|
| Spaces | light | `desktop/spaces/src/main/windows.ts` |
| Planner | light | `planner/desktop/src/main/index.ts` |
| Media Monitoring | dark | `desktop/media-monitoring/electron/main/index.ts` |

## macOS IDE

Already uses `WorkspaceDesktopBackdrop` + `MainWindowChrome` (`WindowChromeConfigurator.swift`). See `mac/publshr/docs/APP_SHELL.md`.

## References

Arc Browser, Finder sidebar, Apple Music, Linear, Framer, Cursor desktop, macOS Sonoma glass materials.
