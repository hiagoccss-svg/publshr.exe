-- Enterprise foundation: profiles, chat core, files, workspace helpers, search RPC
-- Apply before chat presence / phases migrations (they ALTER chat_channels).

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Profiles (extends auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL DEFAULT '',
  display_name text,
  avatar_url text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, display_name)
  VALUES (NEW.id, COALESCE(NEW.email, ''), COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)))
  ON CONFLICT (id) DO UPDATE SET email = EXCLUDED.email;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Workspaces (extend planner base)
ALTER TABLE public.workspaces
  ADD COLUMN IF NOT EXISTS slug text,
  ADD COLUMN IF NOT EXISTS owner_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS plan_id text NOT NULL DEFAULT 'free',
  ADD COLUMN IF NOT EXISTS settings jsonb NOT NULL DEFAULT '{}'::jsonb;

UPDATE public.workspaces SET slug = lower(regexp_replace(name, '[^a-zA-Z0-9]+', '-', 'g'))
  WHERE slug IS NULL OR slug = '';

-- Private helpers for chat RLS (used by existing chat migrations)
CREATE SCHEMA IF NOT EXISTS publshr_private;

DO $$ BEGIN
  CREATE TYPE publshr_private.workspace_role AS ENUM (
    'owner', 'admin', 'manager', 'editor', 'viewer', 'client'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE OR REPLACE FUNCTION publshr_private.workspace_member_role(ws_id uuid, uid uuid)
RETURNS publshr_private.workspace_role AS $$
  SELECT CASE lower(wm.role)
    WHEN 'owner' THEN 'owner'::publshr_private.workspace_role
    WHEN 'admin' THEN 'admin'::publshr_private.workspace_role
    WHEN 'manager' THEN 'manager'::publshr_private.workspace_role
    WHEN 'editor' THEN 'editor'::publshr_private.workspace_role
    WHEN 'viewer' THEN 'viewer'::publshr_private.workspace_role
    WHEN 'client' THEN 'client'::publshr_private.workspace_role
    ELSE 'viewer'::publshr_private.workspace_role
  END
  FROM public.workspace_members wm
  WHERE wm.workspace_id = ws_id AND wm.user_id = uid AND wm.status = 'active'
  LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, publshr_private;

CREATE OR REPLACE FUNCTION publshr_private.is_workspace_member(ws_id uuid, uid uuid)
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.workspace_members
    WHERE workspace_id = ws_id AND user_id = uid AND status = 'active'
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION publshr_private.role_at_least(
  actual publshr_private.workspace_role,
  minimum publshr_private.workspace_role
)
RETURNS boolean AS $$
  SELECT CASE actual
    WHEN 'owner' THEN true
    WHEN 'admin' THEN minimum IN ('admin', 'manager', 'editor', 'viewer', 'client')
    WHEN 'manager' THEN minimum IN ('manager', 'editor', 'viewer', 'client')
    WHEN 'editor' THEN minimum IN ('editor', 'viewer', 'client')
    WHEN 'viewer' THEN minimum IN ('viewer', 'client')
    WHEN 'client' THEN minimum = 'client'
    ELSE false
  END;
$$ LANGUAGE sql IMMUTABLE;

-- Chat channels & messages
CREATE TABLE IF NOT EXISTS public.chat_channels (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  kind text NOT NULL DEFAULT 'channel'
    CHECK (kind IN ('channel', 'dm', 'group', 'thread')),
  visibility text NOT NULL DEFAULT 'public'
    CHECK (visibility IN (
      'public', 'private', 'internal', 'client_safe', 'announcement',
      'read_only', 'hidden', 'invite_only'
    )),
  is_archived boolean NOT NULL DEFAULT false,
  last_message_at timestamptz,
  message_count int NOT NULL DEFAULT 0,
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS chat_channels_workspace_idx ON public.chat_channels (workspace_id, is_archived);

CREATE TABLE IF NOT EXISTS public.chat_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  channel_id uuid NOT NULL REFERENCES public.chat_channels(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  body text,
  thread_parent_id uuid REFERENCES public.chat_messages(id) ON DELETE SET NULL,
  attachments jsonb NOT NULL DEFAULT '[]'::jsonb,
  is_edited boolean NOT NULL DEFAULT false,
  is_deleted boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS chat_messages_channel_idx ON public.chat_messages (channel_id, created_at DESC);
CREATE INDEX IF NOT EXISTS chat_messages_workspace_idx ON public.chat_messages (workspace_id);

ALTER TABLE public.chat_channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY chat_channels_select ON public.chat_channels
  FOR SELECT USING (publshr_private.is_workspace_member(workspace_id, auth.uid()));

CREATE POLICY chat_channels_insert ON public.chat_channels
  FOR INSERT WITH CHECK (publshr_private.is_workspace_member(workspace_id, auth.uid()));

CREATE POLICY chat_channels_update ON public.chat_channels
  FOR UPDATE USING (publshr_private.is_workspace_member(workspace_id, auth.uid()));

CREATE POLICY chat_messages_select ON public.chat_messages
  FOR SELECT USING (publshr_private.is_workspace_member(workspace_id, auth.uid()));

CREATE POLICY chat_messages_insert ON public.chat_messages
  FOR INSERT WITH CHECK (
    user_id = auth.uid()
    AND publshr_private.is_workspace_member(workspace_id, auth.uid())
  );

CREATE POLICY chat_messages_update ON public.chat_messages
  FOR UPDATE USING (
    user_id = auth.uid()
    OR publshr_private.role_at_least(
      publshr_private.workspace_member_role(workspace_id, auth.uid()),
      'admin'::publshr_private.workspace_role
    )
  );

-- Files (chat uploads + attachments)
CREATE TABLE IF NOT EXISTS public.files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  uploaded_by uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  bucket text NOT NULL DEFAULT 'workspace-files',
  storage_path text NOT NULL,
  file_name text NOT NULL,
  mime_type text NOT NULL DEFAULT 'application/octet-stream',
  size_bytes int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.files ENABLE ROW LEVEL SECURITY;

CREATE POLICY files_select ON public.files
  FOR SELECT USING (publshr_private.is_workspace_member(workspace_id, auth.uid()));

CREATE POLICY files_insert ON public.files
  FOR INSERT WITH CHECK (
    uploaded_by = auth.uid()
    AND publshr_private.is_workspace_member(workspace_id, auth.uid())
  );

-- Workspace creation RPC
CREATE OR REPLACE FUNCTION public.create_workspace(p_name text)
RETURNS public.workspaces AS $$
DECLARE
  ws public.workspaces;
  uid uuid := auth.uid();
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;
  INSERT INTO public.workspaces (name, slug, owner_id)
  VALUES (
    p_name,
    lower(regexp_replace(p_name, '[^a-zA-Z0-9]+', '-', 'g')) || '-' || substr(gen_random_uuid()::text, 1, 8),
    uid
  )
  RETURNING * INTO ws;
  INSERT INTO public.workspace_members (workspace_id, user_id, role, status)
  VALUES (ws.id, uid, 'owner', 'active')
  ON CONFLICT DO NOTHING;
  RETURN ws;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Global search (chat messages + planner items)
CREATE OR REPLACE FUNCTION public.search_workspace(
  p_workspace_id uuid,
  p_query text,
  p_limit int DEFAULT 25
)
RETURNS jsonb AS $$
DECLARE
  q text := trim(lower(p_query));
  msg_rows jsonb;
  task_rows jsonb;
BEGIN
  IF NOT publshr_private.is_workspace_member(p_workspace_id, auth.uid()) THEN
    RETURN jsonb_build_object('messages', '[]'::jsonb, 'tasks', '[]'::jsonb);
  END IF;

  SELECT coalesce(jsonb_agg(row_to_json(m)), '[]'::jsonb) INTO msg_rows
  FROM (
    SELECT cm.id, cm.channel_id, cm.body, cm.created_at, cc.name AS channel_name
    FROM public.chat_messages cm
    JOIN public.chat_channels cc ON cc.id = cm.channel_id
    WHERE cm.workspace_id = p_workspace_id
      AND cm.is_deleted = false
      AND cm.body IS NOT NULL
      AND (q = '' OR lower(cm.body) LIKE '%' || q || '%')
    ORDER BY cm.created_at DESC
    LIMIT p_limit
  ) m;

  SELECT coalesce(jsonb_agg(row_to_json(t)), '[]'::jsonb) INTO task_rows
  FROM (
    SELECT pi.id, pi.title, pi.status, pi.due_date
    FROM public.planner_items pi
    WHERE pi.workspace_id = p_workspace_id
      AND (q = '' OR lower(pi.title) LIKE '%' || q || '%')
    ORDER BY pi.updated_at DESC
    LIMIT p_limit
  ) t;

  RETURN jsonb_build_object('messages', msg_rows, 'tasks', task_rows, 'query', p_query);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, publshr_private;

GRANT EXECUTE ON FUNCTION public.search_workspace(uuid, text, int) TO authenticated;

-- Profiles RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY profiles_select ON public.profiles
  FOR SELECT USING (true);

CREATE POLICY profiles_update ON public.profiles
  FOR UPDATE USING (id = auth.uid());

-- Realtime (idempotent)
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_channels;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
