# Repo and environment cleanup

Use this when tidying GitHub, your Mac install, and verifying Supabase + live updates.

## GitHub branches

Agent and feature work creates many `cursor/*` branches. After PRs merge, delete stale remotes:

```bash
cd mac/publshr
# Preview
DRY_RUN=1 bash scripts/cleanup-github-branches.sh
# Delete (keeps branches tied to open PRs)
bash scripts/cleanup-github-branches.sh
git fetch --prune origin
```

**Do not delete** branches that still have open pull requests. The script skips those automatically.

## GitHub live channel (installed app updates)

Every push to `main` publishes the **`live`** release (`Publshr-macos-aarch64.tar.gz`, `Publshr-Install-macos.zip`, `VERSION.txt`).

Verify from any machine:

```bash
cd mac/publshr
bash scripts/verify-github-live.sh
```

Repo default: `hiagoccss-svg/publshr.exe` (see `AppReleaseConfig.defaultRepo`).

## Supabase (Chat, Spaces, auth)

Project: `lboesdtsrqfvosznjpdy` — URL and publishable key in `Sources/PublshrApp/Services/SupabaseConfig.swift`.

Apply new SQL from `supabase/migrations/` (repo root) via Supabase CLI or dashboard, then:

```bash
cd mac/publshr
bash scripts/verify-auth.sh
bash scripts/verify-chat-spaces.sh
# Or all at once:
bash scripts/verify-all-connections.sh
```

Canonical migrations live under `/supabase/migrations/` at the repo root. `mac/publshr/supabase/migrations/` may point to those files for documentation.

## Mac local cleanup (safe to remove)

These are **not** in git; remove on your Mac if installs got messy:

| Path | What it is |
|------|------------|
| `~/Applications/Publshr.app` | Installed app (reinstall from `live` zip or `install-macos.sh`) |
| `~/Library/Application Support/Publshr` | Local cache/SQLite (optional; sign in again after wipe) |
| `~/Library/Caches` entries for Publshr | Build/update cache |
| Old downloads | `Publshr-Install-macos.zip` copies in Downloads — use [live release](https://github.com/hiagoccss-svg/publshr.exe/releases/download/live/Publshr-Install-macos.zip) only |

Reinstall (one line):

```bash
curl -fsSL "https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install-macos.sh" | bash
```

Settings → **Sync now** refreshes GitHub `live` + Supabase after reinstall.

## Repo artifacts (do not commit)

- `mac/publshr/.build/`, `mac/publshr/dist/` — Swift build output (gitignored)
- `install/macos/Publshr-Install-macos.zip` — **removed from git**; CI builds the real zip to the `live` release only
- `actionlint` binary at repo root — local tool, gitignored

## Open PRs (as of cleanup run)

Leave these branches until merged or closed:

- `cursor/fix-shell-vertical-collapse-bf12`
- `cursor/mac-logo-chat-ui-af14`
- `cursor/fix-regressions-chat-spaces-icon-7abf`
- `cursor/fix-minimize-restore-392f` (draft)
- `cursor/fix-auto-update-enterprise-dfbc` (draft)
