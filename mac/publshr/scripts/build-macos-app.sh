#!/usr/bin/env bash
# Wrap the PublshrApp Swift binary in a real macOS .app (Dock icon, double-click launch).
set -euo pipefail

BINARY="${1:?Usage: build-macos-app.sh <path-to-PublshrApp-binary> <short-version> <build> [out-dir]}"
SHORT_VERSION="${2:?short version required}"
BUILD="${3:?build number required}"
OUT_DIR="${4:-.}"
GITHUB_REPO="${PUBLSHR_GITHUB_REPO:-hiagoccss-svg/publshr.exe}"

APP_NAME="Publshr.app"
APP_ROOT="${OUT_DIR}/${APP_NAME}"
MACOS_DIR="${APP_ROOT}/Contents/MacOS"
RES_DIR="${APP_ROOT}/Contents/Resources"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

rm -rf "$APP_ROOT"
mkdir -p "$MACOS_DIR" "$RES_DIR"

# Real GUI executable — CFBundleExecutable must match this filename (no shell wrapper).
cp "$BINARY" "${MACOS_DIR}/Publshr"
chmod 755 "${MACOS_DIR}/Publshr"

sed -e "s#@@SHORT_VERSION@@#${SHORT_VERSION}#g" \
    -e "s#@@BUILD@@#${BUILD}#g" \
    -e "s#@@GITHUB_REPO@@#${GITHUB_REPO}#g" \
    "${SCRIPT_DIR}/../app/Info.plist.template" >"${APP_ROOT}/Contents/Info.plist"

if [[ "$(uname -s)" == "Darwin" ]]; then
    ICON_OUT="${RES_DIR}/AppIcon.icns"
    if [[ -f "${SCRIPT_DIR}/../app/AppIcon.icns" ]]; then
        cp "${SCRIPT_DIR}/../app/AppIcon.icns" "$ICON_OUT"
    else
        chmod +x "${SCRIPT_DIR}/generate-app-icon.swift" 2>/dev/null || true
        swift "${SCRIPT_DIR}/generate-app-icon.swift" "$ICON_OUT" 2>/dev/null || true
    fi
    if [[ -f "$ICON_OUT" ]]; then
        /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "${APP_ROOT}/Contents/Info.plist" 2>/dev/null \
            || /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "${APP_ROOT}/Contents/Info.plist"
    fi
    # Ad-hoc sign so Gatekeeper is less likely to block launch from /Applications.
    codesign --force --deep --sign - "$APP_ROOT" 2>/dev/null || true
fi

cp "${SCRIPT_DIR}/apply-macos-update.sh" "${RES_DIR}/apply-macos-update.sh"
chmod 755 "${RES_DIR}/apply-macos-update.sh"

echo "Built ${APP_ROOT} (${SHORT_VERSION} build ${BUILD})" >&2
