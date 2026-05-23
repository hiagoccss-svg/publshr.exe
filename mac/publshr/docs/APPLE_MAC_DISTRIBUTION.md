# Apple trust — open without “unidentified developer”

Publshr ships **outside the Mac App Store** (GitHub download). Apple does **not** require an App Store privacy questionnaire for that path. Users get a normal double-click open after you complete **Developer ID signing + notarization** on **your** Apple Developer account.

## Two different “privacy” things

| What | Who fills it | Required for GitHub download? |
|------|----------------|-------------------------------|
| **Gatekeeper / notarization** | You (Apple Developer Program) | Yes — otherwise users use Right-click → Open |
| **App Store privacy labels** | You, in App Store Connect | **No** — not listing on the Mac App Store |
| **In-app policy links** | Your legal pages (`publshr.com/privacy`) | Product choice — app uses a short first-run notice, not a separate Apple form |
| **macOS permission prompts** | Already in `Info.plist` (mic, camera, Face ID) | Yes when those features are used — system dialogs only |

Nothing in this repo can be “filled out on Cursor’s side” for **your** Apple identity. You add credentials to GitHub; CI signs and notarizes every `main` build.

## What you need (one-time)

1. Enroll in the [Apple Developer Program](https://developer.apple.com/programs/) (paid).
2. Create a **Developer ID Application** certificate in Xcode or Certificates portal.
3. Create an [app-specific password](https://appleid.apple.com) for notarization.
4. Add these **GitHub repository secrets** (Settings → Secrets → Actions):

| Secret | Example |
|--------|---------|
| `DEVELOPER_ID_APPLICATION` | `Developer ID Application: Your Name (TEAMID)` |
| `APPLE_ID` | your@email.com |
| `APPLE_APP_SPECIFIC_PASSWORD` | xxxx-xxxx-xxxx-xxxx |
| `APPLE_TEAM_ID` | 10-character team id |

5. Push to `main` → **Deliver macOS live app** signs `Publshr.app`, notarizes, staples, and publishes the DMG/zip.

After that, downloads open like any commercial Mac app — no Right-click → Open.

## Verify locally (Mac with certs)

```bash
cd mac/publshr
export DEVELOPER_ID_APPLICATION="Developer ID Application: …"
export APPLE_ID="…"
export APPLE_APP_SPECIFIC_PASSWORD="…"
export APPLE_TEAM_ID="…"
bash scripts/package-release.sh 0.0.0-test
STAGE="dist/publshr-0.0.0-test-macos-aarch64"
bash scripts/sign-macos-release.sh "$STAGE/Publshr.app" --notarize-app
spctl -a -vv "$STAGE/Publshr.app"
```

Expect `source=Notarized Developer ID`.

## What we ship in the bundle

- `PrivacyInfo.xcprivacy` — Apple privacy manifest (required-reason APIs: UserDefaults, file timestamps).
- `Info.plist` usage strings — microphone, camera, Face ID (system prompts when used).
- Hardened runtime + Developer ID signature when secrets are configured.

## MDM / enterprise

Notarized `Publshr.app` or `Publshr-Install-macos.dmg` can be deployed via MDM. No App Store review.

## If secrets are missing

CI still builds and publishes ad-hoc signed binaries. Users must **right-click → Open** once. This is expected until you add the four secrets above.
