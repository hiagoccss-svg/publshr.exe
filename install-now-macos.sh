#!/usr/bin/env bash
# One-shot install from GitHub live — same validation as install/macos/install-macos.sh
# Usage:
#   curl -fsSL "https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install-now-macos.sh" | bash
set -euo pipefail

PUBLSHR_MAC_APP="${PUBLSHR_MAC_APP:-/Applications/Publshr.app}"
LIVE_URL="https://github.com/hiagoccss-svg/publshr.exe/releases/download/live/Publshr-macos-aarch64.tar.gz"
REPO_ROOT="https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main"

log() { echo "[Publshr] $*" >&2; }

[[ "$(uname -s)" == "Darwin" ]] || { log "macOS only"; exit 1; }

_is_mach_o_gui() {
    local path="$1"
    [[ -f "$path" ]] || return 1
    if command -v file >/dev/null 2>&1; then
        file "$path" | grep -q 'Mach-O' && return 0
    fi
    local size
    size="$(wc -c < "$path" | tr -d ' ')"
    [[ "$size" -ge 500000 ]]
}

_validate_app() {
    local app="$1"
    local exec="${app}/Contents/MacOS/Publshr"
    [[ -f "$exec" ]] || return 1
    [[ ! -f "${app}/Contents/MacOS/PublshrApp" ]] || return 1
    _is_mach_o_gui "$exec" || return 1
    if command -v strings >/dev/null 2>&1; then
        strings "$exec" | grep -q "Welcome to Publshr" && return 1
        strings "$exec" | grep -q "Search files, commands" && return 1
        strings "$exec" | grep -q "Favorites" || return 1
    fi
    return 0
}

_repair_tree() {
    local tree="$1"
    local app="${tree}/Publshr.app"
    local macos="${app}/Contents/MacOS"
    local exec="${macos}/Publshr"
    if _validate_app "$app"; then
        return 0
    fi
    local src=""
    if [[ -f "${macos}/PublshrApp" ]] && _is_mach_o_gui "${macos}/PublshrApp"; then
        src="${macos}/PublshrApp"
    elif [[ -f "${tree}/bin/PublshrApp" ]] && _is_mach_o_gui "${tree}/bin/PublshrApp"; then
        src="${tree}/bin/PublshrApp"
    else
        return 1
    fi
    log "Repairing bundle (native GUI → Contents/MacOS/Publshr) …"
    rm -f "${macos}/PublshrApp" "${macos}/publshr" "${macos}/Publshr" 2>/dev/null || true
    ditto "$src" "$exec"
    chmod 755 "$exec"
    xattr -cr "$app" 2>/dev/null || true
    codesign --force --deep --sign - "$app" 2>/dev/null || true
    _validate_app "$app"
}

log "Downloading live build (no cache) …"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
curl -fsSL "$LIVE_URL" -o "$TMP/app.tar.gz"
tar -xzf "$TMP/app.tar.gz" -C "$TMP"
TREE="$(find "$TMP" -maxdepth 1 -type d -name 'publshr-*' | head -1)"
[[ -n "$TREE" ]] || { log "ERROR: invalid tarball layout"; exit 1; }

_repair_tree "$TREE" || { log "ERROR: live package is not a valid enterprise Publshr build"; exit 1; }

APP="${TREE}/Publshr.app"
BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "${APP}/Contents/Info.plist" 2>/dev/null || echo '?')"
SHELL_VER="$(/usr/libexec/PlistBuddy -c 'Print :PublshrShellVersion' "${APP}/Contents/Info.plist" 2>/dev/null || echo '?')"
log "Verified enterprise build ${BUILD} (shell ${SHELL_VER})"

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

_validate_app "$PUBLSHR_MAC_APP" || { log "ERROR: installed app failed verification"; exit 1; }

INSTALLED_BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "${PUBLSHR_MAC_APP}/Contents/Info.plist")"
log "Installed build ${INSTALLED_BUILD} → ${PUBLSHR_MAC_APP}"
log "Opening Publshr …"
open "$PUBLSHR_MAC_APP"
