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

fetch_live_version_shell_tag() {
  local url="https://github.com/hiagoccss-svg/publshr.exe/releases/download/live/VERSION.txt"
  local attempt body
  for attempt in 1 2 3 4; do
    body="$(curl -fsSL "$url" 2>/dev/null || true)"
    if [[ -n "$body" ]]; then
      printf '%s' "$body" | sed -n '5p' | tr -d '[:space:]'
      return 0
    fi
    sleep "$attempt"
  done
  echo "ERROR: could not fetch live VERSION.txt after retries" >&2
  return 1
}

REMOTE_SHELL="$(fetch_live_version_shell_tag)"

LOCAL_VER="$(publshr_shell_tag_version "$SHELL_TAG")"
REMOTE_VER="$(publshr_shell_tag_version "$REMOTE_SHELL")"

if [[ "$SHELL_TAG" == "$REMOTE_SHELL" ]]; then
    echo "OK: shell tag matches live channel ($SHELL_TAG)"
elif [[ "$LOCAL_VER" -gt "$REMOTE_VER" ]]; then
    echo "WARN: AppShellIdentity ($SHELL_TAG) is ahead of live ($REMOTE_SHELL)" >&2
    echo "      Expected on PRs until deliver-macos publishes live VERSION.txt after merge." >&2
    echo "OK: shell tag ahead of live (aligns after next live publish)"
elif [[ "$LOCAL_VER" -lt "$REMOTE_VER" ]]; then
    echo "ERROR: AppShellIdentity ($SHELL_TAG) is behind live ($REMOTE_SHELL)" >&2
    echo "Bump AppShellIdentity.distributionTag to match or exceed the live channel." >&2
    exit 1
else
    echo "ERROR: AppShellIdentity ($SHELL_TAG) != live VERSION.txt shell ($REMOTE_SHELL)" >&2
    echo "Bump AppShellIdentity.distributionTag and push to main before expecting in-app updates." >&2
    exit 1
fi

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
