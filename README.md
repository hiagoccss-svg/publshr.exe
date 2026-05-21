# publshr

Cross-platform publisher helper.

| Platform | Location | Artifact |
|----------|----------|----------|
| Windows | Repository root (see release assets) | `publshr.exe` |
| macOS | [`mac/publshr`](mac/publshr) | Swift package → `publshr` binary |

The macOS app lives in **`mac/publshr`**: a Swift package you can build with `swift build -c release` on a Mac. It exposes the same CLI shape as the Windows tool (`--help`, `--version`); extend `Sources/publshr/main.swift` when you add shared behavior.
