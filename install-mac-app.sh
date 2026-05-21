#!/usr/bin/env bash
# macOS: build and install the real Publshr.app (workspace app — updates live in Settings).
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "install-mac-app.sh is for macOS only." >&2
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

Installs the Publshr macOS application (publisher workspace).
Updates: Publshr menu → Settings → Updates (not a separate app).

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

echo "Removing old Publshr installs (including previous updater-style builds) …"
rm -rf "$HOME/Applications/$APP_NAME" "/Applications/$APP_NAME" 2>/dev/null || true
sudo rm -rf "/Applications/$APP_NAME" 2>/dev/null || true

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

echo ""
echo "Installed: $DEST"
echo ""
echo "This is the publisher app (drafts + workspace)."
echo "  Updates: Publshr → Settings (⌘,) → Updates tab"
echo "  Not a separate updater program."
echo ""
open -a "$DEST"
