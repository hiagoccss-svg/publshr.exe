# Fully live — nothing on your dev machine

Publshr enterprise runs from **GitHub** (apps) + **Supabase** (data). You do not need the repo cloned, `npm run dev`, or Xcode on your Mac for day-to-day use.

## One-line installs (macOS)

| Product | Command |
|---------|---------|
| **Publshr IDE** (Chat, Spaces, Settings) | `curl -fsSL "https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install-macos.sh" \| bash` |
| **Spaces** (boards, whiteboard canvas) | `curl -fsSL "https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install-desktop-spaces.sh" \| bash` |
| **Media Monitoring** (coverage, alerts, reports) | `curl -fsSL "https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install-desktop-media-monitoring.sh" \| bash` |

Apps install to `~/Applications` and auto-update from GitHub releases.

## Cloud backend (always on)

| Service | Project |
|---------|---------|
| Supabase | `lboesdtsrqfvosznjpdy` (`publshr.exe`) |
| Auth, Chat, Spaces, devices, subscriptions | Same project for mac IDE + desktop apps |
| Migrations | `supabase/migrations/` (applied on production) |

Verify from any machine:

```bash
bash mac/publshr/scripts/verify-all-connections.sh
```

## Update channels

| App | Release tag | When it updates |
|-----|-------------|-----------------|
| macOS IDE | `live` | Every push to `main` (~3–8 min) |
| Spaces | `spaces-production` (falls back to `spaces-staging`) | Push to `main` touching `desktop/` |
| Media Monitoring | `media-monitoring-production` (falls back to staging) | Same |
| Planner | `planner-production` | Same |

Install scripts try **production** first, then **staging**, so a single curl works even before the first production release exists.

Installed apps poll GitHub for new app bundles; Supabase syncs on sign-in and on the IDE’s 30s tick.

## What stays on your Mac (user data only)

Under `~/Library/Application Support/` — sessions, SQLite caches, preferences. **Never** deleted by updates.

## Optional: developers only

`npm run dev` is for UI work in Cursor, not for end users. Production users only need the curl installers above.
