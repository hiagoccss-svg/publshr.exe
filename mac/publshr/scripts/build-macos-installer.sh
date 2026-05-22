#!/usr/bin/env bash
set -euo pipefail

BINARY="${1:?Usage: build-macos-installer.sh <PublshrInstaller-binary> <short-version> <build> [out-dir]}"
SHORT_VERSION="${2:?}"
BUILD="${3:?}"
OUT_DIR="${4:-.}"

APP_ROOT="${OUT_DIR}/PublshrInstaller.app"
MACOS_DIR="${APP_ROOT}/Contents/MacOS"
RES_DIR="${APP_ROOT}/Contents/Resources"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

rm -rf "$APP_ROOT"
mkdir -p "$MACOS_DIR" "$RES_DIR"

cp "$BINARY" "${MACOS_DIR}/PublshrInstaller"
chmod 755 "${MACOS_DIR}/PublshrInstaller"

sed -e "s#@@SHORT_VERSION@@#${SHORT_VERSION}#g" \
    -e "s#@@BUILD@@#${BUILD}#g" \
    "${SCRIPT_DIR}/../app/Installer-Info.plist.template" >"${APP_ROOT}/Contents/Info.plist"

if [[ "$(uname -s)" == "Darwin" ]]; then
    ICON_OUT="${RES_DIR}/AppIcon.icns"
    if [[ -f "${SCRIPT_DIR}/../app/AppIcon.icns" ]]; then
        cp "${SCRIPT_DIR}/../app/AppIcon.icns" "$ICON_OUT"
    else
        swift "${SCRIPT_DIR}/generate-app-icon.swift" "$ICON_OUT" 2>/dev/null || true
    fi
    if [[ -f "$ICON_OUT" ]]; then
        /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "${APP_ROOT}/Contents/Info.plist" 2>/dev/null \
            || /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "${APP_ROOT}/Contents/Info.plist"
    fi
    codesign --force --deep --sign - "$APP_ROOT" 2>/dev/null || true
fi

echo "Built ${APP_ROOT}" >&2
