#!/usr/bin/env bash
# Download (or build) publshr and install system-wide under /opt/publshr with /usr/local/bin entry.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="${PUBLSHR_VERSION:-0.1.0}"
REPO="${PUBLSHR_REPO:-hiagoccss-svg/publshr.exe}"
INSTALL_ROOT="${PUBLSHR_INSTALL_ROOT:-/opt/publshr}"
BIN_LINK="${PUBLSHR_BIN_LINK:-/usr/local/bin/publshr}"

usage() {
    cat <<EOF
Usage: $0 [options]

Install publshr to $INSTALL_ROOT/$VERSION and $BIN_LINK

Options:
  --download-only   Only download from GitHub releases (fail if missing)
  --build-only      Build from source and install (no download)
  --uninstall       Remove installation
  -h, --help        Show this help

Environment:
  PUBLSHR_VERSION         Release version (default: $VERSION)
  PUBLSHR_INSTALL_ROOT    Install root (default: $INSTALL_ROOT)
  PUBLSHR_BIN_LINK        Symlink/wrapper path (default: $BIN_LINK)
EOF
}

require_root() {
    if [[ "$(id -u)" -ne 0 ]]; then
        exec sudo -E env \
            PUBLSHR_VERSION="$VERSION" \
            PUBLSHR_REPO="$REPO" \
            PUBLSHR_INSTALL_ROOT="$INSTALL_ROOT" \
            PUBLSHR_BIN_LINK="$BIN_LINK" \
            "$0" "$@"
    fi
}

platform_asset() {
    local os arch
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
    echo "publshr-${VERSION}-${os}-${arch}.tar.gz"
}

download_release() {
    local asset url tmp root
    asset="$(platform_asset)"
    url="https://github.com/${REPO}/releases/download/v${VERSION}/${asset}"
    tmp="$(mktemp -d)"
    echo "Downloading $url ..." >&2
    curl -fsSL "$url" -o "$tmp/$asset"
    tar -xzf "$tmp/$asset" -C "$tmp"
    echo "$tmp/$(basename "$asset" .tar.gz)"
}

install_tree() {
    local tree="$1"
    local dest="$INSTALL_ROOT/$VERSION"

    rm -rf "$dest"
    mkdir -p "$INSTALL_ROOT"
    cp -a "$tree" "$dest"
    chmod 755 "$dest/bin/publshr"

    mkdir -p "$(dirname "$BIN_LINK")"
    rm -f "$BIN_LINK"

    if [[ -d "$dest/lib" && -n "$(ls -A "$dest/lib" 2>/dev/null)" ]]; then
        cat >"$BIN_LINK" <<WRAP
#!/usr/bin/env bash
export LD_LIBRARY_PATH="${dest}/lib:\${LD_LIBRARY_PATH:-}"
exec "${dest}/bin/publshr" "\$@"
WRAP
        chmod 755 "$BIN_LINK"
    else
        ln -sf "$dest/bin/publshr" "$BIN_LINK"
    fi

    echo "Installed publshr $VERSION" >&2
    echo "  Application: $dest/bin/publshr" >&2
    echo "  Command:     $BIN_LINK" >&2
    "$BIN_LINK" --version
}

build_tree() {
    if ! command -v swift >/dev/null 2>&1; then
        echo "Swift not found. Install Xcode (macOS) or https://www.swift.org/install/ (Linux)." >&2
        exit 1
    fi
    bash "$SCRIPT_DIR/scripts/package-release.sh" "$VERSION" >&2
    local asset
    asset="$(platform_asset)"
    echo "$SCRIPT_DIR/dist/${asset%.tar.gz}"
}

uninstall() {
    require_root "$@"
    rm -rf "$INSTALL_ROOT/$VERSION"
    rm -f "$BIN_LINK"
    echo "Removed publshr $VERSION from $INSTALL_ROOT and $BIN_LINK"
}

main() {
    case "${1:-}" in
        -h|--help)
            usage
            exit 0
            ;;
        --uninstall)
            uninstall "$@"
            exit 0
            ;;
    esac

    require_root "$@"

    local tree="" cleanup=""
    case "${1:-}" in
        --download-only)
            tree="$(download_release)"
            ;;
        --build-only)
            tree="$(build_tree)"
            ;;
        *)
            if tree="$(download_release)"; then
                echo "Using release download." >&2
            else
                echo "No release found; building from source ..." >&2
                tree="$(build_tree)"
            fi
            ;;
    esac

    cleanup="$(dirname "$tree")"
    install_tree "$tree"
    [[ -d "$cleanup" && "$cleanup" == /tmp/* ]] && rm -rf "$cleanup"
}

main "$@"
