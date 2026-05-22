# Publshr Spaces

Enterprise operations and project management module for Publshr — a desktop-native operational hub (not a basic task board).

## Stack

- **Electron** — multi-window desktop shell
- **React + TypeScript** — UI
- **Tailwind CSS** — calm, premium design system
- **SQLite** (`better-sqlite3`) — local-first cache, search index, offline queue
- **Supabase** — realtime sync, auth, cloud storage (optional)

## Phase 1 (implemented)

- Full desktop shell: top bar, **272px** Spaces sidebar, workspace, **340px** context panel
- **ClickUp hierarchy**: Space → Folder → List → Tasks (`space_folders`, `space_lists`, `list_id`)
- Spaces create modal; folder/list tree; breadcrumbs; quick-add task
- Task inspector: status, priority, assignee, due date, tags, checklist, comments
- **Overview**, **List**, **Board**, **Calendar** views; board drag-and-drop status
- Command palette (`⌘K` / `Ctrl+K`); global search via SQLite index
- Multi-window scaffold; offline `sync_queue`; optional Supabase sync

## Phase 2–4 (planned)

See product spec: timeline, documents, comments, files, notifications, approvals, client mode, AI, automations.

## Development

Native **desktop window** with hot reload (no reinstall). See [Desktop workflow](../docs/DESKTOP_WORKFLOW.md).

```bash
cd desktop/spaces
npm install
cp .env.example .env   # optional Supabase
npm run dev
```

Installed testing uses GitHub channel `spaces-staging` (app bundle updates without a new installer).

## Build

```bash
npm run build
npm run typecheck
```

## Database

- Local: `~/Library/Application Support/@publshr/spaces/spaces-cache/spaces.db` (macOS) or equivalent per OS under Electron `userData`.
- Remote: apply `supabase/migrations/001_spaces_schema.sql` to your Supabase project.

## Design principles

- Calm `surface` palette, minimal chrome, operational density without clutter
- No fake demo data on first run
- Local-first: instant UI, background sync when online
