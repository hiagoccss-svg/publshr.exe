#!/usr/bin/env bash
# Install publshr from anywhere (no git clone required).
# Usage: curl -fsSL https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/main/install-publshr.sh | bash
set -euo pipefail

REPO="${PUBLSHR_REPO:-hiagoccss-svg/publshr.exe}"
BRANCH="${PUBLSHR_BRANCH:-main}"

# Default to newest GitHub release tag (strip leading v).
resolve_latest_version() {
    local api="https://api.github.com/repos/${REPO}/releases?per_page=10"
    local tag
    tag="$(curl -fsSL -H "Accept: application/vnd.github+json" -H "User-Agent: Publshr-Installer/1.0" "$api" \
        | python3 -c "
import json, sys
releases = json.load(sys.stdin)
best = None
for r in releases:
    name = (r.get('tag_name') or '').lstrip('v')
    parts = name.split('.')
    if len(parts) < 2 or not parts[-1].isdigit():
        continue
    build = int(parts[-1])
    if best is None or build > best[0]:
        best = (build, name)
print(best[1] if best else '', end='')
" 2>/dev/null || true)"
    if [[ -n "$tag" ]]; then
        echo "$tag"
        return 0
    fi
    echo "0.2.0"
}

VERSION="${PUBLSHR_VERSION:-$(resolve_latest_version)}"
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
