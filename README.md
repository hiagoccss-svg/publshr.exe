# publshr

A native macOS IDE styled like **Cursor**, with **Supabase** account creation, email confirmation, and profile sync.

| Platform | Install |
|----------|---------|
| macOS | `curl -fsSL …/install-publshr.sh \| bash` → **Publshr.app** in Applications |
| Linux | `./install.sh` → CLI at `/usr/local/bin/publshr` |

## Features

- **Cursor-matched UI** — activity bar, sidebar, editor tabs, AI chat panel, status bar (`#181818` / `#252526` / `#1e1e1e` palette)
- **Supabase Auth** — sign up, sign in, 6-digit email OTP confirmation, session persistence
- **Profile auto-create** — `handle_new_user` trigger writes to `public.profiles` on signup

## Quick install (macOS)

```bash
curl -fsSL https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/cursor/cursor-mac-supabase-auth-8b60/install-publshr.sh | bash
```

Then open **Finder → Applications → Publshr**.

## Account creation flow

1. **Create account** — email, name, password (min 8 chars)
2. **Confirm email** — enter the 6-digit code from Supabase (enable `{{ .Token }}` in your [email template](https://supabase.com/dashboard/project/lboesdtsrqfvosznjpdy/auth/templates))
3. **Sign in** — access the IDE; profile loads from `profiles`

### Supabase project

- Project: `publshr.exe` (`lboesdtsrqfvosznjpdy`)
- URL: `https://lboesdtsrqfvosznjpdy.supabase.co`
- Add redirect URL: `com.publshr.app://auth/callback` in [Auth URL configuration](https://supabase.com/dashboard/project/lboesdtsrqfvosznjpdy/auth/url-configuration)

## Build from source (macOS)

```bash
cd mac/publshr
swift build -c release --product PublshrApp
./scripts/build-macos-app.sh .build/release/PublshrApp 0.2.0 .
open Publshr.app
```

## Verify auth (API)

```bash
./scripts/verify-auth.sh
```

Swift package: [`mac/publshr`](mac/publshr)
