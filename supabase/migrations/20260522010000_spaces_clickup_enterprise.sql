-- Spaces enterprise schema (ClickUp-style hierarchy: Space → Folder → List → Task)
-- Safe to re-run (IF NOT EXISTS).

DO $$ BEGIN
  CREATE TYPE space_type AS ENUM (
    'client', 'campaign', 'launch', 'editorial', 'department',
    'initiative', 'event', 'retainer', 'publication', 'operation', 'general'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE space_status AS ENUM ('active', 'planning', 'on_hold', 'completed', 'archived');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE task_status AS ENUM (
    'todo', 'in_progress', 'review', 'blocked', 'approved', 'completed', 'archived'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE task_priority AS ENUM ('none', 'low', 'normal', 'high', 'urgent');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS public.spaces (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text NOT NULL DEFAULT '',
  type text NOT NULL DEFAULT 'general',
  status text NOT NULL DEFAULT 'active',
  owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  color text NOT NULL DEFAULT '#3d5a80',
  is_pinned boolean NOT NULL DEFAULT false,
  is_favourite boolean NOT NULL DEFAULT false,
  is_archived boolean NOT NULL DEFAULT false,
  client_mode boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.space_folders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id uuid NOT NULL REFERENCES public.spaces(id) ON DELETE CASCADE,
  name text NOT NULL,
  sort_order double precision NOT NULL DEFAULT 0,
  is_archived boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.space_lists (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id uuid NOT NULL REFERENCES public.spaces(id) ON DELETE CASCADE,
  folder_id uuid REFERENCES public.space_folders(id) ON DELETE SET NULL,
  name text NOT NULL,
  sort_order double precision NOT NULL DEFAULT 0,
  is_archived boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.space_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id uuid NOT NULL REFERENCES public.spaces(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'contributor',
  UNIQUE (space_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id uuid NOT NULL REFERENCES public.spaces(id) ON DELETE CASCADE,
  list_id uuid REFERENCES public.space_lists(id) ON DELETE SET NULL,
  title text NOT NULL,
  description text NOT NULL DEFAULT '',
  status text NOT NULL DEFAULT 'todo',
  priority text NOT NULL DEFAULT 'normal',
  assignee_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  start_date date,
  due_date date,
  tags text[] NOT NULL DEFAULT '{}',
  parent_task_id uuid REFERENCES public.tasks(id) ON DELETE SET NULL,
  checklist jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order double precision NOT NULL DEFAULT 0,
  time_spent_minutes int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.space_comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id uuid NOT NULL REFERENCES public.spaces(id) ON DELETE CASCADE,
  task_id uuid REFERENCES public.tasks(id) ON DELETE CASCADE,
  document_id uuid,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  body text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id uuid NOT NULL REFERENCES public.spaces(id) ON DELETE CASCADE,
  title text NOT NULL,
  doc_type text NOT NULL DEFAULT 'brief',
  content text NOT NULL DEFAULT '',
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.space_activity (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id uuid NOT NULL REFERENCES public.spaces(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action text NOT NULL,
  entity_type text NOT NULL,
  entity_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.space_files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id uuid NOT NULL REFERENCES public.spaces(id) ON DELETE CASCADE,
  file_name text NOT NULL,
  file_url text NOT NULL,
  mime_type text NOT NULL DEFAULT 'application/octet-stream',
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS tasks_space_list_idx ON public.tasks (space_id, list_id, sort_order);
CREATE INDEX IF NOT EXISTS space_lists_folder_idx ON public.space_lists (space_id, folder_id);

-- RLS: workspace members only
ALTER TABLE public.spaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.space_folders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.space_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.space_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.space_activity ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS spaces_workspace_members ON public.spaces;
CREATE POLICY spaces_workspace_members ON public.spaces
  FOR ALL USING (public.is_workspace_member(workspace_id));

DROP POLICY IF EXISTS space_folders_access ON public.space_folders;
CREATE POLICY space_folders_access ON public.space_folders
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.spaces s
      WHERE s.id = space_folders.space_id AND public.is_workspace_member(s.workspace_id)
    )
  );

DROP POLICY IF EXISTS space_lists_access ON public.space_lists;
CREATE POLICY space_lists_access ON public.space_lists
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.spaces s
      WHERE s.id = space_lists.space_id AND public.is_workspace_member(s.workspace_id)
    )
  );

DROP POLICY IF EXISTS tasks_space_members ON public.tasks;
CREATE POLICY tasks_space_members ON public.tasks
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.spaces s
      WHERE s.id = tasks.space_id AND public.is_workspace_member(s.workspace_id)
    )
  );

DROP POLICY IF EXISTS space_comments_access ON public.space_comments;
CREATE POLICY space_comments_access ON public.space_comments
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.spaces s
      WHERE s.id = space_comments.space_id AND public.is_workspace_member(s.workspace_id)
    )
  );

DROP POLICY IF EXISTS documents_access ON public.documents;
CREATE POLICY documents_access ON public.documents
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.spaces s
      WHERE s.id = documents.space_id AND public.is_workspace_member(s.workspace_id)
    )
  );

DROP POLICY IF EXISTS space_activity_access ON public.space_activity;
CREATE POLICY space_activity_access ON public.space_activity
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.spaces s
      WHERE s.id = space_activity.space_id AND public.is_workspace_member(s.workspace_id)
    )
  );

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.tasks;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.spaces;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.space_comments;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
