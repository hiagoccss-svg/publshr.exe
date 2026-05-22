# Whiteboards (ClickUp / Microsoft Whiteboard parity)

Enterprise infinite canvas inside **Spaces**, linked to the same workspace hierarchy as tasks and documents.

## ClickUp parity target

| Capability | ClickUp | Publshr phase |
|------------|---------|-----------------|
| Infinite canvas | Yes | **Phase 1** (tldraw) |
| Multiple boards per Space | Yes | **Phase 1** |
| Link board to Space / List | Yes | **Phase 1** (`space_id`, optional `list_id`) |
| Sticky notes, shapes, arrows | Yes | **Phase 1** (tldraw) |
| Embed / link tasks on canvas | Yes | **Phase 2** (`whiteboard_task_links`) |
| Realtime cursors | Yes | **Phase 2** (Supabase Realtime on `whiteboards`) |
| Planner project link | Partial | **Phase 2** (`planner_project_id`) |
| Templates | Yes | Phase 3 |
| Export PNG/PDF | Yes | Phase 3 |
| macOS IDE native canvas | N/A | **Phase 2** (WKWebView host or Swift canvas) |
| Chat link / share in channel | Yes | Phase 3 (`chat_message_links`) |

## Data model

```
Workspace → Space → Whiteboard(s)
                 ├─ optional list_id
                 ├─ optional planner_project_id
                 └─ snapshot (tldraw JSON)
```

Migration: `supabase/migrations/20260522140000_whiteboards_enterprise.sql`

## Clients

| Surface | Path | Status |
|---------|------|--------|
| Spaces Electron | `desktop/spaces/` — `WhiteboardView.tsx` | Phase 1 |
| macOS IDE Spaces | `mac/publshr/Sources/PublshrApp/Spaces/Views/SpacesWhiteboardView.swift` | Phase 1 tab + sync |
| Planner | Optional `planner_project_id` on board | Phase 2 |

## Snapshot format

Store [tldraw](https://tldraw.dev) `getSnapshot()` JSON in `whiteboards.snapshot`. Revisions append to `whiteboard_revisions` on debounced save (max 20 per board).

## Apply schema

```bash
# Supabase SQL editor or CLI
supabase db push
# File: supabase/migrations/20260522140000_whiteboards_enterprise.sql
```

## Run Spaces with whiteboard

```bash
cd desktop/spaces
npm install
npm run dev
```

Open a Space → **Whiteboard** tab → create board → draw; saves to Supabase when online.
