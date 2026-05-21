# AGENTS.md

## Cursor Cloud specific instructions

### Project overview

`publshr` is a cross-platform CLI tool (matching Windows `publshr.exe`). The main code lives under `mac/publshr/` as a Swift Package Manager project requiring Swift >= 5.9.

### Swift toolchain

The update script installs Swift 5.10.1 to `/opt/swift/usr/bin` and adds it to PATH via `~/.bashrc`. Verify with `swift --version`.

### Build and run

```bash
cd mac/publshr
swift build              # debug build
swift build -c release   # release build
.build/debug/publshr --help
.build/debug/publshr --version
```

### Enterprise chat (mac IDE)

Chat lives under `mac/publshr/Sources/PublshrApp/Chat/`. See `mac/publshr/docs/CHAT_SYSTEM.md`. Supabase migrations: `20260521180000_chat_presence_and_members.sql`, `20260521200000_chat_phases_2_4.sql`.

### Tests

No automated test suite exists yet (`swift test` reports "no tests found"). If tests are added later, run them with `swift test` from `mac/publshr/`.

### Lint

No dedicated linter is configured. Swift compiler warnings serve as the primary code quality check during `swift build`.

### Release packaging

```bash
cd mac/publshr
chmod +x scripts/package-release.sh
bash scripts/package-release.sh <version>
```

Produces `dist/publshr-<version>-<os>-<arch>.tar.gz`.

### Gotchas

- On Ubuntu, Swift requires `libncurses6`, `libcurl4`, and `libxml2` runtime libraries. The update script installs these automatically.
- The `@main` attribute in `main.swift` uses Swift's entry-point API; this requires Swift >= 5.3 but the package declares `swift-tools-version: 5.9`.
- The `main` branch is mostly empty (just a README). Application code is on feature branches.
