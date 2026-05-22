-- Avatar uploads: use {user_id}/avatar.{ext} (avoids Storage API mis-assigning owner_id from "avatars/" prefix).

CREATE POLICY "workspace_files_avatar_insert_own_v2"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'workspace-files'
  AND (
    name LIKE auth.uid()::text || '/avatar.%'
    OR name LIKE 'avatars/' || auth.uid()::text || '.%'
  )
);

CREATE POLICY "workspace_files_avatar_update_own_v2"
ON storage.objects FOR UPDATE TO authenticated
USING (
  bucket_id = 'workspace-files'
  AND (
    name LIKE auth.uid()::text || '/avatar.%'
    OR name LIKE 'avatars/' || auth.uid()::text || '.%'
  )
)
WITH CHECK (
  bucket_id = 'workspace-files'
  AND (
    name LIKE auth.uid()::text || '/avatar.%'
    OR name LIKE 'avatars/' || auth.uid()::text || '.%'
  )
);

CREATE POLICY "workspace_files_avatar_select_coworker_v2"
ON storage.objects FOR SELECT TO authenticated
USING (
  bucket_id = 'workspace-files'
  AND (
    name ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/avatar\.'
    OR name LIKE 'avatars/%'
  )
  AND EXISTS (
    SELECT 1
    FROM public.workspace_members wm_self
    JOIN public.workspace_members wm_owner
      ON wm_owner.workspace_id = wm_self.workspace_id
    WHERE wm_self.user_id = auth.uid()
      AND (
        name LIKE wm_owner.user_id::text || '/avatar.%'
        OR name LIKE 'avatars/' || wm_owner.user_id::text || '.%'
      )
  )
);
