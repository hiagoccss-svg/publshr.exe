#!/usr/bin/env bash
# Install publshr from anywhere (no git clone required).
# Usage: curl -fsSL https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/cursor/add-mac-publshr-9411/install-publshr.sh | bash
set -euo pipefail

VERSION="${PUBLSHR_VERSION:-0.1.0}"
REPO="${PUBLSHR_REPO:-hiagoccss-svg/publshr.exe}"
BRANCH="${PUBLSHR_BRANCH:-cursor/add-mac-publshr-9411}"
INSTALLER_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/native/publshr/install.sh"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

echo "Fetching installer ..."
curl -fsSL "$INSTALLER_URL" -o "$TMP"
chmod +x "$TMP"
echo "Installing publshr ${VERSION} (requires sudo) ..."
exec sudo env PUBLSHR_VERSION="$VERSION" PUBLSHR_REPO="$REPO" "$TMP" "$@"
