# Enterprise Chat System

Real-time workspace communication integrated into the Publshr macOS IDE.

## Phase 1

- Channels, DMs, realtime messages, presence, macOS Notification Center alerts (live Supabase inserts), in-app notification feed, SQLite cache

## Phase 2

- **File uploads** — `workspace-files` bucket + `files` table; drag/drop and paperclip
- **Reactions** — `chat_reactions` with quick emoji picker and realtime sync
- **Pinned messages** — `chat_pinned_items` panel per channel
- **Edit / delete** — soft delete; edit with indicator
- **@mentions** — highlighted in composer; parser for @user / @here / @channel
- **Threading** — `thread_parent_id`; side thread panel with reply count

## Phase 3

- **Voice notes** — `AVAudioRecorder`, inline composer bar (no sheet), waveform preview, upload + `chat_voice_transcripts`
- **Incoming message popup** — `ChatIncomingMessagePopupManager` (Teams-style); prefs in Notification settings
- **Multi-window** — `ChatWindowManager` pops channel into `NSWindow`
- **Permissions UI** — workspace `settings.chat` toggles (local + model)
- **Planner integration** — share `tasks` into chat with link preview cards

## Phase 4

- **AI assistant** — local summarization, reply suggestions, action items (`ChatAIService`; swap for AI SDK later)
- **Period script recap** — pick start/end dates; detailed who-said-what script (`ChatPeriodSummaryBuilder`, `ChatAISheet`)
- **Transcription-ready** — `chat_voice_transcripts` with `pending` → `ready` pipeline
- **Search** — `search_workspace` RPC + local SQLite `search_index`
- **Automations** — deadline / action-item extraction from AI heuristics

## Supabase tables

| Table | Phase |
|-------|-------|
| `chat_channels`, `chat_messages`, `chat_presence`, `chat_channel_members` | 1 |
| `chat_reactions`, `chat_pinned_items`, `chat_read_receipts`, `chat_message_links` | 2 |
| `chat_voice_transcripts` | 3–4 |

Migrations:

- `supabase/migrations/20260521180000_chat_presence_and_members.sql`
- `supabase/migrations/20260521200000_chat_phases_2_4.sql`

## Architecture

```
EnterpriseChatView
├── ChatSidebarView
├── ChatConversationView
│   ├── ChatThreadPanelView (Phase 2)
│   ├── ChatPinnedPanelView
│   └── ChatMessageBubbleView + reactions + links + voice
├── ChatSearchSheet (Phase 4)
├── ChatAISheet (Phase 4)
├── ChatPermissionsSheet (Phase 3)
└── ChatVoiceRecorderSheet (Phase 3)

ChatViewModel + ChatViewModel+Phases
ChatService + ChatService+Phases
ChatLocalStore (SQLite + search index)
ChatWindowManager (pop-out windows)
ChatAIService (summaries / suggestions)
ChatVoiceRecorder (microphone)
```

## Keyboard shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘⇧F | Chat search |
| ⌘⇧O | Pop out channel window |
