#!/usr/bin/env bash
# Build a macOS .app bundle from a release binary (shows in Applications / Launchpad).
set -euo pipefail

VERSION="${1:-0.1.0}"
BINARY="${2:-}"
OUT_APP="${3:-}"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "create-macos-app.sh only runs on macOS." >&2
    exit 1
fi

if [[ -z "$BINARY" || ! -f "$BINARY" ]]; then
    echo "Usage: $0 <version> <path-to-publshr-binary> [output/Publshr.app]" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_APP="${OUT_APP:-$SCRIPT_DIR/dist/Publshr.app}"

rm -rf "$OUT_APP"
mkdir -p "$OUT_APP/Contents/MacOS" "$OUT_APP/Contents/Resources"

cp "$BINARY" "$OUT_APP/Contents/MacOS/publshr-bin"
chmod 755 "$OUT_APP/Contents/MacOS/publshr-bin"

cat >"$OUT_APP/Contents/MacOS/publshr" <<LAUNCHER
#!/bin/bash
set -euo pipefail
APP_MACOS="\$(cd "\$(dirname "\$0")" && pwd)"
BIN="\$APP_MACOS/publshr-bin"

# Finder double-click: no TTY — open Terminal with publshr ready
if [[ ! -t 0 ]] && [[ \$# -eq 0 ]]; then
    /usr/bin/osascript <<APPLESCRIPT
tell application "Terminal"
    activate
    do script "clear; echo 'publshr CLI'; echo ''; '\$BIN' --help; echo ''; echo 'Run: publshr --version'; exec bash -l"
end tell
APPLESCRIPT
    exit 0
fi

exec "\$BIN" "\$@"
LAUNCHER
chmod 755 "$OUT_APP/Contents/MacOS/publshr"

/usr/bin/sed "s/__VERSION__/$VERSION/g" >"$OUT_APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>publshr</string>
  <key>CFBundleIdentifier</key>
  <string>com.publshr.cli</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>Publshr</string>
  <key>CFBundleDisplayName</key>
  <string>Publshr</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>__VERSION__</string>
  <key>CFBundleVersion</key>
  <string>__VERSION__</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

echo "Created $OUT_APP" >&2
