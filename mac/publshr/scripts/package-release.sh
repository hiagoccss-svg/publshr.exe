#!/usr/bin/env bash
# Build publshr and pack a self-contained release tarball (bin + Swift runtime libs).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-0.1.0}"
cd "$SCRIPT_DIR"

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
swift build -c release

BIN="$SCRIPT_DIR/.build/release/publshr"
STAGE="$SCRIPT_DIR/dist/publshr-${VERSION}-${os}-${arch}"
rm -rf "$STAGE"
mkdir -p "$STAGE/bin" "$STAGE/lib"

cp "$BIN" "$STAGE/bin/publshr"
chmod 755 "$STAGE/bin/publshr"

if [[ "$os" == "linux" ]]; then
    mapfile -t swift_libs < <(ldd "$BIN" | awk '/libswift|libdispatch|libBlocksRuntime/ {print $3}' | sort -u)
    for lib in "${swift_libs[@]}"; do
        [[ -n "$lib" && -f "$lib" ]] && cp -L "$lib" "$STAGE/lib/"
    done
fi

OUT="$SCRIPT_DIR/dist/publshr-${VERSION}-${os}-${arch}.tar.gz"
mkdir -p "$SCRIPT_DIR/dist"
tar -czf "$OUT" -C "$SCRIPT_DIR/dist" "publshr-${VERSION}-${os}-${arch}"
echo "Created $OUT" >&2
ls -lh "$OUT" >&2
