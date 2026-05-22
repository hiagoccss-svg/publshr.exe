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

## Shell layers

```
┌─────────────────────────────────────────────────────────┐
│  Auth → Workspace picker → MainIDEView                     │
│  Desktop wallpaper → glass shell → floating library cards  │
├──────────┬──────────────┬────────────────────────────────┤
│ Bar menu │  Universal   │  Glass main content (Chat /     │
│ (compact │  submenu     │  Spaces) + disconnected footer  │
│ or wide) │  (module nav)│  actions at column bottom       │
├──────────┴──────────────┴────────────────────────────────┤
│  Unified header (tabs) · thin status line (main column)  │
└─────────────────────────────────────────────────────────┘
```

Bar menu: `ActivityBarView` — toggle **compact** (48px icons) vs **expanded** labels (`publshr.barMenuExpanded`). Universal submenu: `LibraryUniversalSubmenu` + `AppSecondarySidebar`. Glass: `WorkspaceDesktopBackdrop`, `glassMainContent()`, `.libraryCard(glass:)`.

| Layer | Files |
|-------|--------|
| Flow | `ContentView.swift`, `AuthViewModel`, `AuthView`, `WorkspacePickerView` |
| Shell | `MainIDEView.swift`, `ActivityBarView`, sidebars |
| Subscription gate | `SubscriptionService`, `EnterpriseModuleGate` |
| Updates | `AppUpdateService`, `AppUpdateViewModel` (silent sync; Settings for errors) |
| Security | `BiometricAuthService`, `AuthKeychain`, Settings → Security |

## Adding a new module (same pattern as Chat)

1. **Supabase** — tables, RLS, optional RPCs; plan flags on `subscription_plans` (`includes_*`).
2. **Service + ViewModel** — e.g. `ChatService`, `ChatViewModel`.
3. **UI** — root view + **integrated chrome** (do not add a second global toolbar in `MainIDEView`).
4. **`AppModule`** — case in enum, activity bar icon, `MainIDEView.moduleMainContent` switch.
5. **Gate** — `subscription.canUse*(workspace:)` before showing content; else `EnterpriseModuleGate`.
6. **Attach on sign-in** — `ContentView.syncEnterpriseData()` / `PublshrApp.syncEnterpriseServices()`.

## Workspace setup

- After sign-in, user picks or **creates** a workspace (`create_workspace` RPC in `20260522000000_enterprise_foundation.sql`).
- Selection is stored in `UserDefaults` (`com.publshr.app.lastWorkspaceId`).
- Must apply Supabase migrations or workspace create/list will fail with a clear in-app message.

## Biometrics (Touch ID / Face ID)

1. Sign in with email/password (session stays in Supabase client storage).
2. Enable **Quick unlock** in Settings → Security (or accept the one-time sheet after first sign-in).
3. Session tokens are copied to Keychain; each launch prompts for biometrics before the IDE opens.
4. **Sign out** keeps Keychain when quick unlock is on so the sign-in screen can offer **Unlock with Touch ID**.

## Live updates

- App checks GitHub tag **`live`** using `releases/download/...` URLs (avoids API 403).
- Downloads install in place to `~/Applications/Publshr.app` when possible.
- Old builds cannot self-update until replaced once via the installer above.

## CI

Push to **`main`** → `.github/workflows/deliver-macos.yml` publishes `live` assets and `Publshr-Install-macos.zip`.
