# Spaces (macOS IDE)

Enterprise operations hub inside Publshr — native SwiftUI, Supabase-backed, local SQLite cache.

## Setup

Apply the schema once per Supabase project:

```bash
# File: mac/publshr/supabase/migrations/001_spaces_schema.sql
```

## Architecture (ClickUp hierarchy)

```
Workspace → Space → (optional) Folder → List → Tasks
                              └─ Docs (space-level)
```

```
Activity bar → Spaces sidebar (spaces + folder/list/doc tree) → Breadcrumbs + Views bar → Board / List / Calendar / Overview → Inspector
```

| Layer | File |
|-------|------|
| UI | `Spaces/Views/*`, `SpacesClickUpDesign.swift` |
| Breadcrumbs / views | `SpacesBreadcrumbBar.swift`, `SpacesViewsBar.swift`, `SpacesHierarchyTreeView.swift` |
| State | `SpacesViewModel.swift`, `SpacesBreadcrumb.swift` |
| API + realtime | `SpacesService.swift` |
| Offline cache | `Spaces/Services/SpacesLocalStore.swift` (wired on load failure) |
| Layout tokens | `SpacesClickUpDesign.swift` — sidebar 272pt, inspector 340pt, board columns 280pt |

Apply enterprise schema: `supabase/migrations/20260522010000_spaces_clickup_enterprise.sql`

## Live features

- **Spaces** CRUD, pin, search; sidebar 272pt with pinned sections; inline + sheet create
- **Folders** create (auto-creates default List, ClickUp-style); expand/collapse tree; rename API
- **Lists** create in space or folder; filter tasks by list; “All tasks” view; rename API
- **Tasks** board (280pt columns), list, calendar, overview; drag status; inspector 340pt
- **Whiteboards** — infinite canvas per space (tldraw + Supabase); see `WHITEBOARD_SYSTEM.md`
- **Documents** create, sidebar + overview links, editor sheet (560×520)
- **Comments**, activity log, assignee, priority, due, tags, checklist
- Realtime: tasks, spaces
- Offline: SQLite cache for spaces/tasks when network fails
- Focus mode, back/forward navigation, menu commands (⌘⇧N space, ⌘⇧T task)
