-- Upgrade legacy `spaces` / `tasks` tables for the Mac IDE (ClickUp-style columns + folders/lists).
-- Safe to re-run.

ALTER TABLE public.spaces ADD COLUMN IF NOT EXISTS description text NOT NULL DEFAULT '';
ALTER TABLE public.spaces ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'active';
ALTER TABLE public.spaces ADD COLUMN IF NOT EXISTS is_pinned boolean NOT NULL DEFAULT false;
ALTER TABLE public.spaces ADD COLUMN IF NOT EXISTS is_favourite boolean NOT NULL DEFAULT false;
ALTER TABLE public.spaces ADD COLUMN IF NOT EXISTS client_mode boolean NOT NULL DEFAULT false;
ALTER TABLE public.spaces ADD COLUMN IF NOT EXISTS owner_id uuid REFERENCES auth.users(id) ON DELETE SET NULL;

UPDATE public.spaces s
SET owner_id = w.owner_id
FROM public.workspaces w
WHERE s.workspace_id = w.id AND s.owner_id IS NULL;

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

ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS list_id uuid REFERENCES public.space_lists(id) ON DELETE SET NULL;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS tags text[] NOT NULL DEFAULT '{}';
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS checklist jsonb NOT NULL DEFAULT '[]'::jsonb;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS start_date date;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS time_spent_minutes int NOT NULL DEFAULT 0;

ALTER TABLE public.space_folders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.space_lists ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS space_folders_access ON public.space_folders;
CREATE POLICY space_folders_access ON public.space_folders
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.spaces s
      WHERE s.id = space_folders.space_id
        AND publshr_private.is_workspace_member(s.workspace_id, auth.uid())
    )
  );

DROP POLICY IF EXISTS space_lists_access ON public.space_lists;
CREATE POLICY space_lists_access ON public.space_lists
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.spaces s
      WHERE s.id = space_lists.space_id
        AND publshr_private.is_workspace_member(s.workspace_id, auth.uid())
    )
  );
