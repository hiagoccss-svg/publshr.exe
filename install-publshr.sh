#!/usr/bin/env bash
# Install publshr CLI (Linux) or redirect macOS users to the real .app installer.
set -euo pipefail

if [[ "$(uname -s)" == "Darwin" ]]; then
    ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo ".")"
    if [[ -f "$ROOT/install-mac-app.sh" ]]; then
        echo "On macOS, install the application (not the CLI updater) with:"
        echo "  cd \"$ROOT\" && ./install-mac-app.sh"
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
echo "Installing publshr CLI ${VERSION} (requires sudo) …"
exec sudo env PUBLSHR_VERSION="$VERSION" PUBLSHR_REPO="$REPO" "$TMP" "$@"
