# Enterprise apps — naming, surfaces, and live data

## Product names (canonical)

| Product | Display name | Bundle ID | Repo path |
|---------|--------------|-----------|-----------|
| macOS IDE | **Publshr** | `com.publshr.app` | `mac/publshr` |
| Spaces | **Publshr Spaces** | `com.publshr.spaces` | `desktop/spaces` |
| Media Monitoring | **Publshr Media Monitoring** | `com.publshr.media-monitoring` | `desktop/media-monitoring` |
| Planner | **Publshr Planner** | `com.publshr.planner` | `planner/desktop` |

Source of truth: `shared/enterprise/products.ts` and `DesktopCompanionAppLauncher.swift`.

## Live vs local cache

| Layer | Behavior |
|-------|----------|
| **Auth, chat, spaces data** | Supabase Postgres + Realtime (required for production) |
| **SQLite cache** | Performance and brief disconnects only — not a demo/offline product mode |
| **Electron without Supabase env** | Local SQLite only (dev); installed enterprise builds must ship with Supabase configured |
| **Publication seed (Media Monitoring)** | Skipped when `SUPABASE_URL` / `VITE_SUPABASE_URL` is set |

## Surface parity (macOS IDE vs Electron)

| Feature | Electron (`desktop/spaces`) | macOS IDE (`Publshr.app`) |
|---------|----------------------------|---------------------------|
| Operations sidebar (Dashboard, Documents, …) | Yes | Yes (`SpacesNavSidebar` + `SpacesEnterpriseSectionsView`) |
| Space hierarchy + task views | Yes | Yes |
| Whiteboard canvas (tldraw) | Yes | List + metadata; canvas via Spaces app or Phase 2 embed |
| Chat | Full app | Full native module |
| Media Monitoring | Full app | Native shell + open **Publshr Media Monitoring** |
| Planner | Full app | Chat integration + open **Publshr Planner** |

## Verify live stack

```bash
bash mac/publshr/scripts/verify-enterprise.sh
bash mac/publshr/scripts/verify-all-connections.sh
```

Apply migrations through `20260523120000_spaces_approvals.sql` before relying on Approvals in production.
