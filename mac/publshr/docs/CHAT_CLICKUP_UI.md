# Chat UI — ClickUp enterprise layout

Publshr Chat follows [ClickUp Chat Sidebar](https://help.clickup.com/hc/en-us/articles/33491596671255-What-is-the-Chat-Sidebar) and [ClickUp 4.0](https://help.clickup.com/hc/en-us/articles/31142608907543-Intro-to-ClickUp-4-0) patterns: converged navigation, filters, organized sections, bottom layout controls, settings submenu, and per-channel notification controls.

## Global navigation (where icons go)

| Zone | Width | Contents |
|------|-------|----------|
| **Bar menu** (far left) | ~19.5% window (min 248px) · collapsed = traffic lights + toggle | **Chat** · **Spaces** (real app modules only) |
| **Bar menu** | 200pt expanded / ~56–96pt icon rail · glass tint | Chat, Spaces, profile |
| **Universal submenu** | 272pt fixed · **#FFFFFF** | Search in unified titlebar row (Chat + Spaces); filters, lists, footer (flat, no boxed chrome) |
| **Main column** | ~50% remainder · **#FFFFFF** | Titlebar: 32×32 icon slots, 8pt gaps, aligned with columns 1–2 |
| **Thread panel** (optional) | ~320px | Right-side thread replies |
| **Unified titlebar** | full width | Traffic lights row: sidebar, back/forward, submenu search, channel title + actions |
| **Bar menu profile** | bottom of rail | Avatar opens profile sheet (photo, status, sign out) |

Settings opens in a **separate sheet/window** (not in the activity strip), matching a focused IDE shell.

## Chat sidebar structure

```
┌─────────────────────────────┐
│ 🔍 Search channels…         │  ← Titlebar row (`ChatSidebarTitlebarChrome`)
├─────────────────────────────┤
│ [All][Unread][Pinned][DMs][Ch] │  ← Filters (tap again to clear)
├─────────────────────────────┤
│ CHANNELS              [+]   │  ← Organized layout
│   ○ general            (3)  │
│ DIRECT MESSAGES       [+]   │
│ PLANNER                     │
├─────────────────────────────┤
│ Organized · Recents    [+][⚙️] │  ← Bottom: layout toggles, new, settings
│ Create channel              │  ← Flat footer rows (`LibrarySubmenuTextButtonStyle`)
│ New message                 │
└─────────────────────────────┘
```

### Filters

| Filter | Behavior |
|--------|----------|
| **All** | Channels + DMs (organized) or full recents list |
| **Unread** | Rows with message unread count or thread unread |
| **@** | Channels/DMs with unread @you / @here / @channel |
| **Pinned** | User-pinned channels/DMs only |
| **DMs** | Direct + group messages only |
| **Channels** | Workspace channels only |

### Hubs (above channel list)

| Hub | Behavior |
|-----|----------|
| **Channels** | Default organized/recents lists |
| **Activity** | In-app notification feed (mentions + messages) |
| **Drafts** | Unsent composer drafts (SQLite) |
| **Sent** | Your recent messages + pending scheduled sends |

### Layouts (bottom-left, ClickUp)

| Layout | Icon | Behavior |
|--------|------|----------|
| **Organized** | `list.bullet.rectangle` | Sections: Pinned, Channels, Direct Messages, Planner |
| **Recents** | `clock` | Single list sorted by `last_message_at` |

Active layout label appears next to the toggles. Preference keys: `publshr.chat.sidebarFilter`, `publshr.chat.sidebarLayout`.

### Bottom settings menu (gear, lower-right)

| Item | Action |
|------|--------|
| Notification settings | Default All / Mentions / Mute + per-channel overrides |
| Mark all as read | Clears unread badges workspace-wide |
| Search workspace | Opens search sheet |
| Focus on chat | Hides sidebars |
| New channel / message | When permitted |
| Workspace chat permissions | Admin toggles |

## Conversation column

- **Unified titlebar (chat)** — channel title, pop-out, focus, AI, search, pinned, DM details (DM/group), notifications, command palette, settings (`ChatEditorToolbarContent`).
- **Composer toolbar** — @mention picker, emoji, attach, voice, schedule send, channel label.
- **DM inspector** — right panel for DM/group members, notifications, copy link.
- **Composer** — `Message {channel}…`, send (⌘↩).
- **Unread** — bold sidebar row; numeric badge; thread icon for unread thread replies.

## Channel row submenu (⋯)

Shared via `ChatChannelActionsMenu`: Open, pop-out, pin/unpin, mark read, mute, search, pinned panel, channel settings, workspace permissions.

## Notification settings (ClickUp-style)

Per [Notification settings](https://help.clickup.com/hc/en-us/articles/6325918957335-Notification-settings):

- **Default for new channels** — `all` | `mentions` | `muted` (UserDefaults `publshr.chat.defaultNotificationLevel`)
- **Current channel** — quick All / Mentions / Mute (updates `chat_channel_members.notification_level`)
- **Mark all conversations read**

## Keyboard shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘\\ | Toggle chat sidebar (ClickUp `Cmd + \`) |
| ⌘⇧F | Workspace chat search |
| ⌘⇧O | Pop out channel |
| ⌘↩ | Send message |

## Performance

- Sidebar uses `LazyVStack` inside `ScrollView` for large channel lists.
- Filter/search run on in-memory channel arrays (no per-keystroke network).
- Realtime + SQLite cache unchanged (`ChatLocalStore`).

## Swift sources

| File | Role |
|------|------|
| `Chat/Utilities/ChatClickUpDesign.swift` | Layout tokens, filter/layout enums |
| `Chat/Views/ChatSidebarTitlebarChrome.swift` | Search in submenu titlebar row |
| `Chat/Views/ChatSidebarView.swift` | Filters, sections, flat footer + settings gear |
| `Views/Titlebar/ShellUnifiedTitlebar.swift` | Full-width titlebar (traffic-light alignment) |
| `Views/Titlebar/TrafficLightLayoutStore.swift` | Measures system close/minimize/zoom geometry |
| `Views/Titlebar/ChatEditorHeaderBar.swift` | `ChatEditorToolbarContent` for chat column |
| `Theme/AppWindowChrome.swift` | `TitlebarToolbarRow` / `TitlebarToolbarSlot` alignment |
| `Chat/Views/ChatNotificationSettingsSheet.swift` | Notification defaults sheet |
| `Chat/Models/ChatInAppNotification.swift` | In-app notification feed items |
| `Chat/Services/ChatNotificationService.swift` | macOS Notification Center delivery |
| `Chat/Views/ChatComposerView.swift` | Composer toolbar |
| `Chat/Views/ChatEnterpriseUI.swift` | Typing indicator + `typingSummary` |
| `Chat/Views/ChatSidebarHubViews.swift` | Activity / Drafts / Sent hubs |
| `Chat/Views/ChatDMInspectorPanel.swift` | DM/group details panel |
| `Chat/Views/ChatMentionPickerSheet.swift` | Mention picker |
| `Chat/Views/ChatScheduleSendSheet.swift` | Schedule send |
| `Chat/Views/ChatChannelActionsMenu.swift` | Row + toolbar actions |
| `Views/Library/LibraryBarMenuIconRail.swift` | Module icons + profile avatar footer |
| `Theme/WorkspaceShellBackground.swift` | `GlassSubmenuChrome`, primary bar transparency |
| `Theme/LibrarySubmenuButtonStyle.swift` | Flat footer actions (no pill boxes) |
| `Chat/Views/ChatWorkspaceChannelTabs.swift` | Open channel tab strip |
| `Chat/ViewModels/ChatViewModel.swift` | Filters, layout, unread, notifications |
| `Views/ActivityBarView.swift` | Module icons + chat badge |

## Deploy

Every push to `main` publishes the macOS `live` build. Merge PR → install or auto-update → Chat UI ships in `Publshr.app`.
