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

## Supabase

Apply `supabase/migrations/20250521000000_media_monitoring.sql` to your project. Configure env in renderer when enabling cloud sync (Phase 2).

## Roadmap

| Phase | Features |
|-------|----------|
| 2 | Article detail, screenshots, filtering, saved coverage, realtime Supabase sync |
| 3 | Sentiment, media/PR value tuning, duplicates, relevance |
| 4 | Reports, exports, competitor tracking, AI summaries |
| 5 | Advanced AI insights, trends, predictive alerts |
