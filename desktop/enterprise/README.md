# Publshr Enterprise (Tauri)

Native desktop platform shell for Publshr — **install once**, auto-update via GitHub Releases, local-first SQLite, Supabase sync.

## Quick start

```bash
npm install
cp .env.example .env   # optional
npm run dev
```

## Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Tauri dev window + Vite HMR |
| `npm run typecheck` | TypeScript check |
| `npm run dist` | Production installer bundle |

## Architecture

See [DESKTOP_TAURI_PLATFORM.md](../../mac/publshr/docs/DESKTOP_TAURI_PLATFORM.md).
