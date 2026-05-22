#!/usr/bin/env bash
# Copy repository-root icon.png into mac/publshr/app/ before macOS packaging.
# GitHub uploads often land at the repo root; builds read mac/publshr/app/icon.png.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ROOT_ICON="$REPO_ROOT/icon.png"
APP_ICON="${SCRIPT_DIR}/../app/icon.png"

if [[ ! -f "$ROOT_ICON" ]]; then
    exit 0
fi

if [[ ! -f "$APP_ICON" ]] || ! cmp -s "$ROOT_ICON" "$APP_ICON"; then
    mkdir -p "$(dirname "$APP_ICON")"
    cp "$ROOT_ICON" "$APP_ICON"
    echo "sync-app-icon: $ROOT_ICON → $APP_ICON" >&2
fi
