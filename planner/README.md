# Planner — Communications Operating System

Desktop module for PR, media, editorial, and agency teams. Built with **Electron**, **React**, **TypeScript**, **Tailwind**, **Supabase**, and **SQLite** local cache.

## Quick start

```bash
cd planner/desktop
npm install
cp .env.example .env   # add Supabase URL + publishable key
npm run dev
```

## Architecture

| Layer | Path | Role |
|-------|------|------|
| Desktop shell | `desktop/electron/` | Windows, IPC, SQLite, notifications |
| UI | `desktop/src/` | React views, design system, stores |
| Cloud | `supabase/migrations/` | Postgres schema, RLS, Realtime |
| Sync | `desktop/src/lib/sync/` | Local-first write, background Supabase sync |

## MVP phases

1. **Phase 1** (current): Shell, auth, timeline, CRUD, SQLite cache
2. **Phase 2**: Calendar, board, context panel, search, filters
3. **Phase 3**: Editor in separate window, autosave, source panel
4. **Phase 4**: Approvals, notifications, realtime, permissions
5. **Phase 5**: Client view, AI assistant, publishing

## Supabase

Uses the same Publshr project (`lboesdtsrqfvosznjpdy`). Apply migrations:

```bash
cd planner/supabase
# With Supabase CLI linked to project:
supabase db push
```

Or run `migrations/20260521000000_planner_schema.sql` in the SQL editor.

## Build

```bash
cd planner/desktop
npm run build
npm run package   # platform installer
```
