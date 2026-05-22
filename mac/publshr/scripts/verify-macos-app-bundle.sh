#!/usr/bin/env bash
# Fail CI/install if Publshr.app is not a real native GUI bundle.
set -euo pipefail

APP="${1:?Usage: verify-macos-app-bundle.sh <path-to-Publshr.app>}"

EXEC="${APP}/Contents/MacOS/Publshr"
PLIST="${APP}/Contents/Info.plist"
MIN_BYTES=500000

if [[ ! -f "$PLIST" ]]; then
    echo "ERROR: Missing Info.plist in $APP" >&2
    exit 1
fi

BUNDLE_EXEC="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$PLIST" 2>/dev/null || true)"
if [[ "$BUNDLE_EXEC" != "Publshr" ]]; then
    echo "ERROR: CFBundleExecutable must be Publshr (got: ${BUNDLE_EXEC:-<unset>})" >&2
    exit 1
fi

if [[ ! -f "$EXEC" ]]; then
    echo "ERROR: Missing GUI binary at $EXEC" >&2
    ls -la "${APP}/Contents/MacOS/" 2>/dev/null >&2 || true
    exit 1
fi

if [[ -f "${APP}/Contents/MacOS/PublshrApp" ]]; then
    echo "ERROR: Stale PublshrApp binary must not ship in MacOS/ (use Publshr only)" >&2
    exit 1
fi

if [[ -f "${APP}/Contents/MacOS/publshr" && ! -L "${APP}/Contents/MacOS/publshr" ]]; then
    if [[ ! -f "${APP}/Contents/MacOS/Publshr" ]] || ! [[ "${APP}/Contents/MacOS/publshr" -ef "${APP}/Contents/MacOS/Publshr" ]]; then
        echo "ERROR: CLI binary must not be named publshr in MacOS/ (use publshr-cli)" >&2
        exit 1
    fi
fi

if head -1 "$EXEC" 2>/dev/null | grep -q '^#!'; then
    echo "ERROR: CFBundleExecutable must be Mach-O, not a shell script: $EXEC" >&2
    exit 1
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
    FILE_INFO="$(file "$EXEC")"
    if ! grep -q 'Mach-O' <<<"$FILE_INFO"; then
        echo "ERROR: $EXEC is not Mach-O: $FILE_INFO" >&2
        exit 1
    fi
fi

SIZE="$(wc -c < "$EXEC" | tr -d ' ')"
if [[ "$SIZE" -lt "$MIN_BYTES" ]]; then
    echo "ERROR: $EXEC too small ($SIZE bytes) — expected native GUI app (>= $MIN_BYTES)" >&2
    exit 1
fi

_binary_contains() {
    grep -aq "$1" "$EXEC" 2>/dev/null
}

if _binary_contains "Welcome to Publshr"; then
    echo "ERROR: Binary still contains fake IDE Welcome screen — wrong build" >&2
    exit 1
fi
if _binary_contains "Search files, commands"; then
    echo "ERROR: Binary still contains fake IDE file search bar — wrong build" >&2
    exit 1
fi
if _binary_contains "EXPLORER"; then
    echo "ERROR: Binary still contains fake Explorer sidebar — wrong build" >&2
    exit 1
fi
if ! _binary_contains "PublshrEnterpriseShell-8"; then
    echo "ERROR: Binary missing enterprise shell marker (PublshrEnterpriseShell-8) — wrong build" >&2
    exit 1
fi

ICON="${APP}/Contents/Resources/AppIcon.icns"
if [[ ! -f "$ICON" ]]; then
    echo "ERROR: Missing AppIcon.icns in bundle (icon updates require a full live rebuild)" >&2
    exit 1
fi

UPDATE_SH="${APP}/Contents/Resources/apply-macos-update.sh"
if [[ ! -f "$UPDATE_SH" ]]; then
    echo "ERROR: Missing apply-macos-update.sh in Resources (in-place live updates will fail)" >&2
    exit 1
fi

if _binary_contains "LiveKitWebRTC.framework"; then
    LK_FW="${APP}/Contents/Frameworks/LiveKitWebRTC.framework/LiveKitWebRTC"
    if [[ ! -f "$LK_FW" ]]; then
        echo "ERROR: Binary links LiveKitWebRTC but ${LK_FW} is missing (dyld crash at launch)" >&2
        exit 1
    fi
    if [[ "$(uname -s)" == "Darwin" ]]; then
        if ! otool -l "$EXEC" 2>/dev/null | awk '/cmd LC_RPATH/ {getline; print $2}' | grep -qxF '@executable_path/../Frameworks'; then
            echo "ERROR: Missing @executable_path/../Frameworks LC_RPATH on Publshr binary" >&2
            exit 1
        fi
    fi
fi

echo "OK: $APP — native GUI Publshr ($SIZE bytes)" >&2
