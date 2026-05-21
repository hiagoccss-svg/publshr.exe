# publshr (macOS)

Swift package that builds the macOS counterpart to the Windows `publshr.exe` in the repo root.

## Requirements

- macOS 13 or later
- [Swift](https://www.swift.org/install/) 5.9 or later (Xcode or standalone toolchain)

## Build

From this directory:

```bash
swift build -c release
```

The binary is at `.build/release/publshr`. Copy it anywhere on your `PATH`, or run:

```bash
swift run publshr --help
```

## Run without installing

```bash
swift run publshr --version
```
