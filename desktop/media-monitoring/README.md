# Publshr Media Monitoring

Enterprise desktop media intelligence and coverage monitoring for communications teams, PR agencies, and brands.

## Stack

- **Electron** — desktop shell, multi-window, native notifications
- **React + TypeScript + Tailwind** — UI matching Publshr Planner/Editor aesthetic
- **SQLite** (`better-sqlite3`) — local-first cache, offline viewing
- **Supabase** — cloud schema and sync (migrations in `supabase/migrations/`)

## Phase 1 (MVP)

- Desktop module shell (top bar, sidebar, workspace, context panel)
- Monitor profile creation (side panel, boolean keywords, regions, languages)
- Progressive live article feed from approved publications only
- Publication database (15 seeded verified sources)
- SQLite local cache

## Quick start

```bash
cd desktop/media-monitoring
npm install
npm run dev
```

## Build

```bash
npm run build
```

## Architecture

```
electron/main/     Main process — SQLite, monitoring engine, IPC
electron/preload/  Secure bridge to renderer
src/               React UI
supabase/          Cloud migrations
```

### Monitoring engine

When a profile is started, articles stream in progressively (400–800ms intervals) from the **approved publication database** only — not random web search. Media value uses publication authority and traffic estimates.

### Local database

Stored at `{userData}/media-monitoring.db` with tables: `publication_sources`, `monitor_profiles`, `monitor_results`, `saved_coverage`, `monitoring_sessions`.

## Supabase sync

Schema is deployed to the **publshr.exe** Supabase project (`lboesdtsrqfvosznjpdy`). Tables:

- `publication_sources` (15 verified outlets seeded)
- `monitor_profiles`, `monitor_results`, `saved_coverage`
- `coverage_comments`, `coverage_activity`

**Sign in** with your Publshr email/password. On login the app:

1. Creates or loads your workspace
2. Pulls publications and monitors from Supabase → SQLite
3. Pushes new monitors, live results, and saved coverage to the cloud
4. Subscribes to realtime `monitor_results` inserts

Verify cloud connectivity:

```bash
node scripts/verify-supabase.mjs
# With auth:
node scripts/verify-supabase.mjs you@example.com your-password
```

Optional env (see `.env.example`): `SUPABASE_URL`, `SUPABASE_ANON_KEY`

## Roadmap

| Phase | Features |
|-------|----------|
| 2 | Article detail, screenshots, filtering, saved coverage, realtime Supabase sync |
| 3 | Sentiment, media/PR value tuning, duplicates, relevance |
| 4 | Reports, exports, competitor tracking, AI summaries |
| 5 | Advanced AI insights, trends, predictive alerts |
