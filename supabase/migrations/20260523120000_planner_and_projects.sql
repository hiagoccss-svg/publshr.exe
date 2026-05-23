-- Planner + projects for Mac Chat "Your projects" and enterprise search_workspace RPC.
-- Safe to re-run (IF NOT EXISTS / DROP POLICY IF EXISTS).

CREATE TABLE IF NOT EXISTS public.projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  status text NOT NULL DEFAULT 'active',
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_projects_workspace ON public.projects(workspace_id);

CREATE TABLE IF NOT EXISTS public.planner_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  project_id uuid REFERENCES public.projects(id) ON DELETE SET NULL,
  title text NOT NULL,
  type text NOT NULL DEFAULT 'internal_task',
  status text NOT NULL DEFAULT 'idea',
  priority text NOT NULL DEFAULT 'medium',
  owner_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  description text,
  due_date date,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT planner_items_type_check CHECK (
    type IN (
      'campaign', 'press_release', 'editorial_article', 'media_pitch',
      'client_announcement', 'social_content', 'event_communication',
      'report', 'coverage_follow_up', 'approval_request', 'internal_task'
    )
  ),
  CONSTRAINT planner_items_status_check CHECK (
    status IN (
      'idea', 'drafting', 'internal_review', 'client_approval', 'scheduled',
      'published', 'coverage_tracking', 'reporting', 'completed'
    )
  ),
  CONSTRAINT planner_items_priority_check CHECK (
    priority IN ('low', 'medium', 'high', 'urgent')
  )
);

CREATE INDEX IF NOT EXISTS idx_planner_items_workspace ON public.planner_items(workspace_id);
CREATE INDEX IF NOT EXISTS idx_planner_items_project ON public.planner_items(project_id);
CREATE INDEX IF NOT EXISTS idx_planner_items_due ON public.planner_items(due_date);

CREATE OR REPLACE FUNCTION public.touch_planner_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS projects_updated_at ON public.projects;
CREATE TRIGGER projects_updated_at
  BEFORE UPDATE ON public.projects
  FOR EACH ROW EXECUTE FUNCTION public.touch_planner_updated_at();

DROP TRIGGER IF EXISTS planner_items_updated_at ON public.planner_items;
CREATE TRIGGER planner_items_updated_at
  BEFORE UPDATE ON public.planner_items
  FOR EACH ROW EXECUTE FUNCTION public.touch_planner_updated_at();

ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.planner_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS projects_select ON public.projects;
DROP POLICY IF EXISTS projects_insert ON public.projects;
DROP POLICY IF EXISTS projects_update ON public.projects;
DROP POLICY IF EXISTS projects_delete ON public.projects;

CREATE POLICY projects_select ON public.projects
  FOR SELECT USING (publshr_private.is_workspace_member(workspace_id, auth.uid()));

CREATE POLICY projects_insert ON public.projects
  FOR INSERT WITH CHECK (publshr_private.is_workspace_member(workspace_id, auth.uid()));

CREATE POLICY projects_update ON public.projects
  FOR UPDATE USING (publshr_private.is_workspace_member(workspace_id, auth.uid()));

CREATE POLICY projects_delete ON public.projects
  FOR DELETE USING (publshr_private.is_workspace_member(workspace_id, auth.uid()));

DROP POLICY IF EXISTS planner_items_select ON public.planner_items;
DROP POLICY IF EXISTS planner_items_insert ON public.planner_items;
DROP POLICY IF EXISTS planner_items_update ON public.planner_items;
DROP POLICY IF EXISTS planner_items_delete ON public.planner_items;

CREATE POLICY planner_items_select ON public.planner_items
  FOR SELECT USING (publshr_private.is_workspace_member(workspace_id, auth.uid()));

CREATE POLICY planner_items_insert ON public.planner_items
  FOR INSERT WITH CHECK (publshr_private.is_workspace_member(workspace_id, auth.uid()));

CREATE POLICY planner_items_update ON public.planner_items
  FOR UPDATE USING (publshr_private.is_workspace_member(workspace_id, auth.uid()));

CREATE POLICY planner_items_delete ON public.planner_items
  FOR DELETE USING (publshr_private.is_workspace_member(workspace_id, auth.uid()));

GRANT SELECT, INSERT, UPDATE, DELETE ON public.projects TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.planner_items TO authenticated;
