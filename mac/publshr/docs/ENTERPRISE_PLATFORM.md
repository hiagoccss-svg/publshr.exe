# Enterprise platform (native macOS)

Publshr’s native macOS IDE (`mac/publshr`) includes an enterprise layer for **install onboarding**, **subscriptions**, **workspace setup**, **settings**, **privacy**, **device registration**, and **local files**.

## First-run setup

After sign-in, `EnterpriseOnboardingView` runs when:

- `EnterpriseInstallState.needsEnterpriseSetup` is true, or
- the user has not accepted the privacy policy (`PrivacyConsentStore`).

Steps: privacy → device acknowledgment → plan summary. Completing setup registers the Mac in `device_registrations` and logs `privacy_audit_events`.

## Subscription plans

Plans live in Supabase `subscription_plans` (see migration `002_enterprise_platform.sql`). Each workspace has `plan_id` (default `trial`).

| Plan       | Chat | Spaces | Seats |
|------------|------|--------|-------|
| trial      | ✓    | ✓      | 3     |
| team       | ✓    | ✓      | 25    |
| enterprise | ✓    | ✓      | 500   |

`SubscriptionService` loads the plan and gates Chat/Spaces modules in `MainIDEView`.

## Settings (native)

`SettingsRootView` replaces the legacy single-page settings:

- **Updates** — live channel / auto-install
- **Account** — profile, sign out
- **Workspace** — switch workspace, invite members
- **Subscription** — plan, seats, feature flags
- **Privacy** — policy acceptance, audit
- **Devices** — registered Macs + this device
- **Files** — native open panel, security-scoped bookmarks
- **Security** — Keychain session, Touch ID
- **Chat** — permissions persisted to `workspaces.settings.chat`

## Local files

`FileAccessService` uses `NSOpenPanel` and security-scoped bookmarks for uploads (Chat composer, Settings → Files test).

## Database

Apply migrations in order:

1. Chat migrations under `mac/publshr/supabase/migrations/` (presence, phases)
2. `001_spaces_schema.sql` (if using Spaces)
3. `002_enterprise_platform.sql`

## Swift modules

| Path | Role |
|------|------|
| `Sources/PublshrApp/Enterprise/` | Services (subscription, device, files, workspace) |
| `Sources/PublshrApp/Views/Settings/` | Settings UI |
| `Sources/PublshrApp/Views/Enterprise/` | Onboarding, module gates |

## Install / updates

Stable install: `install-macos.sh` from the repo. CI publishes the `live` release; the app auto-updates via `AppUpdateViewModel`.
