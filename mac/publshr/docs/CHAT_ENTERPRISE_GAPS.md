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
| Realtime edits/deletes | `subscribeMessageUpdates` (wired to IDE + pop-out) |
| Typing indicators | IDE + pop-out via `ChatTypingBroadcaster` |
| Notification click | Opens dedicated window for that channel |
| Permissions UI | Persisted to `workspaces.settings.chat` via Supabase PATCH |
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

1. ~~**Mention push notifications**~~ — realtime delivers macOS alerts for `@user` / `@here` / `@channel` when notification level allows; server-side push to offline devices still TODO.
2. ~~**Channel member management UI**~~ — `ChatChannelSettingsSheet`: invite, remove, leave, notification level; workspace admin override. Guest/client query filtering still TODO.
3. ~~**End-to-end file upload from pop-out**~~ — implemented on `ChatChannelSession.uploadFile`.
4. ~~**Image inline preview**~~ — `ChatMessageBubbleView` renders image attachments.
5. **Workspace switcher** — multiple workspaces per account.
6. **Audit log writes** — message delete/edit → `audit_logs` table.
7. **Message retention / export** — admin policies + export job.

### Medium priority

8. ~~**Quick reply from notification**~~ — `UNTextInputNotificationAction` on all chat categories; routes to `sendQuickReply`.
9. ~~**Dock badge**~~ — unread total on dock + bar menu badge (`ChatNotificationService` + `LibraryBarMenuColumn`).
10. **Focus Mode** — notification interruption levels (macOS 12+).
11. ~~**Read receipt UI**~~ — “Seen by …” under own messages when `read_receipts_enabled`.
12. ~~**Channel notification prefs**~~ — per-channel All/Mentions/Mute in settings sheet + DM inspector.
13. **True speech-to-text** — replace `ChatAIService.mockTranscribeVoice` with Whisper / cloud STT.
14. **AI via gateway** — replace heuristics with Vercel AI SDK / your LLM.
15. **Client-safe channel filtering** — hide internal channels for guest role at query level.
16. ~~**Group DM creation UI**~~ — New Message sheet: Direct / Group segment + multi-select; DM inspector for existing groups.
17. ~~**Announcement / read-only channels**~~ — composer uses `canPost(in:)` (admin-only posting).

### Recently shipped (mac IDE)

- **ClickUp parity** — Activity/Drafts/Sent hubs, schedule send, mentions filter, DM inspector (`#82`).
- **Period script recap** — date-range channel recap in AI sheet (`#84` / `#90`).
- **@mention autocomplete** — inline composer picker + sheet (`openMentionPicker`).
- **Channel-scoped search** — `openChannelSearch()` vs workspace search; in-memory channel filter.
- **Pinned panel** — preview + jump to message.
- **Chat export** — transcript `.txt` when `can_export_chats`.
- **AI follow-ups → Planner** — “Add to Planner” on recap action items.
- **Scheduled send** — composer schedule sheet (ClickUp parity on `main`).

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
