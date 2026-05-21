#!/usr/bin/env bash
# Build (or download) publshr and install to PREFIX (default: ~/.local/bin).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="${PUBLSHR_VERSION:-0.1.0}"
PREFIX="${PREFIX:-${HOME}/.local/bin}"
REPO="${PUBLSHR_REPO:-hiagoccss-svg/publshr.exe}"

mkdir -p "$PREFIX"

install_binary() {
    local src="$1"
    install -m 755 "$src" "$PREFIX/publshr"
    echo "Installed publshr $VERSION to $PREFIX/publshr"
    "$PREFIX/publshr" --version
}

download_release() {
    local os arch asset url tmp
    case "$(uname -s)" in
        Darwin) os=macos ;;
        Linux) os=linux ;;
        *) echo "Unsupported OS: $(uname -s)" >&2; return 1 ;;
    esac
    case "$(uname -m)" in
        x86_64|amd64) arch=x86_64 ;;
        arm64|aarch64) arch=aarch64 ;;
        *) echo "Unsupported arch: $(uname -m)" >&2; return 1 ;;
    esac
    asset="publshr-${VERSION}-${os}-${arch}.tar.gz"
    url="https://github.com/${REPO}/releases/download/v${VERSION}/${asset}"
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' RETURN
    echo "Downloading $url ..."
    if ! curl -fsSL "$url" -o "$tmp/$asset"; then
        return 1
    fi
    tar -xzf "$tmp/$asset" -C "$tmp"
    install_binary "$tmp/publshr"
}

build_from_source() {
    if ! command -v swift >/dev/null 2>&1; then
        echo "Swift not found. Install from https://www.swift.org/install/ or set PATH to your toolchain." >&2
        return 1
    fi
    echo "Building publshr from source ..."
    (cd "$SCRIPT_DIR" && swift build -c release)
    install_binary "$SCRIPT_DIR/.build/release/publshr"
}

if [[ "${1:-}" == "--download-only" ]]; then
    download_release
    exit 0
fi

if [[ "${1:-}" == "--build-only" ]]; then
    build_from_source
    exit 0
fi

if download_release 2>/dev/null; then
    exit 0
fi

echo "No release binary found; building from source ..."
build_from_source
