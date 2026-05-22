#!/usr/bin/env bash
# Download livekit-server for macOS into app Resources (local SFU, no cloud).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/../app/resources"
VERSION="${LIVEKIT_VERSION:-2.9.0}"

mkdir -p "$OUT_DIR"

arch="$(uname -m)"
case "$arch" in
  arm64) asset="livekit_${VERSION}_darwin_arm64.tar.gz" ;;
  x86_64) asset="livekit_${VERSION}_darwin_amd64.tar.gz" ;;
  *) echo "Unsupported arch: $arch" >&2; exit 1 ;;
esac

url="https://github.com/livekit/livekit/releases/download/v${VERSION}/${asset}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "Downloading $url …" >&2
curl -fsSL "$url" -o "$tmp/archive.tar.gz"
tar -xzf "$tmp/archive.tar.gz" -C "$tmp"
bin="$(find "$tmp" -name livekit-server -type f | head -1)"
if [[ -z "$bin" ]]; then
  echo "livekit-server not found in archive" >&2
  exit 1
fi

cp "$bin" "$OUT_DIR/livekit-server"
chmod 755 "$OUT_DIR/livekit-server"
echo "Installed $OUT_DIR/livekit-server" >&2
