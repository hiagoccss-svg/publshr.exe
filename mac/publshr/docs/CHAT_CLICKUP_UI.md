# Chat UI — ClickUp enterprise layout

Publshr Chat follows [ClickUp Chat Sidebar](https://help.clickup.com/hc/en-us/articles/33491596671255-What-is-the-Chat-Sidebar) patterns: left navigation, filters, organized sections, unread badges, and a converged workspace shell.

## Global navigation (where icons go)

| Zone | Width | Contents |
|------|-------|----------|
| **Bar menu** (far left) | 200px | **Chat** · **Spaces** (real app modules only) |
| **Chat sidebar** | 272px | Search, filters, channel/DM lists, layout toggle |
| **Main column** | flex | Channel status bar, messages, composer |
| **Thread panel** (optional) | ~320px | Right-side thread replies |
| **Editor header** (chat column) | full width | Channel title, search, command, settings, profile |

Settings opens in a **separate window** (not in the activity strip), matching a focused IDE shell.

## Chat sidebar structure

```
┌─────────────────────────────┐
│ 🔍 Search channels…         │  ← Titlebar row (`ChatSidebarTitlebarChrome`)
├─────────────────────────────┤
│ [All][Unread][DMs][Channels]│  ← ClickUp filters (tap again to clear)
├─────────────────────────────┤
│ CHANNELS              [+]   │  ← Organized layout
│   ○ general            (3)  │
│   ○ announcements      🧵   │  ← thread unread icon
│ DIRECT MESSAGES       [+]   │
│   ○ Jane Doe                │
│ PLANNER                     │
│   ○ Task title              │
├─────────────────────────────┤
│ [≡] [🕐]        Organized   │  ← Organized vs Recents (persisted)
└─────────────────────────────┘
```

### Filters

| Filter | Behavior |
|--------|----------|
| **All** | Channels + DMs (organized) or full recents list |
| **Unread** | Rows with message unread count or thread unread |
| **Pinned** | User-pinned channels/DMs (sidebar menu → Pin to sidebar) |
| **DMs** | Direct + group messages only |
| **Channels** | Workspace channels only |

### Layouts

| Layout | Behavior |
|--------|----------|
| **Organized** | Sections: Channels, Direct Messages, Planner |
| **Recents** | Single list sorted by `last_message_at` |

Preference keys: `publshr.chat.sidebarFilter`, `publshr.chat.sidebarLayout` (UserDefaults).

## Conversation column

- **Editor header** — channel title, in-channel search, command palette, settings, profile (typing in composer area).
- **Composer** — placeholder `Message {channel}…`, attach, voice, send (⌘↩).
- **Unread** — bold sidebar row; numeric badge on the right; thread icon for unread thread replies.

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
| `Chat/Utilities/ChatClickUpDesign.swift` | Layout tokens |
| `Chat/Views/ChatSidebarTitlebarChrome.swift` | Search in submenu titlebar row |
| `Chat/Views/ChatSidebarView.swift` | ClickUp sidebar (filters, sections, flat footer) |
| `Views/Titlebar/ChatEditorHeaderBar.swift` | Chat editor column titlebar |
| `Theme/AppWindowChrome.swift` | `TitlebarToolbarRow` / `TitlebarToolbarSlot` alignment |
| `Theme/WorkspaceShellBackground.swift` | `GlassSubmenuChrome`, primary bar transparency |
| `Theme/LibrarySubmenuButtonStyle.swift` | Flat footer actions (no pill boxes) |
| `Chat/Views/ChatWorkspaceChannelTabs.swift` | Open channel tab strip |
| `Chat/ViewModels/ChatViewModel.swift` | Filters, layout, unread threads |
| `Views/ActivityBarView.swift` | Module icons + chat badge |

## Deploy

Every push to `main` publishes the macOS `live` build. Merge PR → install or auto-update → Chat UI ships in `Publshr.app`.
