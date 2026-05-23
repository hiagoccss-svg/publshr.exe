-- Phases 2–4: reactions, pins, read receipts, message links, voice transcripts

CREATE TABLE IF NOT EXISTS public.chat_reactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  message_id uuid NOT NULL REFERENCES public.chat_messages(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  emoji text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (message_id, user_id, emoji)
);

CREATE INDEX IF NOT EXISTS chat_reactions_message_idx ON public.chat_reactions (message_id);
ALTER TABLE public.chat_reactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY chat_reactions_select ON public.chat_reactions
  FOR SELECT USING (publshr_private.is_workspace_member(workspace_id, auth.uid()));
CREATE POLICY chat_reactions_insert ON public.chat_reactions
  FOR INSERT WITH CHECK (user_id = auth.uid() AND publshr_private.is_workspace_member(workspace_id, auth.uid()));
CREATE POLICY chat_reactions_delete ON public.chat_reactions
  FOR DELETE USING (user_id = auth.uid());

CREATE TABLE IF NOT EXISTS public.chat_pinned_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  channel_id uuid NOT NULL REFERENCES public.chat_channels(id) ON DELETE CASCADE,
  message_id uuid REFERENCES public.chat_messages(id) ON DELETE CASCADE,
  file_id uuid REFERENCES public.files(id) ON DELETE SET NULL,
  pinned_by uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  sort_order integer NOT NULL DEFAULT 0,
  note text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS chat_pinned_channel_idx ON public.chat_pinned_items (channel_id, sort_order);
ALTER TABLE public.chat_pinned_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY chat_pinned_select ON public.chat_pinned_items
  FOR SELECT USING (publshr_private.is_workspace_member(workspace_id, auth.uid()));
CREATE POLICY chat_pinned_insert ON public.chat_pinned_items
  FOR INSERT WITH CHECK (publshr_private.is_workspace_member(workspace_id, auth.uid()));
CREATE POLICY chat_pinned_delete ON public.chat_pinned_items
  FOR DELETE USING (
    pinned_by = auth.uid()
    OR publshr_private.role_at_least(
      publshr_private.workspace_member_role(workspace_id, auth.uid()), 'admin'::publshr_private.workspace_role)
  );

CREATE TABLE IF NOT EXISTS public.chat_read_receipts (
  message_id uuid NOT NULL REFERENCES public.chat_messages(id) ON DELETE CASCADE,
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  seen_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (message_id, user_id)
);

ALTER TABLE public.chat_read_receipts ENABLE ROW LEVEL SECURITY;
CREATE POLICY chat_receipts_select ON public.chat_read_receipts
  FOR SELECT USING (publshr_private.is_workspace_member(workspace_id, auth.uid()));
CREATE POLICY chat_receipts_insert ON public.chat_read_receipts
  FOR INSERT WITH CHECK (user_id = auth.uid() AND publshr_private.is_workspace_member(workspace_id, auth.uid()));

CREATE TABLE IF NOT EXISTS public.chat_message_links (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  message_id uuid NOT NULL REFERENCES public.chat_messages(id) ON DELETE CASCADE,
  link_type text NOT NULL CHECK (link_type IN (
    'task', 'planner_item', 'campaign', 'document', 'report', 'coverage', 'approval', 'file'
  )),
  link_id uuid NOT NULL,
  preview jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS chat_message_links_message_idx ON public.chat_message_links (message_id);
ALTER TABLE public.chat_message_links ENABLE ROW LEVEL SECURITY;
CREATE POLICY chat_message_links_select ON public.chat_message_links
  FOR SELECT USING (publshr_private.is_workspace_member(workspace_id, auth.uid()));
CREATE POLICY chat_message_links_insert ON public.chat_message_links
  FOR INSERT WITH CHECK (publshr_private.is_workspace_member(workspace_id, auth.uid()));

CREATE TABLE IF NOT EXISTS public.chat_voice_transcripts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  message_id uuid NOT NULL REFERENCES public.chat_messages(id) ON DELETE CASCADE,
  storage_path text NOT NULL,
  duration_ms integer NOT NULL DEFAULT 0,
  waveform jsonb NOT NULL DEFAULT '[]'::jsonb,
  transcript text,
  transcript_status text NOT NULL DEFAULT 'pending'
    CHECK (transcript_status IN ('pending', 'processing', 'ready', 'failed')),
  segments jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.chat_voice_transcripts ENABLE ROW LEVEL SECURITY;
CREATE POLICY chat_voice_transcripts_select ON public.chat_voice_transcripts
  FOR SELECT USING (publshr_private.is_workspace_member(workspace_id, auth.uid()));
CREATE POLICY chat_voice_transcripts_insert ON public.chat_voice_transcripts
  FOR INSERT WITH CHECK (publshr_private.is_workspace_member(workspace_id, auth.uid()));
CREATE POLICY chat_voice_transcripts_update ON public.chat_voice_transcripts
  FOR UPDATE USING (publshr_private.is_workspace_member(workspace_id, auth.uid()));

CREATE TRIGGER chat_voice_transcripts_updated_at
  BEFORE UPDATE ON public.chat_voice_transcripts
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_reactions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_pinned_items;
