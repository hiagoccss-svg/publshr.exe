# Spaces enterprise (ClickUp Spaces Home)

Publshr uses **Spaces** only at the top level. There is no separate “Projects” module inside Spaces — **folders** inside a Space play the same role as ClickUp project folders.

## Hierarchy

```
Workspace → Space → Folder → List → Task
```

| ClickUp | Publshr |
|---------|---------|
| Space (department / team) | **Space** |
| Folder (project group) | **Folder** |
| List (sprint / phase) | **List** |
| Task | **Task** |

Legacy space rows with `type = project` are normalized to **initiative** in the UI.

## Shared contract

| File | Role |
|------|------|
| `shared/spaces/hierarchy.ts` | Labels, space types, folder copy |
| `shared/spaces/spaces-home.ts` | Search, filter, pinned/favorites grouping |
| `shared/spaces/view-modes.ts` | Views bar tabs |

## Surfaces

| Surface | Spaces Home |
|---------|-------------|
| `desktop/spaces` renderer | `SpacesEnterpriseHome.tsx` |
| macOS IDE | `SpacesHomeView.swift` + `SpacesHomeLogic.swift` |
| Enterprise Tauri shell | Reuses `desktop/spaces` via `@spaces` alias |

## ClickUp parity (Spaces Home)

- Browse all spaces in the workspace
- Search by name, description, type
- Filter by space type
- Show / hide archived
- Pinned and favorites sections
- Grid and list layout
- Create space + open settings

Reference: [ClickUp — Intro to Spaces](https://help.clickup.com/hc/en-us/articles/6309466958103-Intro-to-Spaces)
