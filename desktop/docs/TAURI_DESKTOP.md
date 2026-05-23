# Tauri-first desktop architecture

Publshr desktop modules (Spaces, Media Monitoring, Planner) use **Tauri 2** as the native shell. **Do not add new Electron surfaces** unless a capability is blocked on Tauri and documented below.

## Why Tauri (not Electron)

| Concern | Tauri | Electron |
|--------|-------|----------|
| Runtime | OS webview (WKWebView / WebView2) | Bundled Chromium |
| Backend | Rust | Node main process |
| RAM / disk | Smaller installers, lower idle memory | Heavier baseline |
| Enterprise fit | Native signing, updater, ACL capabilities | Mature but Chromium tax |

The **UI stack stays the same**: React, TypeScript, Tailwind, shadcn/ui, Framer Motion. Only the **native shell and IPC** change.

## Stack

```
┌─────────────────────────────────────────┐
│  React renderer (Vite + HMR)          │
│  Tailwind · shadcn · Framer Motion      │
└─────────────────┬───────────────────────┘
                  │ invoke / events
┌─────────────────▼───────────────────────┐
│  Rust (Tauri commands, SQLite, sync)    │
│  macOS WKWebView · Windows WebView2     │
└─────────────────────────────────────────┘
```

## Repository layout

| Path | Role |
|------|------|
| `desktop/spaces/src/renderer/` | Spaces UI (shared with legacy Electron renderer) |
| `desktop/spaces/src-tauri/` | Spaces Tauri shell + Rust DB |
| `desktop/spaces/vite.config.ts` | Vite build for Tauri (`dev:web` / `build:web`) |
| `shared/desktop/` | Platform detection, API bridge, glass notes |
| `shared/electron/` | **Legacy** — frozen except critical fixes |
| `desktop/docs/DESKTOP_WORKFLOW.md` | Dev + update workflow (Tauri-first) |

## Development

**Preferred (Tauri):**

```bash
cd desktop/spaces
npm install
npm run tauri:dev    # Vite HMR + native window
```

**Legacy (Electron — maintenance only):**

```bash
npm run dev:electron
```

Root Makefile:

```bash
make spaces-tauri-dev   # Tauri Spaces
make spaces-dev         # alias → spaces-tauri-dev
```

## Migration status

| App | Tauri | Electron |
|-----|-------|----------|
| Spaces | **Active** (`src-tauri`, Rust SQLite) | Legacy `dev:electron` |
| Media Monitoring | Planned | Current |
| Planner | Planned | Current |

Phases:

1. **Spaces pilot** — Tauri shell, Rust `spaces::*` commands, React bridge (`shared/desktop/spaces-api.ts`).
2. **Updater** — `tauri-plugin-updater` + existing GitHub release channels (`spaces-staging`, etc.).
3. **Glass / transparency** — `shared/design/desktop-transparency.css` + Tauri window effects (vibrancy / Mica) in Rust.
4. **Media Monitoring + Planner** — new `src-tauri` per app; retire Electron CI jobs when parity is verified.

## When Electron is still allowed

- Fixing a production regression on the **installed Electron** channel while Tauri staging catches up.
- A dependency has no WebView-safe path (must be documented in this file with an issue link).

New features ship on **Tauri only**.

## Transparency

CSS layer model is unchanged: `shared/design/desktop-transparency.css`.  
Electron used `shared/electron/glass-window.ts`. Tauri applies native vibrancy/Mica in `src-tauri` window builder (see `shared/desktop/TAURI_GLASS.md`).

## CI / releases

- New workflow target: `deliver-desktop-tauri.yml` (to replace `deliver-desktop.yml` per product).
- Artifacts: `.dmg` / `.msi` / `.AppImage` from `tauri build`, not `electron-builder`.
- Channel tags unchanged: `{product}-staging`, `{product}-production`.

## macOS IDE

The Swift **Publshr** IDE (`mac/publshr`) is separate from Tauri desktop apps. Spaces **parity** with the IDE module remains via `shared/spaces/PARITY.md`.
