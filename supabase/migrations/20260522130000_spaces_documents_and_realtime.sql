-- Production completion: Spaces documents/comments/activity + realtime for Chat & Spaces.
-- Uses publshr_private.is_workspace_member (production schema).

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

ALTER TABLE public.space_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.space_activity ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.space_files ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS space_comments_access ON public.space_comments;
CREATE POLICY space_comments_access ON public.space_comments
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.spaces s
      WHERE s.id = space_comments.space_id
        AND publshr_private.is_workspace_member(s.workspace_id, auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.spaces s
      WHERE s.id = space_comments.space_id
        AND publshr_private.is_workspace_member(s.workspace_id, auth.uid())
    )
  );

DROP POLICY IF EXISTS documents_access ON public.documents;
CREATE POLICY documents_access ON public.documents
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.spaces s
      WHERE s.id = documents.space_id
        AND publshr_private.is_workspace_member(s.workspace_id, auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.spaces s
      WHERE s.id = documents.space_id
        AND publshr_private.is_workspace_member(s.workspace_id, auth.uid())
    )
  );

DROP POLICY IF EXISTS space_activity_access ON public.space_activity;
CREATE POLICY space_activity_access ON public.space_activity
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.spaces s
      WHERE s.id = space_activity.space_id
        AND publshr_private.is_workspace_member(s.workspace_id, auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.spaces s
      WHERE s.id = space_activity.space_id
        AND publshr_private.is_workspace_member(s.workspace_id, auth.uid())
    )
  );

DROP POLICY IF EXISTS space_files_access ON public.space_files;
CREATE POLICY space_files_access ON public.space_files
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.spaces s
      WHERE s.id = space_files.space_id
        AND publshr_private.is_workspace_member(s.workspace_id, auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.spaces s
      WHERE s.id = space_files.space_id
        AND publshr_private.is_workspace_member(s.workspace_id, auth.uid())
    )
  );

-- Backfill owners missing from workspace_members (blocks Chat/Spaces RLS for real users).
INSERT INTO public.workspace_members (workspace_id, user_id, role, joined_at)
SELECT w.id, w.owner_id, 'owner', COALESCE(w.created_at, now())
FROM public.workspaces w
WHERE w.owner_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM public.workspace_members wm
    WHERE wm.workspace_id = w.id AND wm.user_id = w.owner_id
  )
ON CONFLICT DO NOTHING;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_channels;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.spaces;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.tasks;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.space_comments;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
