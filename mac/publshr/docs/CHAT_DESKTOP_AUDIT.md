# Chat desktop audit (Publshr.app)

Last updated: 2026-05-22. Native macOS app (`mac/publshr`).

## Build

`swift build --product PublshrApp` — passes without LiveKit.

## Product focus

**ClickUp-style team chat** — sidebar, channels, DMs, threads, search, files. No calls, no AI assistant, no voice-note recording in this build.

## What works

| Area | Status |
|------|--------|
| ClickUp submenu | Header, search, All/Unread/DMs/Channels, Favorites, Organized/Recents |
| Workspace search | Tabs, scope, ⌘⇧F |
| Star / mute / mark read | Channel ⋯ menu + Favorites section |
| Threads, reactions, pins, file attach | Yes |
| Pop-out channel | Yes |
| Supabase realtime + cache | Yes |

## Removed in this pass

| Feature | Notes |
|---------|--------|
| Voice & video calls | `CallSignalingService`, LiveKit dependency, call UI |
| AI assistant | `ChatAIService`, `ChatAISheet`, sparkles / Ask AI buttons |
| Voice note recording | Mic removed; existing voice messages still play back |
| Planner list in chat sidebar | Planner module unchanged |

## Test locally

```bash
cd mac/publshr && swift build --product PublshrApp && .build/debug/PublshrApp
```

1. Chat submenu matches ClickUp sections and filters.
2. Star a channel → appears under **Favorites**.
3. ⌘⇧F → search messages/channels/people.
4. No phone/video/sparkles buttons in chat chrome.

## Reference

[ClickUp Chat Sidebar help](https://help.clickup.com/hc/en-us/articles/33491596671255-What-is-the-Chat-Sidebar)
