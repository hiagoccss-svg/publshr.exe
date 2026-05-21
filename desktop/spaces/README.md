# Publshr Spaces

Enterprise operations and project management module for Publshr — a desktop-native operational hub (not a basic task board).

## Stack

- **Electron** — multi-window desktop shell
- **React + TypeScript** — UI
- **Tailwind CSS** — calm, premium design system
- **SQLite** (`better-sqlite3`) — local-first cache, search index, offline queue
- **Supabase** — realtime sync, auth, cloud storage (optional)

## Phase 1 (implemented)

- Full desktop shell: top bar, sidebar, workspace, context panel
- Spaces CRUD (empty states — no demo seed data)
- Task system with statuses, priorities, checklists
- **List** and **Board** views with drag-and-drop
- Space **Overview** dashboard
- Command palette (`⌘K` / `Ctrl+K`)
- Global search via local SQLite index
- Multi-window: main, per-Space, per-Document
- Offline-first writes with `sync_queue`
- Supabase migration + realtime subscription scaffold

## Phase 2–4 (planned)

See product spec: timeline, documents, comments, files, notifications, approvals, client mode, AI, automations.

## Development

```bash
cd desktop/spaces
npm install
cp .env.example .env   # optional Supabase
npm run dev
```

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
