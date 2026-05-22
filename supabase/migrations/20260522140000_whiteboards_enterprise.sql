-- Enterprise whiteboards (ClickUp-style): infinite canvas linked to Spaces / optional Planner project.
-- Snapshot format: tldraw document JSON (see mac/publshr/docs/WHITEBOARD_SYSTEM.md).

CREATE TABLE IF NOT EXISTS public.whiteboards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  space_id uuid NOT NULL REFERENCES public.spaces(id) ON DELETE CASCADE,
  list_id uuid REFERENCES public.space_lists(id) ON DELETE SET NULL,
  planner_project_id uuid,
  name text NOT NULL DEFAULT 'Whiteboard',
  description text NOT NULL DEFAULT '',
  snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
  thumbnail_path text,
  is_archived boolean NOT NULL DEFAULT false,
  is_pinned boolean NOT NULL DEFAULT false,
  created_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS whiteboards_space_idx ON public.whiteboards (space_id, updated_at DESC);
CREATE INDEX IF NOT EXISTS whiteboards_workspace_idx ON public.whiteboards (workspace_id);

-- Pins on canvas linking to Spaces tasks (ClickUp: cards on board).
CREATE TABLE IF NOT EXISTS public.whiteboard_task_links (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  whiteboard_id uuid NOT NULL REFERENCES public.whiteboards(id) ON DELETE CASCADE,
  task_id uuid NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  shape_id text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (whiteboard_id, shape_id),
  UNIQUE (whiteboard_id, task_id)
);

CREATE INDEX IF NOT EXISTS whiteboard_task_links_task_idx ON public.whiteboard_task_links (task_id);

-- Version history (optional restore; last 20 per board).
CREATE TABLE IF NOT EXISTS public.whiteboard_revisions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  whiteboard_id uuid NOT NULL REFERENCES public.whiteboards(id) ON DELETE CASCADE,
  snapshot jsonb NOT NULL,
  saved_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS whiteboard_revisions_board_idx
  ON public.whiteboard_revisions (whiteboard_id, created_at DESC);

ALTER TABLE public.whiteboards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.whiteboard_task_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.whiteboard_revisions ENABLE ROW LEVEL SECURITY;

-- Workspace members with active space access can read/write whiteboards in that space.
CREATE POLICY "whiteboards_space_member_select"
ON public.whiteboards FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.space_members sm
    WHERE sm.space_id = whiteboards.space_id
      AND sm.user_id = auth.uid()
  )
);

CREATE POLICY "whiteboards_space_member_insert"
ON public.whiteboards FOR INSERT TO authenticated
WITH CHECK (
  created_by = auth.uid()
  AND EXISTS (
    SELECT 1 FROM public.space_members sm
    WHERE sm.space_id = whiteboards.space_id
      AND sm.user_id = auth.uid()
      AND sm.role IN ('owner', 'manager', 'editor', 'contributor')
  )
);

CREATE POLICY "whiteboards_space_member_update"
ON public.whiteboards FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.space_members sm
    WHERE sm.space_id = whiteboards.space_id
      AND sm.user_id = auth.uid()
      AND sm.role IN ('owner', 'manager', 'editor', 'contributor')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.space_members sm
    WHERE sm.space_id = whiteboards.space_id
      AND sm.user_id = auth.uid()
      AND sm.role IN ('owner', 'manager', 'editor', 'contributor')
  )
);

CREATE POLICY "whiteboards_space_member_delete"
ON public.whiteboards FOR DELETE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.space_members sm
    WHERE sm.space_id = whiteboards.space_id
      AND sm.user_id = auth.uid()
      AND sm.role IN ('owner', 'manager')
  )
);

CREATE POLICY "whiteboard_links_member_all"
ON public.whiteboard_task_links FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.whiteboards wb
    JOIN public.space_members sm ON sm.space_id = wb.space_id AND sm.user_id = auth.uid()
    WHERE wb.id = whiteboard_task_links.whiteboard_id
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.whiteboards wb
    JOIN public.space_members sm ON sm.space_id = wb.space_id AND sm.user_id = auth.uid()
      AND sm.role IN ('owner', 'manager', 'editor', 'contributor')
    WHERE wb.id = whiteboard_task_links.whiteboard_id
  )
);

CREATE POLICY "whiteboard_revisions_member_select"
ON public.whiteboard_revisions FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.whiteboards wb
    JOIN public.space_members sm ON sm.space_id = wb.space_id AND sm.user_id = auth.uid()
    WHERE wb.id = whiteboard_revisions.whiteboard_id
  )
);

CREATE POLICY "whiteboard_revisions_member_insert"
ON public.whiteboard_revisions FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.whiteboards wb
    JOIN public.space_members sm ON sm.space_id = wb.space_id AND sm.user_id = auth.uid()
      AND sm.role IN ('owner', 'manager', 'editor', 'contributor')
    WHERE wb.id = whiteboard_revisions.whiteboard_id
  )
);

-- Realtime (enable in Supabase dashboard if this statement is not allowed on your plan).
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.whiteboards;
EXCEPTION
  WHEN duplicate_object THEN NULL;
  WHEN undefined_object THEN NULL;
END $$;
