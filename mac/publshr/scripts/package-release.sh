#!/usr/bin/env bash
# Build publshr CLI + PublshrApp and pack a release tarball.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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
    # Desktop delivery: PublshrApp is required; CLI is optional.
    swift build -c release --product PublshrApp
    swift build -c release --product publshr 2>/dev/null || true
else
    swift build -c release --product publshr
fi

STAGE="$SCRIPT_DIR/dist/publshr-${VERSION}-${os}-${arch}"
rm -rf "$STAGE"
mkdir -p "$STAGE/bin" "$STAGE/lib"

if [[ -f "$SCRIPT_DIR/.build/release/publshr" ]]; then
    cp "$SCRIPT_DIR/.build/release/publshr" "$STAGE/bin/publshr"
    chmod 755 "$STAGE/bin/publshr"
fi

if [[ "$os" == "macos" ]]; then
    APP_BIN="$SCRIPT_DIR/.build/release/PublshrApp"
    cp "$APP_BIN" "$STAGE/bin/PublshrApp"
    chmod 755 "$STAGE/bin/PublshrApp"
    bash "$SCRIPT_DIR/scripts/build-macos-app.sh" "$APP_BIN" "$SHORT_VERSION" "$BUILD_NUM" "$STAGE"
    if [[ -f "$SCRIPT_DIR/.build/release/publshr" ]]; then
        rm -f "$STAGE/Publshr.app/Contents/MacOS/publshr"
        cp "$SCRIPT_DIR/.build/release/publshr" "$STAGE/Publshr.app/Contents/MacOS/publshr"
        chmod 755 "$STAGE/Publshr.app/Contents/MacOS/publshr"
    fi
fi

if [[ "$os" == "linux" && -f "$SCRIPT_DIR/.build/release/publshr" ]]; then
    mapfile -t swift_libs < <(ldd "$SCRIPT_DIR/.build/release/publshr" | awk '/libswift|libdispatch|libBlocksRuntime/ {print $3}' | sort -u)
    for lib in "${swift_libs[@]}"; do
        [[ -n "$lib" && -f "$lib" ]] && cp -L "$lib" "$STAGE/lib/"
    done
fi

OUT="$SCRIPT_DIR/dist/publshr-${VERSION}-${os}-${arch}.tar.gz"
mkdir -p "$SCRIPT_DIR/dist"
tar -czf "$OUT" -C "$SCRIPT_DIR/dist" "publshr-${VERSION}-${os}-${arch}"
echo "Created $OUT" >&2
ls -lh "$OUT" >&2
