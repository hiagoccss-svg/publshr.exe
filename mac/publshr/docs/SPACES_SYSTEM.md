# Spaces (macOS IDE)

Enterprise operations hub inside Publshr — native SwiftUI, Supabase-backed, local SQLite cache.

## Setup

Apply the schema once per Supabase project:

```bash
# File: mac/publshr/supabase/migrations/001_spaces_schema.sql
```

## Architecture

```
Activity bar → Spaces sidebar (List, native) → Toolbar → Workspace (Board / List / Overview) → Inspector
```

| Layer | File |
|-------|------|
| UI | `Spaces/Views/*` |
| State | `SpacesViewModel.swift` |
| API + realtime | `SpacesService.swift` |
| Offline cache | `Spaces/Services/SpacesLocalStore.swift` |
| Native chrome | `SpacesNativeDesign.swift` |

## Live features

- Spaces CRUD, pin, search
- Tasks: full edit, drag-and-drop board, archive
- Comments, activity log, documents (editor sheet), approvals list, files list
- Realtime: tasks, spaces, comments
- Offline: cached spaces/tasks when network fails
- Focus mode, back/forward navigation, menu commands (⌘⇧N space, ⌘⇧T task)
