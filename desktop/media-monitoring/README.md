# Publshr Media Monitoring

Enterprise desktop media intelligence and coverage monitoring for communications teams, PR agencies, and brands.

## Quick start (ready to run)

```bash
cd desktop/media-monitoring
npm install
npm run dev          # development with hot reload
# OR
npm run build && npm run start   # production build
# OR from repo root:
make media-monitoring-dev
make media-monitoring-start
```

The app opens immediately in **local enterprise mode** — no sign-in required. Create a monitor, start live tracking, save coverage, filter results, and export-ready metadata all work offline on SQLite.

**Connect cloud** (optional): click **Sign in** or **Connect cloud** to sync with Supabase (same account as Publshr macOS IDE).

## Verify installation

```bash
npm run smoke          # SQLite schema + seed test
npm run build          # compile main + renderer
npm run typecheck      # TypeScript
```

## Stack

| Layer | Technology |
|-------|------------|
| Desktop | Electron 34 |
| UI | React 18, TypeScript, Tailwind |
| Local cache | SQLite (`better-sqlite3`) |
| Cloud | Supabase (`publshr.exe` project) |

## Enterprise features (working)

- **Live monitoring** — progressive article feed from 15+ approved publications
- **Monitor profiles** — boolean keywords, exclusions, regions, languages
- **Media value / PR value** — authority + traffic based (not random)
- **Saved coverage** — notes, tags, sentiment override
- **Dashboard** — monitors, articles, PR totals
- **Coverage library** — saved articles view
- **Publication database** — verified sources only
- **Filters** — sentiment, sort, saved-only, search
- **Article detail** — full panel + external URL
- **Native notifications** — new coverage alerts
- **Cloud sync** — monitors, results, saved coverage (when signed in)
- **Realtime** — remote inserts via Supabase Realtime

## Supabase

Schema deployed on project `lboesdtsrqfvosznjpdy`. Tables: `publication_sources`, `monitor_profiles`, `monitor_results`, `saved_coverage`, `coverage_activity`.

```bash
npm run verify:cloud you@email.com your-password
```

Env (optional): copy `.env.example` → set `SUPABASE_URL`, `SUPABASE_ANON_KEY`.

## Package for distribution

```bash
npm run dist    # electron-builder → release/
```

## Architecture

```
electron/main/     SQLite, monitoring engine, Supabase sync, IPC
electron/preload/  Secure window.publshr API
src/               React UI
```
