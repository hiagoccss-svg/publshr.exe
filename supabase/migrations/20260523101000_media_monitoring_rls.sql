-- Media monitoring RLS (workspace-scoped). Requires tables from
-- desktop/media-monitoring/supabase/migrations/20250521000000_media_monitoring.sql

ALTER TABLE public.monitor_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.monitor_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_coverage ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.publication_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coverage_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coverage_activity ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS monitor_select ON public.monitor_profiles;
DROP POLICY IF EXISTS monitor_insert ON public.monitor_profiles;
DROP POLICY IF EXISTS monitor_update ON public.monitor_profiles;
DROP POLICY IF EXISTS monitor_delete ON public.monitor_profiles;

CREATE POLICY monitor_select ON public.monitor_profiles
  FOR SELECT USING (public.user_has_workspace_access(workspace_id));
CREATE POLICY monitor_insert ON public.monitor_profiles
  FOR INSERT WITH CHECK (public.user_has_workspace_access(workspace_id));
CREATE POLICY monitor_update ON public.monitor_profiles
  FOR UPDATE USING (public.user_has_workspace_access(workspace_id));
CREATE POLICY monitor_delete ON public.monitor_profiles
  FOR DELETE USING (public.user_has_workspace_access(workspace_id));

DROP POLICY IF EXISTS results_select ON public.monitor_results;
DROP POLICY IF EXISTS results_insert ON public.monitor_results;
DROP POLICY IF EXISTS results_update ON public.monitor_results;
DROP POLICY IF EXISTS results_delete ON public.monitor_results;

CREATE POLICY results_select ON public.monitor_results
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.monitor_profiles mp
      WHERE mp.id = monitor_profile_id
        AND public.user_has_workspace_access(mp.workspace_id)
    )
  );
CREATE POLICY results_insert ON public.monitor_results
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.monitor_profiles mp
      WHERE mp.id = monitor_profile_id
        AND public.user_has_workspace_access(mp.workspace_id)
    )
  );
CREATE POLICY results_update ON public.monitor_results
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.monitor_profiles mp
      WHERE mp.id = monitor_profile_id
        AND public.user_has_workspace_access(mp.workspace_id)
    )
  );
CREATE POLICY results_delete ON public.monitor_results
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.monitor_profiles mp
      WHERE mp.id = monitor_profile_id
        AND public.user_has_workspace_access(mp.workspace_id)
    )
  );

DROP POLICY IF EXISTS saved_select ON public.saved_coverage;
DROP POLICY IF EXISTS saved_insert ON public.saved_coverage;
DROP POLICY IF EXISTS saved_update ON public.saved_coverage;
DROP POLICY IF EXISTS saved_delete ON public.saved_coverage;

CREATE POLICY saved_select ON public.saved_coverage
  FOR SELECT USING (public.user_has_workspace_access(workspace_id));
CREATE POLICY saved_insert ON public.saved_coverage
  FOR INSERT WITH CHECK (public.user_has_workspace_access(workspace_id));
CREATE POLICY saved_update ON public.saved_coverage
  FOR UPDATE USING (public.user_has_workspace_access(workspace_id));
CREATE POLICY saved_delete ON public.saved_coverage
  FOR DELETE USING (public.user_has_workspace_access(workspace_id));

DROP POLICY IF EXISTS pub_read_verified ON public.publication_sources;
CREATE POLICY pub_read_verified ON public.publication_sources
  FOR SELECT USING (verified = true OR public.user_has_workspace_access(workspace_id));

DROP POLICY IF EXISTS comments_select ON public.coverage_comments;
DROP POLICY IF EXISTS comments_insert ON public.coverage_comments;

CREATE POLICY comments_select ON public.coverage_comments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.monitor_results mr
      JOIN public.monitor_profiles mp ON mp.id = mr.monitor_profile_id
      WHERE mr.id = monitor_result_id
        AND public.user_has_workspace_access(mp.workspace_id)
    )
  );
CREATE POLICY comments_insert ON public.coverage_comments
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM public.monitor_results mr
      JOIN public.monitor_profiles mp ON mp.id = mr.monitor_profile_id
      WHERE mr.id = monitor_result_id
        AND public.user_has_workspace_access(mp.workspace_id)
    )
  );

DROP POLICY IF EXISTS activity_select ON public.coverage_activity;
DROP POLICY IF EXISTS activity_insert ON public.coverage_activity;

CREATE POLICY activity_select ON public.coverage_activity
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.monitor_results mr
      JOIN public.monitor_profiles mp ON mp.id = mr.monitor_profile_id
      WHERE mr.id = monitor_result_id
        AND public.user_has_workspace_access(mp.workspace_id)
    )
  );
CREATE POLICY activity_insert ON public.coverage_activity
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.monitor_results mr
      JOIN public.monitor_profiles mp ON mp.id = mr.monitor_profile_id
      WHERE mr.id = monitor_result_id
        AND public.user_has_workspace_access(mp.workspace_id)
    )
  );
