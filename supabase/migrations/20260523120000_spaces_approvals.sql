-- Workspace approval requests (live Supabase; mirrors desktop/spaces local schema).

CREATE TABLE IF NOT EXISTS public.approvals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id uuid NOT NULL REFERENCES public.spaces(id) ON DELETE CASCADE,
  task_id uuid REFERENCES public.tasks(id) ON DELETE SET NULL,
  document_id uuid REFERENCES public.documents(id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'requested'
    CHECK (status IN ('requested', 'in_review', 'approved', 'rejected')),
  title text NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS approvals_space_idx ON public.approvals (space_id, updated_at DESC);

ALTER TABLE public.approvals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS approvals_space_members ON public.approvals;
CREATE POLICY approvals_space_members ON public.approvals
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.spaces s
      WHERE s.id = approvals.space_id
        AND publshr_private.is_workspace_member(s.workspace_id, auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.spaces s
      WHERE s.id = approvals.space_id
        AND publshr_private.is_workspace_member(s.workspace_id, auth.uid())
    )
  );
