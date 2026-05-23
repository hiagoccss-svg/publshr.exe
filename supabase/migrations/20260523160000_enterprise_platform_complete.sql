-- Enterprise platform completeness (idempotent).
-- Ensures the native macOS app can run: Chat, Spaces, Media, devices, subscriptions,
-- privacy audit, calls, scheduled chat dispatch, and 30s background sync tasks.
-- Safe to re-run on production (lboesdtsrqfvosznjpdy).

-- ---------------------------------------------------------------------------
-- Background sync (30s GitHub + Supabase cycle from Mac app)
-- ---------------------------------------------------------------------------
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

drop policy if exists app_background_sync_tasks_own on public.app_background_sync_tasks;
create policy app_background_sync_tasks_own
  on public.app_background_sync_tasks
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Subscription catalog (Settings → Subscription, module gates)
-- ---------------------------------------------------------------------------
create table if not exists public.subscription_plans (
  id text primary key,
  name text not null,
  seat_limit int not null default 5,
  includes_chat boolean not null default true,
  includes_spaces boolean not null default true,
  includes_calls boolean not null default false,
  includes_files_gb int not null default 10,
  price_label text not null default 'Contact sales'
);

insert into public.subscription_plans (
  id, name, seat_limit, includes_chat, includes_spaces, includes_calls, includes_files_gb, price_label
) values
  ('trial', 'Trial', 3, true, true, true, 5, 'Free trial'),
  ('team', 'Team', 25, true, true, true, 50, 'Per workspace / month'),
  ('enterprise', 'Enterprise', 500, true, true, true, 500, 'Custom')
on conflict (id) do update set
  name = excluded.name,
  seat_limit = excluded.seat_limit,
  includes_chat = excluded.includes_chat,
  includes_spaces = excluded.includes_spaces,
  includes_calls = excluded.includes_calls,
  includes_files_gb = excluded.includes_files_gb,
  price_label = excluded.price_label;

alter table if exists public.workspaces
  add column if not exists plan_id text not null default 'trial';

alter table public.subscription_plans enable row level security;
drop policy if exists subscription_plans_read on public.subscription_plans;
create policy subscription_plans_read on public.subscription_plans
  for select to authenticated, anon
  using (true);

-- ---------------------------------------------------------------------------
-- Devices + privacy (onboarding, Settings)
-- ---------------------------------------------------------------------------
create table if not exists public.device_registrations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  workspace_id uuid references public.workspaces(id) on delete set null,
  device_key text not null,
  device_name text not null default '',
  platform text not null default 'macos',
  app_version text not null default '',
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (user_id, device_key)
);

create index if not exists device_registrations_user_idx on public.device_registrations(user_id);

alter table public.device_registrations enable row level security;
drop policy if exists devices_own on public.device_registrations;
create policy devices_own on public.device_registrations
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

alter table if exists public.privacy_audit_events enable row level security;
alter table if exists public.call_rooms enable row level security;
alter table if exists public.call_participants enable row level security;

-- ---------------------------------------------------------------------------
-- Health RPC: app + CI can verify enterprise schema in one call
-- ---------------------------------------------------------------------------
create or replace function public.enterprise_platform_ready()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'ready', (
      to_regclass('public.workspaces') is not null
      and to_regclass('public.subscription_plans') is not null
      and to_regclass('public.device_registrations') is not null
      and to_regclass('public.app_background_sync_tasks') is not null
      and to_regclass('public.chat_channels') is not null
      and to_regclass('public.spaces') is not null
      and to_regclass('public.monitor_profiles') is not null
    ),
    'tables', jsonb_build_object(
      'subscription_plans', to_regclass('public.subscription_plans') is not null,
      'device_registrations', to_regclass('public.device_registrations') is not null,
      'app_background_sync_tasks', to_regclass('public.app_background_sync_tasks') is not null,
      'privacy_audit_events', to_regclass('public.privacy_audit_events') is not null,
      'call_rooms', to_regclass('public.call_rooms') is not null,
      'chat_channels', to_regclass('public.chat_channels') is not null,
      'spaces', to_regclass('public.spaces') is not null,
      'monitor_profiles', to_regclass('public.monitor_profiles') is not null
    ),
    'subscription_plan_count', (select count(*)::int from public.subscription_plans),
    'checked_at', now()
  );
$$;

revoke all on function public.enterprise_platform_ready() from public;
grant execute on function public.enterprise_platform_ready() to authenticated, anon;
