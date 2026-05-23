# Enterprise install, user data, and live delivery

How to ship Publshr like an enterprise Mac app: what goes in the installer, what stays on disk per user, and how **`main` → live → your Mac** stays under ~30 seconds after GitHub publishes.

## Do not disable macOS security

Turning off Gatekeeper or SIP is **not** required and is unsafe for production.

| Approach | Use |
|----------|-----|
| **Developer ID + notarization** | Production — users get seamless open/update (planned in CI) |
| **Install to `~/Applications`** | Updates without admin password each time |
| **Install to `/Applications`** | One admin prompt per update (existing `apply-macos-update.sh`) |
| **First open: Right-click → Open** | Dev/internal only, until notarized |

Auto-update **replaces only** `Publshr.app`. It never deletes user data under Application Support.

## What to put in the download / installer

Every push to **`main`** publishes these **fixed URLs** on the `live` release:

| Asset | Audience | Contents |
|-------|----------|----------|
| **Publshr-Install-macos.dmg** | End users (recommended) | `PublshrInstaller.app`, `Publshr.app`, Applications alias |
| **Publshr-Install-macos.zip** | End users / IT | Same payload as DMG |
| **Publshr-macos-aarch64.tar.gz** | MDM / in-app updater | App bundle only |
| **VERSION.txt** | Auto-updater | Version, build, commit, SHA-256, shell tag |

**Include in the app bundle (CI already does):**

- Native `Publshr.app` (Swift UI, Chat, Spaces, Settings)
- `apply-macos-update.sh` + rollback backup logic
- App icon synced from repo root before build
- Embedded build metadata (`PublshrLiveVersion`, commit, shell tag)

**Optional extras for enterprise IT:**

- Privacy policy / EULA PDF in the zip (add to `package-install-download.sh` when ready)
- MDM manifest pointing at `Publshr-macos-aarch64.tar.gz`
- Supabase project URL in a small `enterprise.json` template (not secrets)

**Do not ship in the installer:** Supabase service keys, user passwords, or per-tenant data.

## What we save per user (never wiped by updates)

All under `~/Library/Application Support/Publshr/`:

| Path / data | Purpose |
|-------------|---------|
| **Keychain** (`AuthKeychain`) | Supabase session — not `localStorage` |
| **Auth offline cache** | Session restore when offline |
| **Chat SQLite** (`ChatLocalStore`) | Channels, messages, drafts, unread counts |
| **Spaces SQLite** | Spaces/tasks cache |
| **UserDefaults** | Sidebar layout, filters, update toggles, last workspace |
| **Window frames** | Main window + pop-out positions |
| **updates/** | Downloaded tarball, `last-update.log`, backup `.app` before install |
| **crashes/** | Local crash reports |
| **voice-notes/** | Local voice attachments |
| **install-source.tree** | Installer diagnostics |

Cloud source of truth: **Supabase** (profiles, chat, spaces, devices, subscriptions).

Full three-tier model (GitHub vs Mac vs Supabase): [DATA_ARCHITECTURE.md](./DATA_ARCHITECTURE.md).

## Live mode: push here → see on Mac quickly

```mermaid
flowchart LR
  A[git push main] --> B[deliver-macos.yml ~3-8 min]
  B --> C[live release updated]
  C --> D[Installed app polls every 30s]
  D --> E[Download verify SHA-256]
  E --> F[Auto-install + relaunch]
  F --> G[Supabase sync same tick]
```

### Timeline (realistic)

| Step | Time |
|------|------|
| Merge / push to `main` | 0 |
| GitHub Actions build + publish `live` | ~3–8 minutes (macOS runner) |
| Installed app notices new `VERSION.txt` | **≤ 30 seconds** after publish |
| Download + install (if auto-install on) | +30–90 seconds (size + network) |

**You cannot beat CI build time** from the client. For fastest iteration:

1. Push to **`main`** (not only a long-lived PR branch).
2. Wait for green **Deliver macOS live app** on GitHub Actions.
3. Keep the app open with **Settings → Updates → Auto-check** and **Install updates automatically** enabled.
4. Or tap **Sync now** after CI finishes.

### What the app checks every 30 seconds

- `VERSION.txt` on the `live` release (version, build, commit, package hash, shell tag)
- Immediate check when the app becomes **active** or **wakes from sleep**
- **Settings → Sync now** = GitHub live + Supabase in one action (always runs GitHub check, even when auto-check is off)
- After each successful in-place update, the app records the live `VERSION.txt` digest so the next poll does not re-download the same build

### Settings toggles (per machine)

| Toggle | Default | Effect |
|--------|---------|--------|
| Auto-check every 30 seconds | On | Poll `live` |
| Install updates automatically | On | Download + run `apply-macos-update.sh` |
| Auto-check off | — | Manual **Sync now** only |

Install location:

- **`~/Applications/Publshr.app`** — passwordless updates (recommended for dev)
- **`/Applications/Publshr.app`** — one admin password per update

## Enterprise checklist (best practices)

### Shipping

- [x] Fixed `live` URLs (install + update never break links)
- [x] PR + `main` compile check before publish
- [x] Transactional update with rollback
- [x] SHA-256 verify before install
- [x] CI hooks for Developer ID sign + DMG notarize (`DEVELOPER_ID_APPLICATION`, `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, `APPLE_TEAM_ID` secrets)
- [ ] Configure Apple secrets on the repo (until then: Right-click → Open on first launch)
- [ ] Remote crash reporting (Sentry / App Insights)

### Identity & compliance

- [x] Keychain session storage
- [x] Touch ID / password unlock optional
- [x] Device registration per workspace
- [x] Privacy consent store
- [ ] SSO / SAML (Supabase enterprise)
- [ ] MDM deployment guide for IT

### Operations

- [x] Local update logs
- [x] Offline chat/spaces cache
- [x] 30s live + cloud sync interval
- [ ] Delta/patch updates (today: full tarball)

## Electron apps (Spaces / Media Monitoring / Planner)

Separate products use **`desktop/docs/DESKTOP_WORKFLOW.md`** and channels `spaces-staging`, etc. The native IDE uses the **`live`** channel only.

## Related

- [INSTALL.md](./INSTALL.md) — download links
- [AUTO_UPDATE.md](./AUTO_UPDATE.md) — updater mechanics
- [ENTERPRISE_DESKTOP.md](./ENTERPRISE_DESKTOP.md) — platform matrix
