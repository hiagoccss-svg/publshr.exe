# Chat UI — ClickUp enterprise layout

Publshr Chat follows the [ClickUp Chat Sidebar](https://help.clickup.com/hc/en-us/articles/33491596671255-What-is-the-Chat-Sidebar): search, filters, organized sections, unread badges, and Organized / Recents layout.

## Chat sidebar (submenu)

```
┌─────────────────────────────┐
│ 💬 Chat              [+]    │  New channel / New message
├─────────────────────────────┤
│ 🔍 Search channels…   [⌕]  │  Filter list + workspace search (⌘⇧F)
├─────────────────────────────┤
│ [All][Unread][DMs][Channels]│  ClickUp filter pills
├─────────────────────────────┤
│ FAVORITES                   │  Starred conversations (user-controlled)
│ CHANNELS              [+]   │
│ DIRECT MESSAGES       [+]   │
├─────────────────────────────┤
│ [≡ Organized] [🕐 Recents]  │  Footer layout toggle
└─────────────────────────────┘
```

### Filters (ClickUp)

| Filter | Behavior |
|--------|----------|
| **All** | Channels + DMs when Organized; all recents when Recents |
| **Unread** | Rows with unread messages or thread replies |
| **DMs** | Direct + group messages only |
| **Channels** | Workspace channels only |

Tap the active pill again (except All) to reset to **All**.

### Layouts

| Layout | Behavior |
|--------|----------|
| **Organized** | Favorites (if any) → Channels → Direct Messages |
| **Recents** | Single list sorted by `last_message_at` |

Keys: `publshr.chat.sidebarFilter`, `publshr.chat.sidebarLayout`, `publshr.chat.starred.<workspaceId>`.

### Row chrome

- **Bold** row + numeric badge = unread messages
- **Thread icon** = unread thread replies you follow
- **Star** = favorite (not the old auto top-8 list)
- **Bell slash** = muted (`notification_level` on Supabase)

## Conversation column

- Status bar: channel title, search, pin, ⋯ menu (no calls / AI)
- Composer: attach files + send (⌘↩) — no voice note recorder
- Threads, reactions, pins, files remain

## Removed (focus on ClickUp chat)

- Voice / video calls (`CallSignalingService`, LiveKit)
- AI assistant sheet and heuristics (`ChatAIService`)
- Voice note recording (playback of old voice attachments still works)
- Planner block in chat sidebar (planner stays in its own module)

## Keyboard shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘\\ | Toggle chat submenu |
| ⌘⇧F | Workspace search |
| ⌘⇧O | Pop out channel |
| ⌘↩ | Send message |

## Swift sources

| File | Role |
|------|------|
| `Chat/Views/ChatSidebarView.swift` | ClickUp submenu |
| `Chat/Utilities/ChatClickUpDesign.swift` | Tokens + filter enums |
| `Chat/Views/ChatSearchSheet.swift` | Workspace search |
| `Chat/ViewModels/ChatViewModel.swift` | Filters, favorites, mute |
