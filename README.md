# publshr

Cross-platform publisher helper.

| Platform | Location | Artifact |
|----------|----------|----------|
| Windows | Repository root (see release assets) | `publshr.exe` |
| macOS | [`mac/publshr`](mac/publshr) | Swift package → `publshr` binary |

The macOS app lives in **`mac/publshr`**. Install on Mac or Linux:

```bash
./install.sh
```

The installer downloads a release asset when available, otherwise builds from source and installs to `~/.local/bin/publshr`. Same CLI as Windows (`--help`, `--version`).
