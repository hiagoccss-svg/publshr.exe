# publshr (macOS)

Native SwiftUI app matching **Cursor on Mac** layout and colors, backed by **Supabase Auth**.

## Install

```bash
./install.sh
```

Installs **Publshr.app** to `/Applications` and the `publshr` launcher in `/usr/local/bin`.

## Build

```bash
swift build -c release --product PublshrApp --product publshr
./scripts/package-release.sh 0.2.0
```

On macOS the tarball includes `Publshr.app`, `bin/PublshrApp`, and `bin/publshr` (CLI).

## Auth configuration

1. Supabase project `lboesdtsrqfvosznjpdy`
2. Redirect URL: `com.publshr.app://auth/callback`
3. Signup email template should include OTP: `{{ .Token }}` for in-app confirmation

Keys are in `Sources/PublshrApp/Services/SupabaseConfig.swift` (publishable key only — safe for clients).

## Layout (Cursor parity)

| Region | Width | Color |
|--------|-------|-------|
| Activity bar | 48px | `#181818` |
| Sidebar | 260px | `#252526` |
| Editor | flex | `#1e1e1e` |
| Chat panel | 380px | `#181818` / `#1e1e1e` |
| Status bar | 22px | `#007acc` |
