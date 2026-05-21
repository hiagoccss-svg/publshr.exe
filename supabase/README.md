# Supabase backend (publshr.exe)

Project: **publshr.exe** (`lboesdtsrqfvosznjpdy`)  
URL: `https://lboesdtsrqfvosznjpdy.supabase.co`

## Tables (enterprise)

- `workspaces`, `workspace_members`
- `spaces` (ClickUp-style hierarchy via `parent_id`)
- `tasks`
- `chat_channels`, `chat_messages`
- `profiles`

## Mac app config

Keys are bundled in `native/publshr/Resources/SupabaseConfig.plist` (publishable key only).

Override with environment variables:

- `PUBLSHR_SUPABASE_URL`
- `PUBLSHR_SUPABASE_KEY`

## Auth

Enable Email provider in Supabase Dashboard → Authentication.

New users: app calls RPC `create_workspace(p_name, p_slug)` after sign-up.
