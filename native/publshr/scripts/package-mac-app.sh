#!/usr/bin/env bash
# Build SwiftUI Publshr.app and zip for GitHub Releases / install-mac-app.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-0.1.0}"
cd "$SCRIPT_DIR"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "package-mac-app.sh requires macOS." >&2
    exit 1
fi

if ! command -v swift >/dev/null 2>&1; then
    echo "Swift/Xcode required." >&2
    exit 1
fi

echo "Building Publshr (SwiftUI) $VERSION ..." >&2
echo "Git: $(git -C "$SCRIPT_DIR/../.." rev-parse --short HEAD 2>/dev/null || echo unknown)" >&2
swift package clean 2>/dev/null || rm -rf "$SCRIPT_DIR/.build"
swift build -c release --product Publshr

BIN="$SCRIPT_DIR/.build/release/Publshr"
chmod +x "$SCRIPT_DIR/scripts/create-macos-app.sh"
bash "$SCRIPT_DIR/scripts/create-macos-app.sh" "$VERSION" "$BIN" "$SCRIPT_DIR/dist/Publshr.app"

mkdir -p "$SCRIPT_DIR/dist"
OUT="$SCRIPT_DIR/dist/Publshr-${VERSION}-macos.app.zip"
rm -f "$OUT"
ditto -c -k --sequesterRsrc --keepParent "$SCRIPT_DIR/dist/Publshr.app" "$OUT"
echo "Created $OUT" >&2
ls -lh "$OUT" >&2
