# Enterprise chat — gaps & roadmap

What is **implemented** vs what still needs work for production-grade enterprise use.

## ✅ Working now

| Area | Status |
|------|--------|
| Channels, DMs, groups | Supabase + local cache |
| Dedicated pop-out window | Borderless, resizable, custom close — **main app stays open** |
| Double-click / context menu | Open channel in new window |
| Isolated window state | `ChatChannelSession` (does not change IDE selection) |
| Realtime inserts | Messages, presence, reactions |
| Realtime edits/deletes | `subscribeMessageUpdates` |
| Typing indicators | Realtime broadcast per channel |
| Notification click | Opens dedicated window for that channel |
| Permissions UI | Saved to `workspaces.settings.chat` in Supabase |
| Threads, reactions, files, voice, AI, search | Phases 2–4 |

## Pop-out window (Slack-style)

- **No macOS title bar** — `ChatFloatingWindow` uses `.borderless` + `.resizable`
- **Custom close** — top-right X (Escape also closes)
- **Draggable** — `isMovableByWindowBackground`
- **Opens focused** on selected channel or DM
- **IDE panel unchanged** — separate `ChatChannelSession` per window

Shortcuts: **⌘⇧O** or Chat menu → “Pop Out Channel”

## 🔶 Still missing / partial (prioritize next)

### High priority

1. **Mention push notifications** — detect `@user` and notify mentioned users (not only generic message toast).
2. **Channel member management UI** — invite, remove, roles; guest/client mode enforcement in queries.
3. **End-to-end file upload from pop-out** — session composer file/voice upload (currently IDE panel only for files).
4. **Image inline preview** — render image attachments in thread, not only filename.
5. **Workspace switcher** — multiple workspaces per account.
6. **Audit log writes** — message delete/edit → `audit_logs` table.
7. **Message retention / export** — admin policies + export job.

### Medium priority

8. **Quick reply from notification** — macOS notification actions.
9. **Dock badge** — unread total on app icon (`NSApp.dockTile`).
10. **Focus Mode** — notification interruption levels (macOS 12+).
11. **Read receipt UI** — “Seen by …” list when enabled.
12. **Channel notification prefs** — per-channel mute/keywords (DB: `chat_channel_members.notification_level` — UI incomplete).
13. **True speech-to-text** — replace `ChatAIService.mockTranscribeVoice` with Whisper / cloud STT.
14. **AI via gateway** — replace heuristics with Vercel AI SDK / your LLM.
15. **Client-safe channel filtering** — hide internal channels for guest role at query level.
16. **Group DM creation UI** — `kind = group` with multi-select members.
17. **Announcement / read-only channels** — block non-admin posts in UI when `visibility = announcement`.

### Lower priority

18. **Multi-monitor window persistence** — remember frame per channel.
19. **Electron/Windows parity** — port `ChatWindowManager` to Win32 borderless window.
20. **E2E encryption** — optional enterprise tier.
21. **Compliance exports** — legal hold, CSV/PDF export.
22. **Workflow automations** — planner → auto-post rules (edge functions).

## Operational checklist before launch

- [ ] Apply both Supabase migrations on production
- [ ] Storage RLS for `workspace-files` upload path
- [ ] Enable Realtime on all chat tables
- [ ] Test pop-out: double-click DM, send message, close window, IDE still on same channel
- [ ] Test notification click opens correct DM window
- [ ] Test edit/delete syncs in pop-out and IDE within 2s
- [ ] Load test: 50+ channels, search performance
- [ ] macOS microphone privacy string in `Info.plist` (`NSMicrophoneUsageDescription`)

## Architecture note

```
Main app: ChatViewModel (IDE panel)
Pop-out:  ChatChannelSession per window (isolated)
Both:     ChatService (Supabase) + ChatWindowManager.route*
```

Do **not** share one `selectedChannel` between IDE and pop-out — that was the main bug fixed in this pass.
