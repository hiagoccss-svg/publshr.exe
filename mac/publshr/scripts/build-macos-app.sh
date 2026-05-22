#!/usr/bin/env bash
# Wrap the PublshrApp binary in Publshr.app for /Applications and Launchpad.
set -euo pipefail

BINARY="${1:?Usage: build-macos-app.sh <path-to-PublshrApp-binary> <short-version> <build> [out-dir]}"
SHORT_VERSION="${2:?short version required}"
BUILD="${3:?build number required}"
OUT_DIR="${4:-.}"
GITHUB_REPO="${PUBLSHR_GITHUB_REPO:-hiagoccss-svg/publshr.exe}"

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
ln -sf Publshr "${MACOS_DIR}/publshr"

sed -e "s#@@SHORT_VERSION@@#${SHORT_VERSION}#g" \
    -e "s#@@BUILD@@#${BUILD}#g" \
    -e "s#@@GITHUB_REPO@@#${GITHUB_REPO}#g" \
    "${SCRIPT_DIR}/../app/Info.plist.template" >"${APP_ROOT}/Contents/Info.plist"

mkdir -p "${APP_ROOT}/Contents/Resources"
cp "${SCRIPT_DIR}/apply-macos-update.sh" "${APP_ROOT}/Contents/Resources/apply-macos-update.sh"
chmod 755 "${APP_ROOT}/Contents/Resources/apply-macos-update.sh"

echo "Built ${APP_ROOT} (${SHORT_VERSION} build ${BUILD})" >&2
