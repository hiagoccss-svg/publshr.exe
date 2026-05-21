#!/usr/bin/env bash
# Install publshr from anywhere (no git clone required).
# Usage: curl -fsSL https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/cursor/add-mac-publshr-9411/install-publshr.sh | bash
set -euo pipefail

VERSION="${PUBLSHR_VERSION:-0.1.0}"
REPO="${PUBLSHR_REPO:-hiagoccss-svg/publshr.exe}"
BRANCH="${PUBLSHR_BRANCH:-cursor/add-mac-publshr-9411}"
INSTALLER_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/mac/publshr/install.sh"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

echo "Fetching installer ..."
curl -fsSL "$INSTALLER_URL" -o "$TMP"
chmod +x "$TMP"

if [[ "$(uname -s)" == "Darwin" ]]; then
    echo ""
    echo "This installs Publshr to /Applications (Launchpad + Finder → Applications)"
    echo "and adds the publshr command for Terminal."
    echo ""
fi

exec env PUBLSHR_VERSION="$VERSION" PUBLSHR_REPO="$REPO" "$TMP" "$@"
