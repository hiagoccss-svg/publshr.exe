#!/usr/bin/env bash
# Embed LiveKit SPM dynamic frameworks into Publshr.app (SwiftPM does not copy them automatically).
# See https://github.com/apple/swift-package-manager/issues/6069 and livekit/client-sdk-swift#371
set -euo pipefail

APP="${1:?Usage: embed-macos-livekit-frameworks.sh <Publshr.app> [package-root]}"
PKG_ROOT="${2:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
EXEC="${APP}/Contents/MacOS/Publshr"
FW_DIR="${APP}/Contents/Frameworks"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "embed-macos-livekit-frameworks.sh: skipped (not macOS)" >&2
    exit 0
fi

if [[ ! -f "$EXEC" ]]; then
    echo "ERROR: Missing executable at $EXEC" >&2
    exit 1
fi

if ! otool -L "$EXEC" 2>/dev/null | grep -q 'LiveKitWebRTC.framework'; then
    echo "OK: $EXEC does not link LiveKitWebRTC — nothing to embed" >&2
    exit 0
fi

_select_framework_src() {
    local fw_name="$1"
    local arch
    case "$(uname -m)" in
        arm64|aarch64) arch=arm64 ;;
        x86_64) arch=x86_64 ;;
        *) arch="$(uname -m)" ;;
    esac

    mapfile -t _candidates < <(
        find "${PKG_ROOT}/.build" -type d -name "${fw_name}.framework" 2>/dev/null \
            | LC_ALL=C sort -u
    )

    if [[ "${#_candidates[@]}" -eq 0 ]]; then
        return 1
    fi

    local c
    for c in "${_candidates[@]}"; do
        if [[ "$c" == *simulator* || "$c" == *-simulator/* ]]; then
            continue
        fi
        if [[ "$c" == *ios-* || "$c" == *iphoneos* || "$c" == *appletvos* ]]; then
            continue
        fi
        if [[ "$c" == *macos* && "$c" == *"${arch}"* ]]; then
            echo "$c"
            return 0
        fi
    done

    for c in "${_candidates[@]}"; do
        if [[ "$c" == *simulator* || "$c" == *-simulator/* ]]; then
            continue
        fi
        if [[ "$c" == *ios-* || "$c" == *iphoneos* ]]; then
            continue
        fi
        if [[ "$c" == *macos* ]]; then
            echo "$c"
            return 0
        fi
    done

    echo "${_candidates[0]}"
}

_embed_framework() {
    local fw_name="$1"
    local src dest binary_id

    src="$(_select_framework_src "$fw_name" || true)"
    if [[ -z "$src" || ! -d "$src" ]]; then
        echo "ERROR: ${fw_name}.framework not found under ${PKG_ROOT}/.build (run swift build first)" >&2
        return 1
    fi

    mkdir -p "$FW_DIR"
    dest="${FW_DIR}/${fw_name}.framework"
    rm -rf "$dest"
    /usr/bin/ditto "$src" "$dest"

    binary_id="${dest}/${fw_name}"
    if [[ -f "$binary_id" ]]; then
        install_name_tool -id "@rpath/${fw_name}.framework/${fw_name}" "$binary_id" 2>/dev/null || true
    fi

    echo "Embedded ${fw_name}.framework from ${src}" >&2
}

_ensure_rpath() {
    local bin="$1"
    local rpath="@executable_path/../Frameworks"
    if otool -l "$bin" 2>/dev/null | awk '/cmd LC_RPATH/ {getline; print $2}' | grep -qxF "$rpath"; then
        return 0
    fi
    install_name_tool -add_rpath "$rpath" "$bin"
    echo "Added LC_RPATH ${rpath} to $(basename "$bin")" >&2
}

_embed_framework LiveKitWebRTC

# UniFFI may be static-linked; embed when present as a dynamic framework.
if find "${PKG_ROOT}/.build" -type d -name 'LiveKitUniFFI.framework' 2>/dev/null | grep -q .; then
    if otool -L "$EXEC" 2>/dev/null | grep -q 'LiveKitUniFFI.framework'; then
        _embed_framework LiveKitUniFFI || true
    fi
fi

_ensure_rpath "$EXEC"

if [[ ! -f "${FW_DIR}/LiveKitWebRTC.framework/LiveKitWebRTC" ]]; then
    echo "ERROR: LiveKitWebRTC.framework missing after embed" >&2
    exit 1
fi

echo "OK: LiveKit frameworks embedded in ${APP}" >&2
