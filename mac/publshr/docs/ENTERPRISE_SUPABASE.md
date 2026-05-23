# Enterprise Supabase — full platform checklist

The native macOS app (`Publshr.app`) expects **one** Supabase project with the migrations under `supabase/migrations/` applied in order. Production project: `lboesdtsrqfvosznjpdy`.

## What must exist for enterprise to run

| Area | Tables / objects | Used by |
|------|------------------|---------|
| Auth + profile | `profiles`, trigger `handle_new_user` | Sign-in |
| Workspaces | `workspaces`, `workspace_members`, `workspace_invites` | IDE shell |
| Subscriptions | `subscription_plans`, `workspaces.plan_id` | Settings → Subscription, module gates |
| Devices | `device_registrations` | Onboarding, Settings → Devices |
| Privacy | `privacy_audit_events` | Onboarding, compliance |
| Background sync | `app_background_sync_tasks` | 30s GitHub + Supabase cycle |
| Chat | `chat_*` (channels, messages, presence, …) | Chat module |
| Spaces | `spaces`, `tasks`, `documents`, `whiteboards`, … | Spaces module |
| Media | `monitor_profiles`, `monitor_results`, `saved_coverage` | Media Monitoring |
| Calls | `call_rooms`, `call_participants` | Voice/video signaling |
| Planner | `projects`, `planner_items` | Planner sections |
| Storage | `workspace-files` bucket policies | Attachments |
| Server jobs | `dispatch_due_chat_scheduled_messages()` (+ pg_cron if enabled) | Scheduled chat |

## Apply migrations (new project)

From repo root with [Supabase CLI](https://supabase.com/docs/guides/cli) linked to your project:

```bash
supabase db push
```

Or apply each file under `supabase/migrations/` in filename order via the Supabase SQL editor.

**Final enterprise bundle (idempotent):** `20260523160000_enterprise_platform_complete.sql`

## Verify production / CI

```bash
cd mac/publshr
bash scripts/verify-all-connections.sh   # GitHub live + auth + chat/spaces + enterprise
```

Enterprise section checks REST access to `subscription_plans`, `device_registrations`, `app_background_sync_tasks`, privacy audit, calls, planner, etc.

**One-shot SQL health check** (SQL editor or `psql`):

```sql
select public.enterprise_platform_ready();
```

Returns `ready: true` when all required tables exist.

## Mac app ↔ Supabase (30s background sync)

Every 30 seconds the app:

1. Checks GitHub `live` (app binary update / install).
2. Pulls Chat, Spaces, Media, devices, subscriptions from Supabase.
3. Upserts `app_background_sync_tasks` for this Mac (`user_id` + `device_key`).

No manual “Sync” required when **Settings → Auto-check every 30 seconds** is on.

## Migration history (production)

As of `app_background_sync_tasks` + `enterprise_platform_complete`, production should list migrations through:

- `enterprise_hardening`
- `spaces_type_legacy_enum_to_text`
- `app_background_sync_tasks`
- `enterprise_platform_complete`

See Supabase Dashboard → Database → Migrations for the live list.
