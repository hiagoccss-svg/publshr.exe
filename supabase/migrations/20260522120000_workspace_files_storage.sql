-- workspace-files bucket: chat attachments + profile avatars (private; app uses signed URLs)

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'workspace-files',
  'workspace-files',
  false,
  52428800,
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'application/pdf', 'audio/mpeg', 'audio/mp4', 'audio/webm', 'video/mp4']::text[]
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

CREATE POLICY "workspace_files_avatar_insert_own"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'workspace-files'
  AND name LIKE 'avatars/' || auth.uid()::text || '.%'
);

CREATE POLICY "workspace_files_avatar_update_own"
ON storage.objects FOR UPDATE TO authenticated
USING (
  bucket_id = 'workspace-files'
  AND name LIKE 'avatars/' || auth.uid()::text || '.%'
)
WITH CHECK (
  bucket_id = 'workspace-files'
  AND name LIKE 'avatars/' || auth.uid()::text || '.%'
);

CREATE POLICY "workspace_files_avatar_select_coworker"
ON storage.objects FOR SELECT TO authenticated
USING (
  bucket_id = 'workspace-files'
  AND name LIKE 'avatars/%'
  AND EXISTS (
    SELECT 1
    FROM public.workspace_members wm_self
    JOIN public.workspace_members wm_owner
      ON wm_owner.workspace_id = wm_self.workspace_id
    WHERE wm_self.user_id = auth.uid()
      AND wm_self.status = 'active'
      AND wm_owner.status = 'active'
      AND name LIKE 'avatars/' || wm_owner.user_id::text || '.%'
  )
);

CREATE POLICY "workspace_files_member_read"
ON storage.objects FOR SELECT TO authenticated
USING (
  bucket_id = 'workspace-files'
  AND name NOT LIKE 'avatars/%'
  AND EXISTS (
    SELECT 1 FROM public.workspace_members wm
    WHERE wm.user_id = auth.uid() AND wm.status = 'active'
  )
);

CREATE POLICY "workspace_files_member_write"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'workspace-files'
  AND name NOT LIKE 'avatars/%'
  AND EXISTS (
    SELECT 1 FROM public.workspace_members wm
    WHERE wm.user_id = auth.uid() AND wm.status = 'active'
  )
);

-- Call signaling: workspace members only (replaces permissive policies from 002).
DROP POLICY IF EXISTS "call_rooms_member" ON public.call_rooms;
DROP POLICY IF EXISTS "call_participants_member" ON public.call_participants;

CREATE POLICY "call_rooms_workspace_member"
ON public.call_rooms FOR ALL TO authenticated
USING (publshr_private.is_workspace_member(workspace_id, auth.uid()))
WITH CHECK (publshr_private.is_workspace_member(workspace_id, auth.uid()));

CREATE POLICY "call_participants_workspace_member"
ON public.call_participants FOR ALL TO authenticated
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
