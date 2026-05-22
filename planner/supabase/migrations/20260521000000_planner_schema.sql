-- Publshr Planner module schema
-- Apply via Supabase CLI or SQL editor

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Workspaces
CREATE TABLE IF NOT EXISTS public.workspaces (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  logo_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Workspace members
CREATE TABLE IF NOT EXISTS public.workspace_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'editor' CHECK (role IN ('owner', 'admin', 'manager', 'editor', 'viewer', 'client')),
  status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (workspace_id, user_id)
);

-- Clients
CREATE TABLE IF NOT EXISTS public.clients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  logo_url TEXT,
  contact_email TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Projects
CREATE TABLE IF NOT EXISTS public.projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  client_id UUID REFERENCES public.clients(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Campaigns
CREATE TABLE IF NOT EXISTS public.campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  project_id UUID REFERENCES public.projects(id) ON DELETE SET NULL,
  client_id UUID REFERENCES public.clients(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  description TEXT,
  start_date DATE,
  end_date DATE,
  status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Planner items
CREATE TABLE IF NOT EXISTS public.planner_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  project_id UUID REFERENCES public.projects(id) ON DELETE SET NULL,
  client_id UUID REFERENCES public.clients(id) ON DELETE SET NULL,
  campaign_id UUID REFERENCES public.campaigns(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN (
    'campaign', 'press_release', 'editorial_article', 'media_pitch',
    'client_announcement', 'social_content', 'event_communication',
    'report', 'coverage_follow_up', 'approval_request', 'internal_task'
  )),
  status TEXT NOT NULL DEFAULT 'idea' CHECK (status IN (
    'idea', 'drafting', 'internal_review', 'client_approval', 'scheduled',
    'published', 'coverage_tracking', 'reporting', 'completed'
  )),
  priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  owner_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  description TEXT,
  start_date DATE,
  due_date DATE,
  publish_date DATE,
  tags JSONB NOT NULL DEFAULT '[]'::jsonb,
  editor_document_id UUID,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_planner_items_workspace ON public.planner_items(workspace_id);
CREATE INDEX IF NOT EXISTS idx_planner_items_due ON public.planner_items(due_date);

-- Assignees
CREATE TABLE IF NOT EXISTS public.planner_item_assignees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  planner_item_id UUID NOT NULL REFERENCES public.planner_items(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  UNIQUE (planner_item_id, user_id)
);

-- Editor documents
CREATE TABLE IF NOT EXISTS public.editor_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  planner_item_id UUID REFERENCES public.planner_items(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  subtitle TEXT,
  content_json JSONB,
  content_html TEXT,
  status TEXT NOT NULL DEFAULT 'draft',
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.planner_items
  ADD CONSTRAINT planner_items_editor_fk
  FOREIGN KEY (editor_document_id) REFERENCES public.editor_documents(id) ON DELETE SET NULL;

-- Approvals
CREATE TABLE IF NOT EXISTS public.approvals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  planner_item_id UUID NOT NULL REFERENCES public.planner_items(id) ON DELETE CASCADE,
  editor_document_id UUID REFERENCES public.editor_documents(id) ON DELETE SET NULL,
  stage TEXT NOT NULL CHECK (stage IN (
    'draft_review', 'internal_review', 'manager_approval',
    'client_approval', 'legal_approval', 'final_approval'
  )),
  approver_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'not_requested' CHECK (status IN (
    'not_requested', 'requested', 'changes_requested', 'approved', 'rejected', 'overdue'
  )),
  requested_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  requested_at TIMESTAMPTZ,
  responded_at TIMESTAMPTZ,
  comments TEXT,
  document_version_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Comments
CREATE TABLE IF NOT EXISTS public.planner_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  planner_item_id UUID REFERENCES public.planner_items(id) ON DELETE CASCADE,
  editor_document_id UUID REFERENCES public.editor_documents(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  visibility TEXT NOT NULL DEFAULT 'internal' CHECK (visibility IN ('internal', 'client')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Attachments
CREATE TABLE IF NOT EXISTS public.attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  planner_item_id UUID REFERENCES public.planner_items(id) ON DELETE CASCADE,
  editor_document_id UUID REFERENCES public.editor_documents(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_type TEXT,
  file_size BIGINT,
  uploaded_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Activity log
CREATE TABLE IF NOT EXISTS public.activity_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  planner_item_id UUID REFERENCES public.planner_items(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Notifications
CREATE TABLE IF NOT EXISTS public.planner_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT,
  read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS planner_items_updated_at ON public.planner_items;
CREATE TRIGGER planner_items_updated_at
  BEFORE UPDATE ON public.planner_items
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS editor_documents_updated_at ON public.editor_documents;
CREATE TRIGGER editor_documents_updated_at
  BEFORE UPDATE ON public.editor_documents
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Helper: is workspace member
CREATE OR REPLACE FUNCTION public.is_workspace_member(ws_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.workspace_members
    WHERE workspace_id = ws_id AND user_id = auth.uid() AND status = 'active'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public;

-- RLS
ALTER TABLE public.workspaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workspace_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.planner_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.planner_item_assignees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.editor_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.planner_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.planner_notifications ENABLE ROW LEVEL SECURITY;

-- Workspaces: members can read
CREATE POLICY workspaces_select ON public.workspaces FOR SELECT
  USING (public.is_workspace_member(id));

CREATE POLICY workspaces_insert ON public.workspaces FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY workspace_members_select ON public.workspace_members FOR SELECT
  USING (public.is_workspace_member(workspace_id));

CREATE POLICY workspace_members_insert ON public.workspace_members FOR INSERT
  WITH CHECK (user_id = auth.uid() OR public.is_workspace_member(workspace_id));

-- Planner items
CREATE POLICY planner_items_select ON public.planner_items FOR SELECT
  USING (public.is_workspace_member(workspace_id));

CREATE POLICY planner_items_insert ON public.planner_items FOR INSERT
  WITH CHECK (public.is_workspace_member(workspace_id));

CREATE POLICY planner_items_update ON public.planner_items FOR UPDATE
  USING (public.is_workspace_member(workspace_id));

CREATE POLICY planner_items_delete ON public.planner_items FOR DELETE
  USING (public.is_workspace_member(workspace_id));

-- Mirror policies for related tables
CREATE POLICY clients_all ON public.clients FOR ALL
  USING (public.is_workspace_member(workspace_id))
  WITH CHECK (public.is_workspace_member(workspace_id));

CREATE POLICY projects_all ON public.projects FOR ALL
  USING (public.is_workspace_member(workspace_id))
  WITH CHECK (public.is_workspace_member(workspace_id));

CREATE POLICY campaigns_all ON public.campaigns FOR ALL
  USING (public.is_workspace_member(workspace_id))
  WITH CHECK (public.is_workspace_member(workspace_id));

CREATE POLICY editor_documents_all ON public.editor_documents FOR ALL
  USING (public.is_workspace_member(workspace_id))
  WITH CHECK (public.is_workspace_member(workspace_id));

CREATE POLICY assignees_all ON public.planner_item_assignees FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.planner_items pi
      WHERE pi.id = planner_item_id AND public.is_workspace_member(pi.workspace_id)
    )
  );

CREATE POLICY approvals_all ON public.approvals FOR ALL
  USING (public.is_workspace_member(workspace_id))
  WITH CHECK (public.is_workspace_member(workspace_id));

CREATE POLICY comments_select ON public.planner_comments FOR SELECT
  USING (
    public.is_workspace_member(workspace_id)
    AND (
      visibility = 'client'
      OR NOT EXISTS (
        SELECT 1 FROM public.workspace_members wm
        WHERE wm.workspace_id = planner_comments.workspace_id
          AND wm.user_id = auth.uid() AND wm.role = 'client'
      )
    )
  );

CREATE POLICY comments_insert ON public.planner_comments FOR INSERT
  WITH CHECK (public.is_workspace_member(workspace_id) AND user_id = auth.uid());

CREATE POLICY attachments_all ON public.attachments FOR ALL
  USING (public.is_workspace_member(workspace_id))
  WITH CHECK (public.is_workspace_member(workspace_id));

CREATE POLICY activity_log_select ON public.activity_log FOR SELECT
  USING (public.is_workspace_member(workspace_id));

CREATE POLICY notifications_select ON public.planner_notifications FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY notifications_update ON public.planner_notifications FOR UPDATE
  USING (user_id = auth.uid());

-- Realtime publication (run in dashboard if needed)
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.planner_items;
