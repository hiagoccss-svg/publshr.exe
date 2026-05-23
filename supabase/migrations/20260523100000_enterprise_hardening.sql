-- Enterprise platform tables, scheduled-message dispatch, RPC hardening, privacy audit read.
-- Safe to re-run on production (lboesdtsrqfvosznjpdy) and fresh installs.

-- ---------------------------------------------------------------------------
-- Subscription catalog + workspace billing columns
-- ---------------------------------------------------------------------------
ALTER TABLE IF EXISTS public.workspaces
  ADD COLUMN IF NOT EXISTS plan_id text NOT NULL DEFAULT 'trial';

CREATE TABLE IF NOT EXISTS public.subscription_plans (
  id text PRIMARY KEY,
  name text NOT NULL,
  seat_limit int NOT NULL DEFAULT 5,
  includes_chat boolean NOT NULL DEFAULT true,
  includes_spaces boolean NOT NULL DEFAULT true,
  includes_calls boolean NOT NULL DEFAULT false,
  includes_files_gb int NOT NULL DEFAULT 10,
  price_label text NOT NULL DEFAULT 'Contact sales'
);

INSERT INTO public.subscription_plans (
  id, name, seat_limit, includes_chat, includes_spaces, includes_calls, includes_files_gb, price_label
) VALUES
  ('trial', 'Trial', 3, true, true, true, 5, 'Free trial'),
  ('team', 'Team', 25, true, true, true, 50, 'Per workspace / month'),
  ('enterprise', 'Enterprise', 500, true, true, true, 500, 'Custom')
ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS subscription_plans_read ON public.subscription_plans;
CREATE POLICY subscription_plans_read ON public.subscription_plans
  FOR SELECT USING (true);

-- ---------------------------------------------------------------------------
-- Device registrations (Settings → Devices)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.device_registrations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  workspace_id uuid REFERENCES public.workspaces(id) ON DELETE SET NULL,
  device_key text NOT NULL,
  device_name text NOT NULL DEFAULT '',
  platform text NOT NULL DEFAULT 'macos',
  app_version text NOT NULL DEFAULT '',
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, device_key)
);

CREATE INDEX IF NOT EXISTS device_registrations_user_idx ON public.device_registrations(user_id);

ALTER TABLE public.device_registrations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS devices_own ON public.device_registrations;
CREATE POLICY devices_own ON public.device_registrations
  FOR ALL USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Privacy / compliance audit (write from app; read own + workspace admins)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.privacy_audit_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  workspace_id uuid REFERENCES public.workspaces(id) ON DELETE SET NULL,
  event_type text NOT NULL,
  detail text NOT NULL DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS privacy_audit_workspace_idx
  ON public.privacy_audit_events (workspace_id, created_at DESC);

ALTER TABLE public.privacy_audit_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS privacy_audit_own ON public.privacy_audit_events;
DROP POLICY IF EXISTS privacy_audit_insert ON public.privacy_audit_events;
DROP POLICY IF EXISTS privacy_audit_select ON public.privacy_audit_events;

CREATE POLICY privacy_audit_insert ON public.privacy_audit_events
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY privacy_audit_select ON public.privacy_audit_events
  FOR SELECT USING (
    user_id = auth.uid()
    OR (
      workspace_id IS NOT NULL
      AND publshr_private.role_at_least(
        publshr_private.workspace_member_role(workspace_id, auth.uid()),
        'admin'::public.workspace_role
      )
    )
  );

-- ---------------------------------------------------------------------------
-- Call signaling (LiveKit room name stored; media out of band)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.call_rooms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  channel_id uuid,
  space_id uuid,
  title text NOT NULL DEFAULT 'Call',
  kind text NOT NULL DEFAULT 'voice' CHECK (kind IN ('voice', 'video')),
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'ended')),
  created_by uuid NOT NULL REFERENCES auth.users(id),
  livekit_room text,
  created_at timestamptz NOT NULL DEFAULT now(),
  ended_at timestamptz
);

CREATE TABLE IF NOT EXISTS public.call_participants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id uuid NOT NULL REFERENCES public.call_rooms(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  joined_at timestamptz NOT NULL DEFAULT now(),
  left_at timestamptz,
  is_muted boolean NOT NULL DEFAULT false,
  is_video_enabled boolean NOT NULL DEFAULT false,
  UNIQUE (room_id, user_id)
);

ALTER TABLE public.call_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.call_participants ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS call_rooms_member ON public.call_rooms;
DROP POLICY IF EXISTS call_participants_member ON public.call_participants;
DROP POLICY IF EXISTS call_rooms_workspace_member ON public.call_rooms;
DROP POLICY IF EXISTS call_participants_workspace_member ON public.call_participants;

CREATE POLICY call_rooms_workspace_member ON public.call_rooms
  FOR ALL TO authenticated
  USING (publshr_private.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (publshr_private.is_workspace_member(workspace_id, auth.uid()));

CREATE POLICY call_participants_workspace_member ON public.call_participants
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.call_rooms r
      WHERE r.id = room_id
        AND publshr_private.is_workspace_member(r.workspace_id, auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.call_rooms r
      WHERE r.id = room_id
        AND publshr_private.is_workspace_member(r.workspace_id, auth.uid())
    )
  );

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.call_rooms;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.call_participants;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ---------------------------------------------------------------------------
-- Server-side scheduled chat delivery (runs without mac IDE open)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.dispatch_due_chat_scheduled_messages()
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  r record;
  n int := 0;
BEGIN
  FOR r IN
    SELECT *
    FROM public.chat_scheduled_messages
    WHERE status = 'pending' AND send_at <= now()
    ORDER BY send_at
    LIMIT 50
    FOR UPDATE SKIP LOCKED
  LOOP
    BEGIN
      INSERT INTO public.chat_messages (
        workspace_id, channel_id, user_id, body, thread_parent_id
      ) VALUES (
        r.workspace_id, r.channel_id, r.user_id, r.body, r.thread_parent_id
      );

      UPDATE public.chat_scheduled_messages
      SET status = 'sent', updated_at = now()
      WHERE id = r.id;

      n := n + 1;
    EXCEPTION WHEN OTHERS THEN
      UPDATE public.chat_scheduled_messages
      SET status = 'failed', updated_at = now()
      WHERE id = r.id;
    END;
  END LOOP;

  RETURN n;
END;
$$;

REVOKE ALL ON FUNCTION public.dispatch_due_chat_scheduled_messages() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.dispatch_due_chat_scheduled_messages() TO service_role;

-- pg_cron (optional): every minute on Supabase hosted when extension is enabled
DO $cron$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.unschedule(jobid)
    FROM cron.job
    WHERE jobname = 'dispatch_chat_scheduled_messages';

    PERFORM cron.schedule(
      'dispatch_chat_scheduled_messages',
      '* * * * *',
      $job$SELECT public.dispatch_due_chat_scheduled_messages();$job$
    );
  END IF;
EXCEPTION
  WHEN undefined_table OR undefined_function OR insufficient_privilege THEN
    NULL;
END;
$cron$;

-- ---------------------------------------------------------------------------
-- RPC execute grants: authenticated only for user-facing RPCs
-- ---------------------------------------------------------------------------
DO $revoke$
DECLARE
  fn record;
BEGIN
  FOR fn IN
    SELECT p.oid::regprocedure AS sig
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname IN (
        'handle_new_user',
        'handle_new_workspace',
        'seed_workspace_default_channels',
        'chat_update_thread_counts'
      )
  LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon', fn.sig);
  END LOOP;
END;
$revoke$;

REVOKE ALL ON FUNCTION public.search_workspace(uuid, text, int) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.search_workspace(uuid, text, int) TO authenticated;

DO $grant_create_ws$
DECLARE
  fn record;
BEGIN
  FOR fn IN
    SELECT p.oid::regprocedure AS sig
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'create_workspace'
  LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon', fn.sig);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', fn.sig);
  END LOOP;
END;
$grant_create_ws$;
