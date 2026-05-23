# ClickUp Spaces parity map

Reference: [ClickUp — Intro to Spaces](https://help.clickup.com/hc/en-us/articles/6309466958103-Intro-to-Spaces), [Hierarchy](https://help.clickup.com/hc/en-us/articles/13856392825367-Intro-to-the-Hierarchy), [Views Bar](https://help.clickup.com/hc/en-us/articles/19063083658135-Intro-to-the-Views-Bar).

Publshr **Spaces** targets the same mental model: **Workspace → Space → (optional) Folder → List → Task**, with a **272px** sidebar, **340px** task inspector, and a **views bar** for each location.

## Where it runs

| Surface | Path |
|---------|------|
| Electron renderer (“web” UI) | `desktop/spaces/src/renderer/` — `npm run dev` |
| macOS IDE (native shell) | `mac/publshr/Sources/PublshrApp/Spaces/` |

Both surfaces share the same **views bar** contract: `shared/spaces/view-modes.ts` (see `shared/spaces/PARITY.md`).

## Parity matrix

| ClickUp capability | Publshr status |
|--------------------|----------------|
| Spaces Home (browse, search, filter, grid/list) | ✅ `SpacesEnterpriseHome` + macOS IDE |
| Unified “Spaces” naming (no top-level Project type) | ✅ Folders = project groups |
| Create / edit space | ✅ Modal + settings |
| Pin / favorites | ✅ Settings + sidebar sections |
| Space privacy / guest access | 🔶 Workspace roles only (no guest tier) |
| Folder → List tree | ✅ Expand/collapse, “All tasks” |
| New folder auto-creates list | ✅ |
| List / Board / Calendar views | ✅ |
| Overview (space dashboard) | ✅ |
| Timeline / Gantt | ✅ Electron + macOS IDE |
| Workload by assignee | ✅ Electron + macOS IDE |
| Priority matrix | ✅ Electron + macOS IDE |
| Whiteboard (tldraw canvas) | ✅ Electron renderer; macOS lists boards (canvas embed Phase 2) |
| Table view | ✅ List view (sortable table) |
| Task detail (status, priority, dates, assignee, tags, checklist, comments) | ✅ |
| Documents at space level | ✅ |
| Activity feed | ✅ |
| Default view per space | ✅ Desktop — local preference |
| Required views / view templates | 🔶 Roadmap |
| Custom statuses per folder/list | 🔶 Inherited workspace statuses |
| ClickApps (sprints, time tracking, etc.) | 🔶 Roadmap |
| Gantt dependencies | 🔶 Roadmap |
| Goals, Mind Maps | 🔶 Roadmap |
| 15+ views (Map, Activity, etc.) | Partial — core ops views first |

## Layout (ClickUp-aligned)

```
Activity / global nav  |  Spaces sidebar (272px)  |  Breadcrumb + Views bar  |  Main view  |  Inspector (340px)
```

## Run locally

```bash
cd desktop/spaces
npm install
cp .env.example .env   # optional Supabase
npm run dev
```

Use **Spaces Home** in the sidebar to see every space; open a space for the folder/list tree and views bar (Overview, List, Board, Calendar, Timeline, Workload, Priority).

## Supabase

Apply migrations listed in `mac/publshr/docs/ENTERPRISE_CHAT_SPACES.md` (including `20260522010000_spaces_clickup_enterprise.sql`).
