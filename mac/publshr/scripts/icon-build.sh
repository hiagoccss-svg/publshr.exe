#!/usr/bin/env bash
# Build AppIcon.icns from mac/publshr/app/icon.png (macOS only).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${SCRIPT_DIR}/../app"
OUT="${1:?output .icns path}"

bash "${SCRIPT_DIR}/sync-app-icon.sh"
SOURCE="${APP_DIR}/icon.png"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "icon-build: skip on non-macOS (CI on macos-14 generates icons)" >&2
    exit 0
fi

chmod +x "${SCRIPT_DIR}/generate-app-icon.swift" 2>/dev/null || true

if [[ -f "$SOURCE" ]]; then
    swift "${SCRIPT_DIR}/generate-app-icon.swift" "$OUT" "$SOURCE"
elif [[ -f "${APP_DIR}/AppIcon.icns" ]]; then
    cp "${APP_DIR}/AppIcon.icns" "$OUT"
else
    swift "${SCRIPT_DIR}/generate-app-icon.swift" "$OUT"
fi
