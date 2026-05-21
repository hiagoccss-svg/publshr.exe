#!/usr/bin/env bash
# macOS: build real SwiftUI Publshr.app and install to Applications.
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "install-mac-app.sh is for macOS only. On Linux use: ./install-local.sh" >&2
    exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$ROOT/native/publshr"
VERSION="${PUBLSHR_VERSION:-0.1.0}"
APP_NAME="Publshr.app"
TARGET="${PUBLSHR_APP_DIR:-$HOME/Applications}"
BRANCH="${PUBLSHR_BRANCH:-cursor/add-makefile-and-install-4aa6}"

usage() {
    cat <<EOF
Usage: $0 [options]

Builds a real macOS application (SwiftUI window — not a Terminal script).
Installs to Applications. Syncs from Git branch: $BRANCH

Options:
  --applications    Install to /Applications (sudo)
  -h, --help        Show help

After install: Finder → Applications → Publshr
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        --applications) TARGET="/Applications"; shift ;;
        *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
    esac
done

if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "Error: $PROJECT_DIR not found." >&2
    exit 1
fi

if ! command -v swift >/dev/null 2>&1; then
    echo "Install Xcode from the App Store." >&2
    exit 1
fi

echo "Building real Publshr.app (SwiftUI) ..."
chmod +x "$PROJECT_DIR/scripts/package-mac-app.sh"
bash "$PROJECT_DIR/scripts/package-mac-app.sh" "$VERSION"

DEST="$TARGET/$APP_NAME"
echo "Installing to $DEST ..."

if [[ "$TARGET" == "/Applications" ]]; then
    sudo rm -rf "$DEST"
    sudo cp -R "$PROJECT_DIR/dist/Publshr.app" "$DEST"
    sudo chmod -R 755 "$DEST"
else
    mkdir -p "$TARGET"
    rm -rf "$DEST"
    cp -R "$PROJECT_DIR/dist/Publshr.app" "$DEST"
fi

# CLI helper (optional)
CLI="$(find "$PROJECT_DIR/dist" -maxdepth 2 -path '*/bin/publshr' 2>/dev/null | head -1)"
if [[ -n "$CLI" && -f "$CLI" ]]; then
    if command -v sudo >/dev/null 2>&1; then
        sudo ln -sf "$CLI" /usr/local/bin/publshr 2>/dev/null || true
    fi
fi

echo ""
echo "Installed real Mac app:"
echo "  $DEST"
echo ""
echo "Open: open \"$DEST\""
echo "Or Spotlight → Publshr"
echo ""
echo "Auto-sync branch: $BRANCH (when online, use Sync from GitHub in the app)"
open "$DEST" 2>/dev/null || true
