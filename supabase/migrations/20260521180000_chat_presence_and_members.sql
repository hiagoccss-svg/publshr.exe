-- Online presence per workspace user
CREATE TABLE IF NOT EXISTS public.chat_presence (
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'offline'
    CHECK (status IN ('online', 'away', 'busy', 'in_meeting', 'offline', 'invisible')),
  activity text,
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (workspace_id, user_id)
);

ALTER TABLE public.chat_presence ENABLE ROW LEVEL SECURITY;

CREATE POLICY chat_presence_select ON public.chat_presence
  FOR SELECT USING (publshr_private.is_workspace_member(workspace_id, auth.uid()));

CREATE POLICY chat_presence_upsert ON public.chat_presence
  FOR ALL USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Channel / DM membership
CREATE TABLE IF NOT EXISTS public.chat_channel_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  channel_id uuid NOT NULL REFERENCES public.chat_channels(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member')),
  last_read_at timestamptz,
  notification_level text NOT NULL DEFAULT 'all'
    CHECK (notification_level IN ('all', 'mentions', 'muted')),
  joined_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (channel_id, user_id)
);

CREATE INDEX IF NOT EXISTS chat_channel_members_user_idx
  ON public.chat_channel_members (workspace_id, user_id);

ALTER TABLE public.chat_channel_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY chat_channel_members_select ON public.chat_channel_members
  FOR SELECT USING (publshr_private.is_workspace_member(workspace_id, auth.uid()));

CREATE POLICY chat_channel_members_insert ON public.chat_channel_members
  FOR INSERT WITH CHECK (publshr_private.is_workspace_member(workspace_id, auth.uid()));

CREATE POLICY chat_channel_members_update ON public.chat_channel_members
  FOR UPDATE USING (
    user_id = auth.uid()
    OR publshr_private.role_at_least(
      publshr_private.workspace_member_role(workspace_id, auth.uid()),
      'admin'::workspace_role
    )
  );

ALTER TABLE public.chat_channels DROP CONSTRAINT IF EXISTS chat_channels_kind_check;
ALTER TABLE public.chat_channels ADD CONSTRAINT chat_channels_kind_check
  CHECK (kind = ANY (ARRAY['channel'::text, 'dm'::text, 'group'::text, 'thread'::text]));

ALTER TABLE public.chat_channels DROP CONSTRAINT IF EXISTS chat_channels_visibility_check;
ALTER TABLE public.chat_channels ADD CONSTRAINT chat_channels_visibility_check
  CHECK (visibility = ANY (ARRAY[
    'public', 'private', 'internal', 'client_safe', 'announcement', 'read_only', 'hidden', 'invite_only'
  ]));

ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_presence;

CREATE TRIGGER chat_presence_updated_at
  BEFORE UPDATE ON public.chat_presence
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
