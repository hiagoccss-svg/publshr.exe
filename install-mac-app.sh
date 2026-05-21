#!/usr/bin/env bash
# macOS only: build publshr and install Publshr.app into Applications (shows in Apps / Spotlight).
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

Install Publshr.app so it appears in Applications and Launchpad.

Options:
  --applications    Install to /Applications (requires sudo)
  -h, --help        Show this help

Default: $HOME/Applications/$APP_NAME

After install, open from:
  - Finder → Applications (or ~/Applications)
  - Spotlight: Cmd+Space, type "Publshr"
  - Terminal: publshr --version  (if /usr/local/bin is linked)
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
    echo "Install Xcode from the App Store (includes Swift)." >&2
    exit 1
fi

echo "Building publshr $VERSION ..."
bash "$PROJECT_DIR/scripts/package-release.sh" "$VERSION"

ASSET="$(cd "$PROJECT_DIR/dist" && ls -d "publshr-${VERSION}-macos-"* 2>/dev/null | grep -v '.tar.gz$' | head -1)"
if [[ -z "$ASSET" ]]; then
    echo "Error: expected dist/publshr-${VERSION}-macos-*" >&2
    exit 1
fi

BINARY="$PROJECT_DIR/dist/$ASSET/bin/publshr"
chmod +x "$PROJECT_DIR/scripts/create-macos-app.sh"
bash "$PROJECT_DIR/scripts/create-macos-app.sh" "$VERSION" "$BINARY" "$PROJECT_DIR/dist/$APP_NAME"

DEST="$TARGET/$APP_NAME"
echo "Installing to $DEST ..."

if [[ "$TARGET" == "/Applications" ]]; then
    sudo rm -rf "$DEST"
    sudo cp -R "$PROJECT_DIR/dist/$APP_NAME" "$DEST"
    sudo chmod -R 755 "$DEST"
else
    mkdir -p "$TARGET"
    rm -rf "$DEST"
    cp -R "$PROJECT_DIR/dist/$APP_NAME" "$DEST"
fi

# CLI on PATH (optional, best-effort)
if [[ -w /usr/local/bin ]] || [[ "$(id -u)" -eq 0 ]]; then
    ln -sf "$DEST/Contents/MacOS/publshr-bin" /usr/local/bin/publshr 2>/dev/null || true
elif command -v sudo >/dev/null 2>&1; then
    sudo ln -sf "$DEST/Contents/MacOS/publshr-bin" /usr/local/bin/publshr 2>/dev/null || true
fi

echo ""
echo "Installed — look in Applications:"
echo "  $DEST"
echo ""
echo "Open it:"
echo "  open \"$DEST\""
echo "  (or Spotlight: Publshr)"
echo ""
if command -v publshr >/dev/null 2>&1; then
    publshr --version
else
    "$DEST/Contents/MacOS/publshr-bin" --version
fi
