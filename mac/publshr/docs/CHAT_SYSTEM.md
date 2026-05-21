# Enterprise Chat System

Real-time workspace communication integrated into the Publshr macOS IDE.

## Phase 1 (implemented)

- **Channels** — public/private workspace channels with default seeds (`#editorial`, `#approvals`, `#campaign-launch`)
- **Direct messages** — 1:1 DMs via `chat_channels.kind = dm` + `chat_channel_members`
- **Realtime messages** — Supabase Realtime on `chat_messages`
- **Online status** — `chat_presence` with heartbeat (online, away, busy, in meeting, offline, invisible)
- **Desktop notifications** — macOS Notification Center for messages in non-active channels
- **SQLite local cache** — `~/Library/Application Support/Publshr/chat-cache.sqlite` for channels, messages, drafts, unread, presence

## Supabase tables

| Table | Purpose |
|-------|---------|
| `chat_channels` | Channels, DMs, groups, threads |
| `chat_messages` | Message bodies, threads, attachments JSON |
| `chat_channel_members` | Membership, notification level, last read |
| `chat_presence` | Per-workspace user status |

Migration: `supabase/migrations/20260521180000_chat_presence_and_members.sql`

## Architecture

```
EnterpriseChatView
├── ChatSidebarView (DMs, channels, search, unread)
└── ChatConversationView
    ├── ChatMessageBubbleView
    └── ChatComposerView

ChatViewModel ←→ ChatService (Supabase + Realtime)
              ←→ ChatLocalStore (SQLite)
              ←→ ChatNotificationService (UNUserNotificationCenter)
```

## MVP roadmap

| Phase | Features |
|-------|----------|
| **2** | File uploads, reactions, pins, edit/delete, @mentions, threading |
| **3** | Voice notes, multi-window chat, advanced permissions, planner hooks |
| **4** | AI summaries, transcription, advanced search, automations |

## Permissions (workspace `settings.chat`)

Defaults are permissive; override in `workspaces.settings` JSON:

```json
{
  "chat": {
    "can_create_channels": true,
    "can_dm": true,
    "can_use_voice_notes": true,
    "read_receipts_enabled": false
  }
}
```

## Client-safe mode

Use `chat_channels.visibility = client_safe` for client-visible channels. Internal channels use `internal` or `private`.
