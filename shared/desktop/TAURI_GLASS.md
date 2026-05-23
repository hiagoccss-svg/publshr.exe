# Tauri native glass window

Maps the Electron `glass-window.ts` behavior to Tauri 2 window configuration.

| OS | Effect | Notes |
|----|--------|-------|
| macOS | `TitleBarStyle::Overlay` + transparent background | Pair with `data-glass-theme` on `<html>` |
| Windows 11+ | `EffectsBuilder` Mica / Acrylic | WebView2 |
| Linux | Semi-opaque fallback | No Mica; use `.dt-chrome` CSS only |

Implement in each app's `src-tauri/src/window.rs` when enabling production glass. Spaces pilot uses a standard window until effects are toggled per QA.

CSS: `shared/design/desktop-transparency.css` (imported from renderer `index.css`).
