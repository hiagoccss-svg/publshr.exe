# Supabase migrations (production)

Apply to project **publshr.exe** (`lboesdtsrqfvosznjpdy`) in this order:

1. `planner/supabase/migrations/20260521000000_planner_schema.sql` (if `workspaces` missing)
2. `20260522000000_enterprise_foundation.sql`
3. `20260521180000_chat_presence_and_members.sql`
4. `20260521200000_chat_phases_2_4.sql`
5. `20260522010000_spaces_clickup_enterprise.sql`
6. `20260522100000_spaces_legacy_schema_upgrade.sql`
7. `20260522120000_workspace_files_storage.sql`
8. `20260522120000_chat_clickup_parity.sql`
9. `20260522130000_spaces_documents_and_realtime.sql`
10. `20260522131000_seed_workspace_default_channels.sql`
11. `20260522140000_chat_channel_members_delete.sql`
12. `20260522140000_whiteboards_enterprise.sql`
13. `20260523100000_enterprise_hardening.sql` — devices, subscriptions, calls, privacy audit, scheduled dispatch, RPC hardening
14. `20260523120000_seed_workspace_default_space.sql` — default **General** space + folder + list per workspace (uses `type = project` on production)

Media monitoring (optional): `desktop/media-monitoring/supabase/migrations/20250521000000_media_monitoring.sql` plus RLS from production `media_monitoring` migration.

Verify after apply:

```bash
bash mac/publshr/scripts/verify-enterprise.sh
```
