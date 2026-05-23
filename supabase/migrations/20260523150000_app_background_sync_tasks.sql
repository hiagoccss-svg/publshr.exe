-- Per-device background sync state (GitHub live + Supabase pull), updated by the Mac app every ~30s.

create table if not exists public.app_background_sync_tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  device_key text not null,
  status text not null default 'idle'
    check (status in ('idle', 'running', 'completed', 'failed')),
  current_step text not null default '',
  client_build int not null default 0,
  client_version text not null default '',
  remote_live_version text,
  needs_app_update boolean not null default false,
  last_sync_started_at timestamptz,
  last_sync_completed_at timestamptz,
  last_log_excerpt text not null default '',
  last_error text,
  updated_at timestamptz not null default now(),
  unique (user_id, device_key)
);

create index if not exists app_background_sync_tasks_user_idx
  on public.app_background_sync_tasks(user_id);

alter table public.app_background_sync_tasks enable row level security;

create policy "app_background_sync_tasks_own"
  on public.app_background_sync_tasks
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
