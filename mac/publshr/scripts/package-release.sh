#!/usr/bin/env bash
# Build publshr CLI + PublshrApp and pack a release tarball.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib-swift-build-paths.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib-swift-build-paths.sh"
cd "$SCRIPT_DIR"

resolve_version() {
    if [[ -n "${1:-}" ]]; then
        FULL="$1"
    else
        BASE="$(tr -d '[:space:]' < "${SCRIPT_DIR}/VERSION")"
        BUILD="${PUBLSHR_BUILD_NUMBER:-0}"
        FULL="${BASE}.${BUILD}"
    fi
    if [[ "$FULL" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        SHORT="$FULL"
        BUILD_NUM="${PUBLSHR_BUILD_NUMBER:-0}"
    else
        SHORT="${FULL%.*}"
        BUILD_NUM="${FULL##*.}"
    fi
    echo "$FULL $SHORT $BUILD_NUM"
}

read -r VERSION SHORT_VERSION BUILD_NUM <<<"$(resolve_version "${1:-}")"

if ! command -v swift >/dev/null 2>&1; then
    echo "Swift toolchain required. Install from https://www.swift.org/install/" >&2
    exit 1
fi

case "$(uname -s)" in
    Darwin) os=macos ;;
    Linux) os=linux ;;
    *) echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

case "$(uname -m)" in
    x86_64|amd64) arch=x86_64 ;;
    arm64|aarch64) arch=aarch64 ;;
    *) echo "Unsupported arch: $(uname -m)" >&2; exit 1 ;;
esac

echo "Building publshr $VERSION ($os-$arch) ..." >&2

if [[ "$os" == "macos" ]]; then
    bash "$SCRIPT_DIR/scripts/sync-app-icon.sh"
    # Build each product separately — combined --product flags may only link the last one on some SwiftPM versions.
    swift build -c release --product PublshrApp
    swift build -c release --product PublshrInstaller
    swift build -c release --product publshr 2>/dev/null || true
else
    swift build -c release --product publshr
fi

STAGE="$SCRIPT_DIR/dist/publshr-${VERSION}-${os}-${arch}"
rm -rf "$STAGE"
mkdir -p "$STAGE/bin" "$STAGE/lib"

CLI_BIN="$(find_swift_release_binary publshr "$SCRIPT_DIR" 2>/dev/null || true)"
if [[ -n "$CLI_BIN" && -f "$CLI_BIN" ]]; then
    cp "$CLI_BIN" "$STAGE/bin/publshr"
    chmod 755 "$STAGE/bin/publshr"
fi

if [[ "$os" == "macos" ]]; then
    APP_BIN="$(find_swift_release_binary PublshrApp "$SCRIPT_DIR" || true)"
    if [[ ! -f "$APP_BIN" ]]; then
        echo "ERROR: PublshrApp release binary not found under ${SCRIPT_DIR}/.build" >&2
        find "$SCRIPT_DIR/.build" -type f -path '*/release/*' 2>/dev/null | head -20 >&2 || true
        exit 1
    fi
    cp "$APP_BIN" "$STAGE/bin/PublshrApp"
    chmod 755 "$STAGE/bin/PublshrApp"
    bash "$SCRIPT_DIR/scripts/build-macos-app.sh" "$APP_BIN" "$SHORT_VERSION" "$BUILD_NUM" "$STAGE"
    # Never ship duplicate/wrong executables in the bundle (breaks Dock launch).
    rm -f "$STAGE/Publshr.app/Contents/MacOS/PublshrApp"
    # On case-insensitive APFS, publshr and Publshr are the same path — do not rm blindly.
    _bundle_macos="$STAGE/Publshr.app/Contents/MacOS"
    if [[ -f "${_bundle_macos}/publshr" && ! "${_bundle_macos}/publshr" -ef "${_bundle_macos}/Publshr" ]]; then
        rm -f "${_bundle_macos}/publshr"
    fi
    INSTALLER_BIN="$(find_swift_release_binary PublshrInstaller "$SCRIPT_DIR" || true)"
    if [[ -n "$INSTALLER_BIN" && -f "$INSTALLER_BIN" ]]; then
        bash "$SCRIPT_DIR/scripts/build-macos-installer.sh" "$INSTALLER_BIN" "$SHORT_VERSION" "$BUILD_NUM" "$STAGE"
    fi
    if [[ -n "$CLI_BIN" && -f "$CLI_BIN" ]]; then
        cp "$CLI_BIN" "$STAGE/Publshr.app/Contents/MacOS/publshr-cli"
        chmod 755 "$STAGE/Publshr.app/Contents/MacOS/publshr-cli"
        ln -sf publshr-cli "$STAGE/bin/publshr"
    fi
    if [[ "$(uname -s)" == "Darwin" ]]; then
        bash "$SCRIPT_DIR/scripts/verify-macos-app-bundle.sh" "$STAGE/Publshr.app"
    fi
fi

if [[ "$os" == "linux" && -n "$CLI_BIN" && -f "$CLI_BIN" ]]; then
    mapfile -t swift_libs < <(ldd "$CLI_BIN" | awk '/libswift|libdispatch|libBlocksRuntime/ {print $3}' | sort -u)
    for lib in "${swift_libs[@]}"; do
        [[ -n "$lib" && -f "$lib" ]] && cp -L "$lib" "$STAGE/lib/"
    done
fi

OUT="$SCRIPT_DIR/dist/publshr-${VERSION}-${os}-${arch}.tar.gz"
mkdir -p "$SCRIPT_DIR/dist"
tar -czf "$OUT" -C "$SCRIPT_DIR/dist" "publshr-${VERSION}-${os}-${arch}"
echo "Created $OUT" >&2
ls -lh "$OUT" >&2
