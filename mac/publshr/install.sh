#!/usr/bin/env bash
# Download (or build) publshr and install to /Applications (macOS) or /opt (Linux).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="${PUBLSHR_VERSION:-0.1.0}"
REPO="${PUBLSHR_REPO:-hiagoccss-svg/publshr.exe}"
INSTALL_ROOT="${PUBLSHR_INSTALL_ROOT:-/opt/publshr}"
BIN_LINK="${PUBLSHR_BIN_LINK:-/usr/local/bin/publshr}"
MAC_APP="${PUBLSHR_MAC_APP:-/Applications/Publshr.app}"

usage() {
    cat <<EOF
Usage: $0 [options]

macOS: installs Publshr.app to $MAC_APP (shows in Applications / Launchpad)
       and publshr command at $BIN_LINK

Linux: installs to $INSTALL_ROOT/$VERSION and $BIN_LINK

Options:
  --download-only   Only download from GitHub releases (fail if missing)
  --build-only      Build from source and install (no download)
  --uninstall       Remove installation
  -h, --help        Show this help
EOF
}

confirm_install() {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        return 0
    fi
    if [[ ! -t 0 ]]; then
        return 0
    fi
    echo ""
    echo "Publshr will be installed to:"
    echo "  • Applications: $MAC_APP  (find it in Launchpad / Finder → Applications)"
    echo "  • Terminal command: $BIN_LINK"
    echo ""
    echo "macOS will ask for your administrator password next."
    read -r -p "Press Enter to install, or Ctrl+C to cancel... " _
}

require_root() {
    if [[ "$(id -u)" -ne 0 ]]; then
        confirm_install
        exec sudo -E env \
            PUBLSHR_VERSION="$VERSION" \
            PUBLSHR_REPO="$REPO" \
            PUBLSHR_INSTALL_ROOT="$INSTALL_ROOT" \
            PUBLSHR_BIN_LINK="$BIN_LINK" \
            PUBLSHR_MAC_APP="$MAC_APP" \
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
    local asset url tmp
    asset="$(platform_asset)"
    url="https://github.com/${REPO}/releases/download/v${VERSION}/${asset}"
    tmp="$(mktemp -d)"
    echo "Downloading $url ..." >&2
    curl -fsSL "$url" -o "$tmp/$asset"
    tar -xzf "$tmp/$asset" -C "$tmp"
    echo "$tmp/$(basename "$asset" .tar.gz)"
}

install_macos_app() {
    local tree="$1"
    local app_src="${tree}/Publshr.app"

    if [[ ! -d "$app_src" ]]; then
        echo "Building Publshr.app from binary ..." >&2
        bash "$SCRIPT_DIR/scripts/build-macos-app.sh" "${tree}/bin/publshr" "$VERSION" "$tree"
        app_src="${tree}/Publshr.app"
    fi

    rm -rf "$MAC_APP"
    cp -a "$app_src" "$MAC_APP"
    chmod -R 755 "$MAC_APP"
    /usr/bin/touch "$MAC_APP"

    mkdir -p "$(dirname "$BIN_LINK")"
    rm -f "$BIN_LINK"
    ln -sf "$MAC_APP/Contents/MacOS/publshr-bin" "$BIN_LINK"

    echo "" >&2
    echo "Installed Publshr $VERSION" >&2
    echo "  App (Launchpad / Applications): $MAC_APP" >&2
    echo "  Terminal command:               $BIN_LINK" >&2
    echo "" >&2
    echo "Open Finder → Applications → Publshr, or run: publshr --help" >&2
    "$BIN_LINK" --version
}

install_linux_tree() {
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

install_tree() {
    local tree="$1"
    if [[ "$(uname -s)" == "Darwin" ]]; then
        install_macos_app "$tree"
    else
        install_linux_tree "$tree"
    fi
}

build_tree() {
    if ! command -v swift >/dev/null 2>&1; then
        echo "Swift not found. Install Xcode from the App Store, then run: xcode-select --install" >&2
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
    rm -rf "$MAC_APP"
    echo "Removed Publshr $VERSION"
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
