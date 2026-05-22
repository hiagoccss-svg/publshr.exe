# publshr (macOS)

Native SwiftUI app matching **Cursor on Mac** layout and colors, backed by **Supabase Auth**.

## Install

```bash
./install.sh
```

Installs **Publshr.app** to `/Applications` and the `publshr` launcher in `/usr/local/bin`.

## Build

```bash
swift build -c release --product PublshrApp --product publshr
./scripts/package-release.sh 0.2.0
```

On macOS the tarball includes `Publshr.app`, `bin/PublshrApp`, and `bin/publshr` (CLI).

## Auth configuration

1. Supabase project `lboesdtsrqfvosznjpdy`
2. Redirect URL: `com.publshr.app://auth/callback`
3. Signup email template should include OTP: `{{ .Token }}` for in-app confirmation

Keys are in `Sources/PublshrApp/Services/SupabaseConfig.swift` (publishable key only — safe for clients).

## Layout (Cursor-style shell, Publshr modules)

| Region | Role |
|--------|------|
| Activity bar (48px) | **Chat**, **Spaces**, **Settings** |
| Main workspace | Full-width module (no fake Explorer / Welcome / code editor) |
| Status bar | App updates, chat connectivity, account |

**Chat** — enterprise team chat (Supabase realtime, channels, DMs, threads, files).  
**Spaces** — ClickUp-style spaces and kanban board (`spaces` + `tasks` tables).  
**Settings** — download/install updates, account, workspace, Touch ID, chat permissions.

The legacy Electron **Spaces** app under `desktop/spaces/` remains for advanced workflows; the mac app embeds the core Spaces experience natively.
