# Spaces: desktop renderer and native IDE parity

Publshr has **no separate browser web app** in this repo. “Web” means the **Electron renderer** (Chromium + React in `desktop/spaces`). “Desktop” in product terms is either:

| Surface | Path | Role |
|---------|------|------|
| **Web UI (canonical for Spaces UX)** | `desktop/spaces/src/renderer/` | Full views bar, Spaces Home, settings, tldraw whiteboard |
| **Native IDE** | `mac/publshr/Sources/PublshrApp/Spaces/` | Same views bar order and labels inside `Publshr.app` |

## Contract

1. **Views bar** — eight tabs in this order (see `shared/spaces/view-modes.ts`):
   Overview → List → Board → Whiteboard → Calendar → Timeline → Workload → Priority
2. **Hierarchy** — Workspace → Space → Folder → List → Task (folders hold project work; no top-level Project type — see `hierarchy.ts`)
3. **Spaces Home** — search, type filter, archived toggle, grid/list (`spaces-home.ts`, `SpacesEnterpriseHome.tsx`, `SpacesHomeView.swift`)
4. **Chrome** — 272px sidebar, 340px task inspector (`SpacesClickUpDesign` / Tailwind tokens)
5. **Supabase** — same tables and migrations under `supabase/migrations/`

When adding a view or renaming a tab, update **both**:

- `shared/spaces/view-modes.ts`
- `mac/publshr/Sources/PublshrApp/Spaces/SpacesViewModes.swift`
- `desktop/spaces/src/renderer/components/layout/WorkspaceArea.tsx` (import `SPACES_VIEW_TABS`)

## Whiteboard canvas

The **tldraw canvas** runs in the Electron renderer only until macOS embeds the same bundle (WKWebView host, Phase 2). The IDE shows the same board list and metadata; canvas editing uses the shared Supabase snapshot API.

## Run both surfaces

```bash
cd desktop/spaces && npm run dev
open /Applications/Publshr.app   # Spaces module in IDE
```
