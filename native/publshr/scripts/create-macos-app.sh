#!/usr/bin/env bash
# Wrap the SwiftUI Publshr binary in a real macOS .app (no Terminal, no shell launcher).
set -euo pipefail

VERSION="${1:-0.1.0}"
BINARY="${2:-}"
OUT_APP="${3:-}"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "create-macos-app.sh only runs on macOS." >&2
    exit 1
fi

if [[ -z "$BINARY" || ! -f "$BINARY" ]]; then
    echo "Usage: $0 <version> <path-to-Publshr-binary> [output/Publshr.app]" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_APP="${OUT_APP:-$SCRIPT_DIR/dist/Publshr.app}"

rm -rf "$OUT_APP"
mkdir -p "$OUT_APP/Contents/MacOS" "$OUT_APP/Contents/Resources"

# Real GUI executable — double-click opens the app window, not Terminal.
cp "$BINARY" "$OUT_APP/Contents/MacOS/Publshr"
chmod 755 "$OUT_APP/Contents/MacOS/Publshr"

/usr/bin/sed "s/__VERSION__/$VERSION/g" >"$OUT_APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>Publshr</string>
  <key>CFBundleIdentifier</key>
  <string>com.publshr.app</string>
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
  <string>14.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.productivity</string>
  <key>LSUIElement</key>
  <false/>
</dict>
</plist>
PLIST

echo "Created real macOS app: $OUT_APP" >&2
