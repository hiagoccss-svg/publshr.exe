#!/usr/bin/env bash
# Wrap the PublshrApp binary in Publshr.app for /Applications and Launchpad.
set -euo pipefail

BINARY="${1:?Usage: build-macos-app.sh <path-to-PublshrApp-binary> <version>}"
VERSION="${2:?version required}"
OUT_DIR="${3:-.}"

APP_NAME="Publshr.app"
APP_ROOT="${OUT_DIR}/${APP_NAME}"
MACOS_DIR="${APP_ROOT}/Contents/MacOS"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

rm -rf "$APP_ROOT"
mkdir -p "$MACOS_DIR"

cp "$BINARY" "${MACOS_DIR}/PublshrApp"
chmod 755 "${MACOS_DIR}/PublshrApp"

cat >"${MACOS_DIR}/Publshr" <<'LAUNCHER'
#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
exec "${DIR}/PublshrApp" "$@"
LAUNCHER
chmod 755 "${MACOS_DIR}/Publshr"

sed "s/@@VERSION@@/${VERSION}/g" "${SCRIPT_DIR}/../app/Info.plist.template" >"${APP_ROOT}/Contents/Info.plist"

echo "Built ${APP_ROOT}" >&2
