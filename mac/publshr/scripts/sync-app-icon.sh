#!/usr/bin/env bash
# Single source of truth: repository-root icon.png → mac/publshr/app/icon.png (white bg, 1024).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ROOT_ICON="$REPO_ROOT/icon.png"
APP_ICON="${SCRIPT_DIR}/../app/icon.png"

if [[ ! -f "$ROOT_ICON" ]]; then
    echo "sync-app-icon: no $ROOT_ICON (upload icon.png at repo root)" >&2
    exit 0
fi

normalize_icon() {
    if command -v python3 >/dev/null 2>&1 && python3 -c "import PIL" 2>/dev/null; then
        python3 "${SCRIPT_DIR}/apply-premium-icon-background.py"
        return
    fi
    if [[ "$(uname -s)" == "Darwin" ]] && command -v swift >/dev/null 2>&1; then
        mkdir -p "$(dirname "$APP_ICON")"
        swift "${SCRIPT_DIR}/normalize-brand-icon.swift" "$ROOT_ICON" "$APP_ICON" 1024
        return
    fi
    mkdir -p "$(dirname "$APP_ICON")"
    cp "$ROOT_ICON" "$APP_ICON"
    echo "sync-app-icon: copied $ROOT_ICON → $APP_ICON (install python3+Pillow or use macOS for white-background normalize)" >&2
}

normalize_icon

# Remove legacy duplicate; in-app UI uses icon.png from the bundle.
rm -f "${SCRIPT_DIR}/../app/logo.png" "$REPO_ROOT/logo.png"
