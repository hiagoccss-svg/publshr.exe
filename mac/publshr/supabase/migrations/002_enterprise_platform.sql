-- Publshr enterprise platform (devices, subscriptions, calls, privacy audit)
-- Apply after chat + spaces migrations. Safe to re-run (IF NOT EXISTS).

-- Extend workspaces for billing + enterprise config
alter table if exists public.workspaces
  add column if not exists plan_id text not null default 'trial';
alter table if exists public.workspaces
  add column if not exists slug text;
alter table if exists public.workspaces
  add column if not exists owner_id uuid references auth.users(id);
alter table if exists public.workspaces
  add column if not exists settings jsonb not null default '{}'::jsonb;

-- Plan catalog (for subscription UI + feature gates)
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

insert into public.subscription_plans (id, name, seat_limit, includes_chat, includes_spaces, includes_calls, includes_files_gb, price_label)
values
  ('trial', 'Trial', 3, true, true, true, 5, 'Free trial'),
  ('team', 'Team', 25, true, true, true, 50, 'Per workspace / month'),
  ('enterprise', 'Enterprise', 500, true, true, true, 500, 'Custom')
on conflict (id) do nothing;

-- Registered Mac devices per user (privacy + security)
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

-- Privacy / compliance audit log
create table if not exists public.privacy_audit_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  workspace_id uuid references public.workspaces(id) on delete set null,
  event_type text not null,
  detail text not null default '',
  created_at timestamptz not null default now()
);

-- Voice / video call rooms (signaling; media via LiveKit URL in workspace settings)
create table if not exists public.call_rooms (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  channel_id uuid,
  space_id uuid,
  title text not null default 'Call',
  kind text not null default 'voice' check (kind in ('voice', 'video')),
  status text not null default 'active' check (status in ('active', 'ended')),
  created_by uuid not null references auth.users(id),
  livekit_room text,
  created_at timestamptz not null default now(),
  ended_at timestamptz
);

create table if not exists public.call_participants (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.call_rooms(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  left_at timestamptz,
  is_muted boolean not null default false,
  is_video_enabled boolean not null default false,
  unique (room_id, user_id)
);

alter publication supabase_realtime add table public.call_participants;
alter publication supabase_realtime add table public.call_rooms;

alter table public.device_registrations enable row level security;
alter table public.call_rooms enable row level security;
alter table public.call_participants enable row level security;
alter table public.privacy_audit_events enable row level security;
alter table public.subscription_plans enable row level security;

create policy "subscription_plans_read" on public.subscription_plans for select using (true);
create policy "devices_own" on public.device_registrations for all using (auth.uid() = user_id);
create policy "privacy_audit_insert" on public.privacy_audit_events for insert with check (auth.uid() = user_id);
create policy "privacy_audit_select" on public.privacy_audit_events for select using (
  auth.uid() = user_id
  or (
    workspace_id is not null
    and publshr_private.role_at_least(
      publshr_private.workspace_member_role(workspace_id, auth.uid()),
      'admin'::publshr_private.workspace_role
    )
  )
);
create policy "call_rooms_workspace_member" on public.call_rooms for all
  using (publshr_private.is_workspace_member(workspace_id, auth.uid()))
  with check (publshr_private.is_workspace_member(workspace_id, auth.uid()));
create policy "call_participants_workspace_member" on public.call_participants for all
  using (
    exists (
      select 1 from public.call_rooms r
      where r.id = room_id
        and publshr_private.is_workspace_member(r.workspace_id, auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.call_rooms r
      where r.id = room_id
        and publshr_private.is_workspace_member(r.workspace_id, auth.uid())
    )
  );
