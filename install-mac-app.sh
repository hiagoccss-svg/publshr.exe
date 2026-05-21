#!/usr/bin/env bash
# macOS: build Publshr.app (Publisher + in-app Updates) and install to Applications.
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

usage() {
    cat <<EOF
Usage: $0 [options]

Installs Publshr (publisher app with Updates inside the app — not a separate updater).

Options:
  --applications    Install to /Applications (sudo)
  -h, --help        Show help

Default install location: ~/Applications/Publshr.app
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

echo "Building Publshr.app …"
chmod +x "$PROJECT_DIR/scripts/package-mac-app.sh"
bash "$PROJECT_DIR/scripts/package-mac-app.sh" "$VERSION"

BUILT_APP="$PROJECT_DIR/dist/$APP_NAME"
DEST="$TARGET/$APP_NAME"

if [[ ! -d "$BUILT_APP" ]]; then
    echo "Error: build did not produce $BUILT_APP" >&2
    exit 1
fi

echo "Installing to: $DEST"
if [[ "$TARGET" == "/Applications" ]]; then
    sudo rm -rf "$DEST"
    sudo ditto "$BUILT_APP" "$DEST"
    sudo chmod -R 755 "$DEST"
else
    mkdir -p "$TARGET"
    rm -rf "$DEST"
    ditto "$BUILT_APP" "$DEST"
fi

# Register with Launch Services so it appears in Applications / Spotlight
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [[ -x "$LSREGISTER" ]]; then
    "$LSREGISTER" -f -R -trusted "$DEST" 2>/dev/null || true
fi

EXEC="$DEST/Contents/MacOS/Publshr"
if [[ ! -f "$EXEC" ]]; then
    echo "Error: installed app is incomplete (missing $EXEC)" >&2
    echo "Contents/MacOS:" >&2
    ls -la "$DEST/Contents/MacOS" 2>&1 >&2 || true
    exit 1
fi
chmod +x "$EXEC"

echo ""
echo "Publshr is installed:"
echo "  $DEST"
echo ""
echo "Open from Finder → Applications, or:"
echo "  open -a \"$DEST\""
echo ""
echo "Updates: open the app → sidebar → Updates (not a separate program)."
echo ""

# Open the installed copy only (not the build folder copy)
open -a "$DEST"
