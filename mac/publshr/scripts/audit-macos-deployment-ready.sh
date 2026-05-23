#!/usr/bin/env bash
# Full pre-deploy audit: GitHub live channel, Supabase enterprise APIs, shell tag alignment.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== Publshr macOS deployment audit ==="
echo "Repo: $(git -C "$ROOT/../.." rev-parse --show-toplevel 2>/dev/null || echo publshr)"
echo

bash "$ROOT/scripts/verify-github-live.sh"
echo
bash "$ROOT/scripts/verify-all-connections.sh"
echo
bash "$ROOT/scripts/verify-enterprise.sh"
echo

# shellcheck source=lib-shell-tag.sh
source "$ROOT/scripts/lib-shell-tag.sh"
SHELL_TAG="$(resolve_publshr_shell_tag "$ROOT/Sources/PublshrApp/Config/AppShellIdentity.swift")"
REMOTE_SHELL="$(curl -fsSL "https://github.com/hiagoccss-svg/publshr.exe/releases/download/live/VERSION.txt" | sed -n '5p' | tr -d '[:space:]')"

if [[ "$SHELL_TAG" != "$REMOTE_SHELL" ]]; then
    echo "ERROR: AppShellIdentity ($SHELL_TAG) != live VERSION.txt shell ($REMOTE_SHELL)" >&2
    echo "Bump AppShellIdentity.distributionTag and push to main before expecting in-app updates." >&2
    exit 1
fi
echo "OK: shell tag matches live channel ($SHELL_TAG)"

if command -v swift >/dev/null 2>&1; then
    echo
    echo "=== Swift build (host: $(uname -s)-$(uname -m)) ==="
    if [[ "$(uname -s)" == "Darwin" ]]; then
        swift build -c release --product PublshrApp
    else
        swift build -c release --product publshr
    fi
    echo "OK: swift build"
fi

echo
echo "ALL DEPLOYMENT AUDIT CHECKS PASSED"
