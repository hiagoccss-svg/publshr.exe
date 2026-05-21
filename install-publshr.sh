#!/usr/bin/env bash
# Install publshr: macOS Supabase app (default) or mac/publshr IDE + CLI (PUBLSHR_INSTALL=mac-ide).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo ".")"

if [[ "$(uname -s)" == "Darwin" ]]; then
    if [[ "${PUBLSHR_INSTALL:-}" == "mac-ide" && -f "$ROOT/mac/publshr/install.sh" ]]; then
        echo "Installing mac/publshr IDE to /Applications …"
        exec "$ROOT/mac/publshr/install.sh" "$@"
    fi
    if [[ -f "$ROOT/install-mac-app.sh" ]]; then
        echo ""
        echo "Installing Publshr (Supabase Chat & Spaces) to ~/Applications or /Applications."
        echo "For the Cursor-style IDE instead: PUBLSHR_INSTALL=mac-ide ./install-publshr.sh"
        echo ""
        exec "$ROOT/install-mac-app.sh" "$@"
    fi
fi

VERSION="${PUBLSHR_VERSION:-0.1.0}"
REPO="${PUBLSHR_REPO:-hiagoccss-svg/publshr.exe}"
BRANCH="${PUBLSHR_BRANCH:-cursor/add-makefile-and-install-4aa6}"
INSTALLER_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/native/publshr/install.sh"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

echo "Fetching CLI installer …"
curl -fsSL "$INSTALLER_URL" -o "$TMP"
chmod +x "$TMP"

if [[ "$(uname -s)" == "Darwin" ]]; then
    echo ""
    echo "This installs the publshr CLI (Linux-style path). For the Mac .app use ./install-mac-app.sh"
    echo ""
fi

echo "Installing publshr CLI ${VERSION} (requires sudo) …"
exec sudo env PUBLSHR_VERSION="$VERSION" PUBLSHR_REPO="$REPO" "$TMP" "$@"
