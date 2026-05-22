-- ClickUp chat parity: message assignment, scheduled sends

ALTER TABLE public.chat_messages
  ADD COLUMN IF NOT EXISTS assigned_to uuid REFERENCES public.profiles(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS chat_messages_assigned_idx
  ON public.chat_messages (workspace_id, assigned_to)
  WHERE assigned_to IS NOT NULL;

CREATE TABLE IF NOT EXISTS public.chat_scheduled_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  channel_id uuid NOT NULL REFERENCES public.chat_channels(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  body text NOT NULL,
  thread_parent_id uuid REFERENCES public.chat_messages(id) ON DELETE SET NULL,
  send_at timestamptz NOT NULL,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'sent', 'cancelled', 'failed')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS chat_scheduled_pending_idx
  ON public.chat_scheduled_messages (workspace_id, send_at)
  WHERE status = 'pending';

ALTER TABLE public.chat_scheduled_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY chat_scheduled_select ON public.chat_scheduled_messages
  FOR SELECT USING (
    user_id = auth.uid()
    AND publshr_private.is_workspace_member(workspace_id, auth.uid())
  );

CREATE POLICY chat_scheduled_insert ON public.chat_scheduled_messages
  FOR INSERT WITH CHECK (
    user_id = auth.uid()
    AND publshr_private.is_workspace_member(workspace_id, auth.uid())
  );

CREATE POLICY chat_scheduled_update ON public.chat_scheduled_messages
  FOR UPDATE USING (
    user_id = auth.uid()
    AND publshr_private.is_workspace_member(workspace_id, auth.uid())
  );

CREATE POLICY chat_scheduled_delete ON public.chat_scheduled_messages
  FOR DELETE USING (
    user_id = auth.uid()
    AND publshr_private.is_workspace_member(workspace_id, auth.uid())
  );

CREATE TRIGGER chat_scheduled_messages_updated_at
  BEFORE UPDATE ON public.chat_scheduled_messages
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_scheduled_messages;
