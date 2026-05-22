#!/usr/bin/env bash
# One-shot install: repair broken live bundle + copy to /Applications (no CDN cache issues).
# Usage:
#   curl -fsSL "https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install-now-macos.sh" | bash
set -euo pipefail

PUBLSHR_MAC_APP="${PUBLSHR_MAC_APP:-/Applications/Publshr.app}"
LIVE_URL="https://github.com/hiagoccss-svg/publshr.exe/releases/download/live/Publshr-macos-aarch64.tar.gz"

log() { echo "[Publshr] $*" >&2; }

[[ "$(uname -s)" == "Darwin" ]] || { log "macOS only"; exit 1; }

log "Downloading live build …"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
curl -fsSL "$LIVE_URL" -o "$TMP/app.tar.gz"
tar -xzf "$TMP/app.tar.gz" -C "$TMP"
TREE="$(find "$TMP" -maxdepth 1 -type d -name 'publshr-*' | head -1)"
APP="${TREE}/Publshr.app"
MACOS="${APP}/Contents/MacOS"
GUI_SRC=""

if [[ -f "${TREE}/bin/PublshrApp" ]]; then
    GUI_SRC="${TREE}/bin/PublshrApp"
elif [[ -f "${MACOS}/PublshrApp" ]]; then
    GUI_SRC="${MACOS}/PublshrApp"
else
    log "ERROR: No GUI binary in package"
    exit 1
fi

log "Preparing native app bundle …"
rm -f "${MACOS}/PublshrApp" "${MACOS}/publshr" "${MACOS}/Publshr" 2>/dev/null || true
ditto "$GUI_SRC" "${MACOS}/Publshr"
chmod 755 "${MACOS}/Publshr"
xattr -cr "$APP" 2>/dev/null || true
codesign --force --deep --sign - "$APP" 2>/dev/null || true

SIZE="$(wc -c < "${MACOS}/Publshr" | tr -d ' ')"
if [[ "$SIZE" -lt 500000 ]]; then
    log "ERROR: GUI binary too small ($SIZE bytes)"
    exit 1
fi
log "Native GUI ready ($SIZE bytes)"

if [[ "$(id -u)" -ne 0 ]]; then
    log "Installing to /Applications (admin password) …"
    sudo rm -rf "$PUBLSHR_MAC_APP"
    sudo ditto "$APP" "$PUBLSHR_MAC_APP"
    sudo xattr -cr "$PUBLSHR_MAC_APP" 2>/dev/null || true
else
    rm -rf "$PUBLSHR_MAC_APP"
    ditto "$APP" "$PUBLSHR_MAC_APP"
    xattr -cr "$PUBLSHR_MAC_APP" 2>/dev/null || true
fi

log "Done. Opening Publshr …"
open "$PUBLSHR_MAC_APP"
