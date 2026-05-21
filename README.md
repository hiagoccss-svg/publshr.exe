# publshr

Enterprise desktop publisher — **Supabase** backend, native macOS apps.

## macOS — Supabase app (v0.3, recommended)

Light **Cursor-style 3-column** UI · **ClickUp-style Chat & Spaces** · live data on Supabase.

```bash
cd ~/publshr.exe
git pull
./install-mac-app.sh
```

| Column 1 | Column 2 | Column 3 |
|----------|------------|----------|
| Spaces | Channels or Tasks | Chat or project tasks |

**Top bar:** workspace, Chat/Projects, New Channel / Space / Task, search, account.  
**Auth:** email + password · optional **Touch ID** unlock.  
**Backend:** [supabase/README.md](supabase/README.md) (`publshr.exe` project).

## macOS — IDE app (`mac/publshr`)

Cursor-matched IDE with Supabase auth (from `main`):

```bash
./install-publshr.sh
# or: ./install.sh && open /Applications/Publshr.app
```

Features: activity bar, sidebar, editor, chat panel, OTP sign-in, `public.profiles` sync.

## macOS — App Space (local JSON, `native/publshr`)

ClickUp-style board/list/calendar using local `app-space.json` (also under `native/publshr` on `main`). Build with `./install-mac-app.sh` when using the merged branch that includes `AppSpace/` sources.

## Planner (communications OS)

Electron desktop module for PR, media, and editorial teams — timeline, board, calendar, editor windows, Supabase + SQLite local-first sync.

```bash
cd planner/desktop && npm install && npm run dev
```

See [planner/README.md](planner/README.md).

## Linux / CLI

```bash
chmod +x install-local.sh
./install-local.sh
export PATH="$(pwd)/.local/bin:$PATH"
publshr --version
```

## Project layout

```
native/publshr/   # Supabase Mac app + App Space + CLI
mac/publshr/      # IDE + auth (Cursor-style)
planner/desktop/  # Communications Planner (Electron + React)
windows/          # publshr.exe releases
AGENTS.md         # Cloud agent notes
```

Windows: [Releases](https://github.com/hiagoccss-svg/publshr.exe/releases).
