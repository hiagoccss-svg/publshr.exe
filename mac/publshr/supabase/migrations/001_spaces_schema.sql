-- Publshr Spaces — enterprise operations schema (Phase 1+)

create type space_type as enum (
  'client', 'campaign', 'launch', 'editorial', 'department',
  'initiative', 'event', 'retainer', 'publication', 'operation', 'general'
);

create type space_status as enum ('active', 'planning', 'on_hold', 'completed', 'archived');

create type task_status as enum (
  'todo', 'in_progress', 'review', 'blocked', 'approved', 'completed', 'archived'
);

create type task_priority as enum ('none', 'low', 'normal', 'high', 'urgent');

create type approval_status as enum (
  'requested', 'in_review', 'changes_requested', 'approved', 'rejected'
);

create type space_member_role as enum (
  'owner', 'manager', 'editor', 'contributor', 'viewer', 'client'
);

create table if not exists spaces (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null,
  name text not null,
  description text not null default '',
  type space_type not null default 'general',
  status space_status not null default 'active',
  owner_id uuid not null,
  color text not null default '#3d5a80',
  is_pinned boolean not null default false,
  is_favourite boolean not null default false,
  is_archived boolean not null default false,
  client_mode boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists space_members (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references spaces(id) on delete cascade,
  user_id uuid not null,
  role space_member_role not null default 'contributor',
  unique (space_id, user_id)
);

create table if not exists tasks (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references spaces(id) on delete cascade,
  title text not null,
  description text not null default '',
  status task_status not null default 'todo',
  priority task_priority not null default 'normal',
  assignee_id uuid,
  start_date date,
  due_date date,
  tags text[] not null default '{}',
  parent_task_id uuid references tasks(id) on delete set null,
  checklist jsonb not null default '[]',
  sort_order double precision not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists task_dependencies (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references tasks(id) on delete cascade,
  depends_on_task_id uuid not null references tasks(id) on delete cascade,
  dep_type text not null default 'blocked_by',
  unique (task_id, depends_on_task_id)
);

create table if not exists documents (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references spaces(id) on delete cascade,
  title text not null,
  doc_type text not null default 'brief',
  content text not null default '',
  updated_at timestamptz not null default now()
);

create table if not exists approvals (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references spaces(id) on delete cascade,
  task_id uuid references tasks(id) on delete set null,
  document_id uuid references documents(id) on delete set null,
  status approval_status not null default 'requested',
  title text not null,
  updated_at timestamptz not null default now()
);

create table if not exists space_comments (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references spaces(id) on delete cascade,
  task_id uuid references tasks(id) on delete cascade,
  document_id uuid references documents(id) on delete cascade,
  user_id uuid not null,
  body text not null,
  created_at timestamptz not null default now()
);

create table if not exists space_files (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references spaces(id) on delete cascade,
  file_name text not null,
  file_url text not null,
  mime_type text not null default 'application/octet-stream',
  updated_at timestamptz not null default now()
);

create table if not exists space_activity (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references spaces(id) on delete cascade,
  user_id uuid not null,
  action text not null,
  entity_type text not null,
  entity_id uuid not null,
  created_at timestamptz not null default now()
);

-- Realtime
alter publication supabase_realtime add table tasks;
alter publication supabase_realtime add table spaces;
alter publication supabase_realtime add table space_activity;

-- RLS placeholders (configure per workspace in production)
alter table spaces enable row level security;
alter table tasks enable row level security;

create policy "spaces_workspace_members" on spaces
  for all using (true);

create policy "tasks_space_members" on tasks
  for all using (true);
