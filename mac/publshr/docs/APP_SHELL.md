# Publshr macOS app shell

The product is a **native Swift/SwiftUI desktop app** with a fixed shell and **pluggable modules** inside. Each module is gated by the workspace **subscription plan** in Supabase.

## What you install

| Artifact | Purpose |
|----------|---------|
| **`Publshr-Install-macos.zip`** | **Canonical download** — full `Publshr.app` inside zip; double-click `Publshr Install.command` (CI `live` release) |
| **`Publshr-macos-aarch64.tar.gz`** | Full app bundle the installer downloads from GitHub `releases/download/live/` |
| **`icon.png`** (repo root) | Synced to `mac/publshr/app/icon.png` before build → Dock/Finder/installer icons |

Install (canonical):

```bash
curl -fsSL "https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install-macos.sh" | bash
```

## Shell layers (library glass reference)

```
┌──────────────────────────────────────────────────────────────┐
│  Desktop wallpaper (behindWindow vibrancy)                    │
│  ┌────────┬──────────────┬─────────────────────────────────┐ │
│  │ Bar    │  Universal   │  Floating glass panel (20px     │ │
│  │ menu   │  submenu     │  radius) — Chat / Spaces        │ │
│  │ 200px  │  260px       │  + outer margin 20px            │ │
│  └────────┴──────────────┴─────────────────────────────────┘ │
│  Unified titlebar (sidebar, New Chat, workspace, search, notifications, profile, settings) │
│  Disconnected status line                                     │
└──────────────────────────────────────────────────────────────┘
```

| Layer | Files |
|-------|--------|
| Flow | `ContentView.swift`, `AuthViewModel`, `AuthView`, `WorkspacePickerView` |
| Shell | `MainIDEView.swift`, `LibraryBarMenuColumn` (200px bar menu), `AppSecondarySidebar` |
| Glass | `WorkspaceDesktopBackdrop`, `LibraryFloatingPanel`, `LibraryGlassDesign` |
| Submenu | `LibraryUniversalSubmenu`, `ChatSidebarView`, `SpacesNavSidebar` |
| Chrome | `AppWindowChrome.swift`, `LibraryShellHeaderView`, `TitlebarChromeActionBar` — unified titlebar actions |
| Marker | `AppShellIdentity.distributionTag` = `PublshrEnterpriseShell-10` (line 5 of `live/VERSION.txt`; auto-update when it changes) |

## Adding a new module (same pattern as Chat)

1. **Supabase** — tables, RLS, optional RPCs; plan flags on `subscription_plans` (`includes_*`).
2. **Service + ViewModel** — e.g. `ChatService`, `ChatViewModel`.
3. **UI** — root view + **integrated chrome** (do not add a second global toolbar in `MainIDEView`).
4. **`AppModule`** — case in enum, bar menu row in `ActivityBarView`, `MainIDEView.moduleMainContent` switch.
5. **Gate** — `subscription.canUse*(workspace:)` before showing content; else `EnterpriseModuleGate`.
6. **Attach on sign-in** — `ContentView.syncEnterpriseData()` / `PublshrApp.syncEnterpriseServices()`.

## Live updates

- App checks GitHub tag **`live`** using `releases/download/...` URLs (avoids API 403).
- Downloads install in place to `~/Applications/Publshr.app` when possible.
- Shell marker **`PublshrEnterpriseShell-10`** must be present in the binary for CI verification.

## CI

Push to **`main`** → `.github/workflows/deliver-macos.yml` publishes `live` assets and `Publshr-Install-macos.zip`.
