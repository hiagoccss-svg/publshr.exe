# Enterprise Chat & Spaces

Production setup for **Chat** and **Spaces** inside the macOS Publshr desktop app (`Publshr.app`), with optional standalone **Spaces** Electron app.

## Supabase (required for multi-user)

Apply migrations in order from `supabase/migrations/`:

1. `planner/supabase/migrations/20260521000000_planner_schema.sql` (if workspaces not present)
2. `20260522000000_enterprise_foundation.sql` — profiles, chat core, files, `search_workspace` RPC
3. `20260521180000_chat_presence_and_members.sql`
4. `20260521200000_chat_phases_2_4.sql`
5. `20260522010000_spaces_clickup_enterprise.sql` — Spaces, folders, lists, tasks, comments
6. `20260522130000_spaces_documents_and_realtime.sql` — `documents`, `space_activity`, realtime for Chat/Spaces
7. `seed_workspace_default_channels` (remote) — `#general` channel per new workspace

Create Storage bucket **`workspace-files`** with RLS for authenticated workspace members (chat uploads).

Enable **Realtime** on: `chat_messages`, `chat_channels`, `chat_presence`, `chat_reactions`, `tasks`, `spaces`, `space_comments`.

## Chat (mac IDE)

| Feature | Status |
|---------|--------|
| Channels, DMs, threads | ✅ |
| Realtime insert + **edit/delete sync** | ✅ |
| Reactions (insert + delete realtime) | ✅ |
| Typing indicators (IDE + pop-out) | ✅ |
| File upload (IDE + pop-out) | ✅ |
| Image inline preview | ✅ |
| @mention notifications | ✅ |
| Permissions → `workspaces.settings` | ✅ persisted |
| Global search (`search_workspace` RPC) | ✅ when migration applied |
| Voice STT / E2E / full audit | 🔶 roadmap |

## Spaces (mac IDE)

ClickUp-style hierarchy: **Space → Folder → List → Task**

| Feature | Status |
|---------|--------|
| Spaces CRUD, pin | ✅ |
| Folders & lists | ✅ |
| Board / list / overview / **calendar** | ✅ |
| Task detail (assignee, priority, due, tags, checklist, comments) | ✅ |
| Documents, activity | ✅ |
| Supabase realtime | ✅ |
| Time tracking, automations, custom fields | 🔶 roadmap |

## Standalone Spaces (Electron)

```bash
cd desktop/spaces
npm install
cp .env.example .env   # Supabase URL + anon key
npm run dev
npm run build
npm run dist           # packaged app in release/
```

Local SQLite remains source of truth; `SupabaseSyncService` pushes `sync_queue` when online.

## Deploy macOS app

Push to `main` → **Deliver macOS live app** publishes `Publshr-macos-aarch64.tar.gz`. Users install via `install-macos.sh`; Chat and Spaces ship inside `Publshr.app`.

## ClickUp parity (honest scope)

Full ClickUp includes Gantt, workload, goals, whiteboards, native mobile, hundreds of integrations, and enterprise compliance tooling. Publshr targets **operations teams** with:

- **Chat** — Slack-class messaging inside the IDE
- **Spaces** — client/campaign spaces, boards, lists, calendar, assignments

Remaining high-value gaps: subtasks UI, time tracking, custom fields, approval workflows UI, automations, and client portal mode.
