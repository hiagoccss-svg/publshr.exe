-- Allow workspace admins (and members removing themselves) to delete channel membership rows.
CREATE POLICY chat_channel_members_delete ON public.chat_channel_members
  FOR DELETE USING (
    user_id = auth.uid()
    OR publshr_private.role_at_least(
      publshr_private.workspace_member_role(workspace_id, auth.uid()),
      'admin'::publshr_private.workspace_role
    )
  );
