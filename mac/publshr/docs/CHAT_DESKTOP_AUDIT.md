# Chat desktop audit (Publshr.app)

Last reviewed: 2026-05-22. Native app only (`mac/publshr`) — not browser/Electron.

## Build status

- `swift build --product PublshrApp` — **passes**
- Supabase migrations required on project `lboesdtsrqfvosznjpdy` for full chat (see `ENTERPRISE_CHAT_SPACES.md`)

## What works today

| Area | Status | Notes |
|------|--------|--------|
| Channels, DMs, realtime messages | OK | Supabase + SQLite cache |
| Submenu (sidebar) | OK | Filter pills, organized/recents, sections |
| Threads, reactions, pins, files, voice | OK | Phases 2–3 |
| Pop-out window | OK | Isolated `ChatChannelSession` |
| Command palette (⌘K) | OK | Opens palette; Search item opens workspace search |
| Chat search (⌘⇧F) | **Improved** | Tabs, scope, live query, channels/people |
| Star / mute / mark read | **Added** | Row menu + Starred section |
| Permissions sheet | OK | `workspaces.settings.chat` |
| AI sheet | OK | Heuristic summaries (not LLM gateway) |
| Spaces module | OK | Separate submenu tree |
| Auto-update (`live`) | OK | Independent of local dev build |

## What was broken or weak (fixed this pass)

| Issue | Fix |
|-------|-----|
| Search sheet was minimal (button + flat list) | `ChatSearchSheet` — tabs, scope, debounced search, empty states |
| “Favorites” were auto top-8, not user control | **Starred** — persisted per workspace |
| Mute existed in DB, no UI | Row menu → mute/unmute via `notification_level` |
| Sidebar search confused with global search | Placeholder: “Filter conversations…” |
| No channel/people hits in search | Local channel name + profile matching |
| `favoriteChannels` removed without updating bar menu | Bar menu uses `starredChannels` |

## Still incomplete (enterprise backlog)

| Priority | Item |
|----------|------|
| High | @mention push notifications |
| High | Channel member invite/roles UI |
| High | Custom collapsible sidebar sections (Slack) |
| Medium | Search modifiers (`in:`, `from:`, `has:file`) |
| Medium | Section ⋯ menus (sort/filter/browse) |
| Medium | Read receipts UI |
| Medium | Group DM creation UI |
| Medium | Workspace switcher in chat |
| Low | True STT / LLM for AI + voice |

## How to test locally

```bash
cd mac/publshr
swift build --product PublshrApp
.build/debug/PublshrApp
```

Or install to `~/Applications/Publshr.app` via `bash scripts/package-release.sh` + `ditto`.

### Chat checklist

1. Sign in → Chat module → submenu shows Channels / DMs.
2. **Filter conversations** field narrows list only.
3. **⌘⇧F** → search sheet → type query → tabs filter results → open hit.
4. Row **⋯** → Star, Mute, Mark read, Search in channel / workspace.
5. Starred section appears after starring.
6. **Muted** filter pill shows muted channels only.
7. Pop-out (⌘⇧O) still independent of IDE selection.

## Submenu architecture (reference)

```
ChatSidebarView
├── Filter field (sidebarSearchQuery)     → list filter only
├── Pills: All | Unread | Starred | Muted | DMs | Channels
├── Starred / Channels / DMs sections
├── Planner share list
└── Footer: Organized | Recents | +
```

Global search: `ChatSearchSheet` + `ChatViewModel.runGlobalSearch()` (RPC + SQLite + local channel/people).

## Related docs

- `CHAT_SYSTEM.md` — phases & tables
- `CHAT_ENTERPRISE_GAPS.md` — roadmap
- `APP_SHELL.md` — shell layout
