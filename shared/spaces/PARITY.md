# Spaces: desktop renderer and native IDE parity

**Product rule:** Enterprise modules ship **inside `Publshr.app` first** (native SwiftUI + embedded `WebBundles` where needed). Electron apps under `desktop/` remain for cross-platform dev/CI; they are not required for macOS users.

Publshr has **no separate browser web app** in this repo. “Web” means the **Electron renderer** (Chromium + React in `desktop/spaces`). The native IDE and renderer must stay identical on views bar, hierarchy, and Supabase schema.

| Module | In `Publshr.app` | Parity surface |
|--------|------------------|----------------|
| Chat | Yes | `mac/publshr/.../Chat/` |
| Spaces | Yes | `mac/publshr/.../Spaces/` + `desktop/spaces/src/renderer/` |
| Whiteboard canvas | Yes (WKWebView + `WebBundles/whiteboard`) | Spaces → Whiteboard tab |
| Media Monitoring | Yes (native) | `mac/publshr/.../MediaMonitoring/` |
| Planner | Yes (native) | `mac/publshr/.../Planner/` |
| Electron parity builds | Optional | `desktop/spaces`, `desktop/media-monitoring` |

## Contract

1. **Views bar** — eight tabs in this order (see `shared/spaces/view-modes.ts`):
   Overview → List → Board → Whiteboard → Calendar → Timeline → Workload → Priority
2. **Hierarchy** — Workspace → Space → Folder → List → Task
3. **Chrome** — 272px sidebar, 340px task inspector (`SpacesClickUpDesign` / Tailwind tokens)
4. **Supabase** — same tables and migrations under `supabase/migrations/`

When adding a view or renaming a tab, update **both**:

- `shared/spaces/view-modes.ts`
- `mac/publshr/Sources/PublshrApp/Spaces/SpacesViewModes.swift`
- `desktop/spaces/src/renderer/components/layout/WorkspaceArea.tsx` (import `SPACES_VIEW_TABS`)

## Whiteboard canvas

The **tldraw canvas** runs inside **`Publshr.app`** via `MacWebModuleHost` and `app/WebBundles/whiteboard/index.html` (Supabase snapshot API). The Electron Spaces renderer uses the same tables and bundle contract for parity testing.

## Run both surfaces

```bash
cd desktop/spaces && npm run dev
open /Applications/Publshr.app   # Spaces module in IDE
```
