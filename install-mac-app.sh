#!/usr/bin/env bash
# macOS: clean-build and install Publshr.app (Chat + Spaces — NOT the old sync-only UI).
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "install-mac-app.sh is for macOS only." >&2
    exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$ROOT/native/publshr"
VERSION="${PUBLSHR_VERSION:-0.2.0}"
APP_NAME="Publshr.app"
TARGET="${PUBLSHR_APP_DIR:-$HOME/Applications}"

usage() {
    cat <<EOF
Usage: $0 [options]

Installs Publshr (Cursor-style layout + ClickUp-style Chat & Spaces).

Options:
  --applications    Install to /Applications (sudo)
  -h, --help
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        --applications) TARGET="/Applications"; shift ;;
        *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
    esac
done

cd "$ROOT"
echo "Repo commit: $(git rev-parse --short HEAD 2>/dev/null || echo '?')"
if ! git rev-parse HEAD >/dev/null 2>&1; then
    echo "Warning: not a git checkout — pull latest main branch code first." >&2
fi

echo "Quitting any running Publshr …"
osascript -e 'tell application "Publshr" to quit' 2>/dev/null || true
sleep 1

echo "Removing old Publshr.app …"
rm -rf "$HOME/Applications/$APP_NAME" "/Applications/$APP_NAME" 2>/dev/null || true
sudo rm -rf "/Applications/$APP_NAME" 2>/dev/null || true
rm -rf "$PROJECT_DIR/.build" "$PROJECT_DIR/dist/$APP_NAME"

if [[ ! -f "$PROJECT_DIR/Sources/PublshrApp/AppShellView.swift" ]]; then
    echo "Error: this checkout is too old (missing AppShellView.swift)." >&2
    echo "Run: git pull origin cursor/add-makefile-and-install-4aa6" >&2
    exit 1
fi

if ! command -v swift >/dev/null 2>&1; then
    echo "Install Xcode from the App Store." >&2
    exit 1
fi

echo "Clean build Publshr.app …"
chmod +x "$PROJECT_DIR/scripts/package-mac-app.sh"
bash "$PROJECT_DIR/scripts/package-mac-app.sh" "$VERSION"

BUILT_APP="$PROJECT_DIR/dist/$APP_NAME"
DEST="$TARGET/$APP_NAME"

if [[ ! -d "$BUILT_APP" ]]; then
    echo "Error: build did not produce $BUILT_APP" >&2
    exit 1
fi

echo "Installing to: $DEST"
mkdir -p "$TARGET"
rm -rf "$DEST"
if [[ "$TARGET" == "/Applications" ]]; then
    sudo ditto "$BUILT_APP" "$DEST"
    sudo chmod -R 755 "$DEST"
else
    ditto "$BUILT_APP" "$DEST"
fi

EXEC="$DEST/Contents/MacOS/Publshr"
if [[ ! -f "$EXEC" ]]; then
    echo "Error: missing $EXEC" >&2
    ls -la "$DEST/Contents/MacOS" >&2 || true
    exit 1
fi
chmod +x "$EXEC"

if command -v codesign >/dev/null 2>&1; then
    codesign --force --deep --sign - "$DEST" 2>/dev/null || true
fi

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [[ -x "$LSREGISTER" ]]; then
    "$LSREGISTER" -f -R -trusted "$DEST" 2>/dev/null || true
fi

PLIST_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$DEST/Contents/Info.plist" 2>/dev/null || echo "?")
echo ""
echo "Installed: $DEST (version $PLIST_VERSION)"
echo ""
echo "CORRECT app looks like:"
echo "  • Dark window, icon rail on the left (Chat / Spaces)"
echo "  • Chat: #channels + messages + Send"
echo "  • WRONG: single screen with only 'Sync from GitHub' — that is an OLD build"
echo ""
echo "If you see the old UI: git pull && ./install-mac-app.sh again"
echo ""
open -a "$DEST"
