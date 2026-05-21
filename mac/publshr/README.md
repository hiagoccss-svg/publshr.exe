# publshr (macOS / Linux)

Swift package for the macOS counterpart to Windows `publshr.exe` (also builds on Linux).

## Install (recommended)

From this directory:

```bash
./install.sh
```

This tries to **download** a release binary from GitHub first, then **builds from source** if no release exists. The binary is installed to `~/.local/bin/publshr` by default. Override the location:

```bash
PREFIX=/usr/local/bin ./install.sh
```

Requires [Swift](https://www.swift.org/install/) 5.9+ when building from source (Xcode on Mac).

## Build only

```bash
swift build -c release
```

Binary: `.build/release/publshr`

## Run without installing

```bash
swift run publshr --version
```
