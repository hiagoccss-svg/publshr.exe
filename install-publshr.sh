#!/usr/bin/env bash
# Publshr — stable macOS installer (single file, never changes URL).
#   curl -fsSL https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/main/install-publshr.sh | bash
#
# Live app updates: push to `main` → GitHub Actions publishes the `live` release
# → installed Publshr.app downloads and applies it automatically.
set -euo pipefail

# --- configuration (stable) ---
PUBLSHR_REPO="${PUBLSHR_REPO:-hiagoccss-svg/publshr.exe}"
PUBLSHR_BRANCH="${PUBLSHR_BRANCH:-main}"
PUBLSHR_LIVE_TAG="${PUBLSHR_LIVE_TAG:-live}"
PUBLSHR_MAC_APP="${PUBLSHR_MAC_APP:-/Applications/Publshr.app}"
PUBLSHR_BIN_LINK="${PUBLSHR_BIN_LINK:-/usr/local/bin/publshr}"
PUBLSHR_INSTALL_ROOT="${PUBLSHR_INSTALL_ROOT:-/opt/publshr}"
# Fixed release asset names (updated in-place on every push to main)
PUBLSHR_LIVE_ASSET_MACOS_ARM64="Publshr-macos-aarch64.tar.gz"
PUBLSHR_LIVE_ASSET_MACOS_X64="Publshr-macos-x86_64.tar.gz"
PUBLSHR_MIN_APP_BYTES=5000000

_publshr_platform() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux) echo "linux" ;;
        *) echo "unsupported" ;;
    esac
}

_publshr_arch() {
    case "$(uname -m)" in
        x86_64|amd64) echo "x86_64" ;;
        arm64|aarch64) echo "aarch64" ;;
        *) echo "unsupported" ;;
    esac
}

_publshr_live_asset_name() {
    local os arch
    os="$(_publshr_platform)"
    arch="$(_publshr_arch)"
    if [[ "$os" == "macos" && "$arch" == "aarch64" ]]; then
        echo "$PUBLSHR_LIVE_ASSET_MACOS_ARM64"
    elif [[ "$os" == "macos" && "$arch" == "x86_64" ]]; then
        echo "$PUBLSHR_LIVE_ASSET_MACOS_X64"
    else
        echo "publshr-live-${os}-${arch}.tar.gz"
    fi
}

_publshr_live_download_url() {
    local asset
    asset="$(_publshr_live_asset_name)"
    echo "https://github.com/${PUBLSHR_REPO}/releases/download/${PUBLSHR_LIVE_TAG}/${asset}"
}

_publshr_live_release_size() {
    local url size
    url="$(_publshr_live_download_url)"
    size="$(curl -fsSIL "$url" 2>/dev/null | awk 'tolower($1)=="content-length:" {print $2}' | tr -d '\r' | tail -1)"
    [[ -n "${size:-}" ]] || return 1
    echo "$size"
}

_publshr_tree_has_mac_app() {
    local tree="$1"
    [[ -d "${tree}/Publshr.app" ]] || [[ -f "${tree}/bin/PublshrApp" ]]
}

_publshr_download_live_tree() {
    local url asset tmp tree size
    url="$(_publshr_live_download_url)"
    asset="$(_publshr_live_asset_name)"
    size="$(_publshr_live_release_size 2>/dev/null || echo 0)"
    if [[ "${size:-0}" -lt "$PUBLSHR_MIN_APP_BYTES" ]]; then
        return 1
    fi
    tmp="$(mktemp -d)"
    echo "Downloading live build from GitHub ..." >&2
    echo "  $url" >&2
    if ! curl -fsSL "$url" -o "$tmp/$asset"; then
        rm -rf "$tmp"
        return 1
    fi
    if ! tar -xzf "$tmp/$asset" -C "$tmp"; then
        rm -rf "$tmp"
        return 1
    fi
    tree="$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -1)"
    if [[ -z "$tree" ]] || ! _publshr_tree_has_mac_app "$tree"; then
        echo "Live release is missing Publshr.app." >&2
        rm -rf "$tmp"
        return 1
    fi
    echo "$tree"
}

_publshr_clone_and_build() {
    if ! command -v git >/dev/null 2>&1; then
        echo "Install Xcode Command Line Tools: xcode-select --install" >&2
        return 1
    fi
    if ! command -v swift >/dev/null 2>&1; then
        echo "Install Xcode from the App Store, then retry." >&2
        return 1
    fi

    local tmp repo_dir ver
    tmp="$(mktemp -d)"
    echo "Building Publshr from GitHub (${PUBLSHR_BRANCH}) ..." >&2
    if ! git clone --depth 1 --branch "$PUBLSHR_BRANCH" "https://github.com/${PUBLSHR_REPO}.git" "$tmp/repo"; then
        rm -rf "$tmp"
        return 1
    fi
    repo_dir="$tmp/repo/mac/publshr"
    if [[ ! -f "$repo_dir/Package.swift" ]]; then
        echo "mac/publshr missing in repository." >&2
        rm -rf "$tmp"
        return 1
    fi
    ver="0.2.0"
    [[ -f "$repo_dir/VERSION" ]] && ver="$(tr -d '[:space:]' < "$repo_dir/VERSION")"
    (
        cd "$repo_dir"
        chmod +x scripts/*.sh 2>/dev/null || true
        bash scripts/package-release.sh "$ver"
    )
    local os arch asset tree
    os="$(_publshr_platform)"
    arch="$(_publshr_arch)"
    asset="publshr-${ver}-${os}-${arch}.tar.gz"
    tree="$repo_dir/dist/${asset%.tar.gz}"
    if ! _publshr_tree_has_mac_app "$tree"; then
        echo "Source build did not produce Publshr.app at $tree" >&2
        rm -rf "$tmp"
        return 1
    fi
    echo "$tree"
}

_publshr_install_macos_app() {
    local tree="$1"
    local app_src="${tree}/Publshr.app"
    if [[ ! -d "$app_src" ]]; then
        local app_bin="${tree}/bin/PublshrApp"
        if [[ ! -f "$app_bin" ]]; then
            echo "Publshr.app not found in install package." >&2
            exit 1
        fi
        local script_dir ver short build
        script_dir="$(dirname "$app_bin")/../../.."  # best-effort; use repo scripts if present
        if [[ -f "${tree}/../scripts/build-macos-app.sh" ]]; then
            script_dir="$(cd "${tree}/../scripts" && pwd)"
        elif [[ -f "$tree/../../scripts/build-macos-app.sh" ]]; then
            script_dir="$(cd "$tree/../../scripts" && pwd)"
        else
            script_dir=""
        fi
        ver="${PUBLSHR_VERSION:-0.2.0}"
        short="$ver"
        build="0"
        if [[ -n "$script_dir" && -x "$script_dir/build-macos-app.sh" ]]; then
            bash "$script_dir/build-macos-app.sh" "$app_bin" "$short" "$build" "$tree"
        else
            echo "Cannot wrap PublshrApp without build scripts." >&2
            exit 1
        fi
        app_src="${tree}/Publshr.app"
    fi
    rm -rf "$PUBLSHR_MAC_APP"
    ditto "$app_src" "$PUBLSHR_MAC_APP"
    chmod -R 755 "$PUBLSHR_MAC_APP"
    /usr/bin/touch "$PUBLSHR_MAC_APP"
    xattr -cr "$PUBLSHR_MAC_APP" 2>/dev/null || true
    mkdir -p "$(dirname "$PUBLSHR_BIN_LINK")"
    rm -f "$PUBLSHR_BIN_LINK"
    ln -sf "$PUBLSHR_MAC_APP/Contents/MacOS/publshr" "$PUBLSHR_BIN_LINK"
    echo "" >&2
    echo "Installed Publshr → $PUBLSHR_MAC_APP" >&2
    echo "  Open from Launchpad or: open \"$PUBLSHR_MAC_APP\"" >&2
    echo "  Pushes to GitHub main update this app automatically." >&2
}

_publshr_install_linux() {
    local tree="$1" dest="${PUBLSHR_INSTALL_ROOT}/${PUBLSHR_VERSION:-live}"
    rm -rf "$dest"
    mkdir -p "$PUBLSHR_INSTALL_ROOT"
    cp -a "$tree" "$dest"
    chmod 755 "$dest/bin/publshr"
    mkdir -p "$(dirname "$PUBLSHR_BIN_LINK")"
    rm -f "$PUBLSHR_BIN_LINK"
    if [[ -d "$dest/lib" && -n "$(ls -A "$dest/lib" 2>/dev/null)" ]]; then
        printf '%s\n' '#!/usr/bin/env bash' "export LD_LIBRARY_PATH=\"${dest}/lib:\${LD_LIBRARY_PATH:-}\"" "exec \"${dest}/bin/publshr\" \"\$@\"" >"$PUBLSHR_BIN_LINK"
        chmod 755 "$PUBLSHR_BIN_LINK"
    else
        ln -sf "$dest/bin/publshr" "$PUBLSHR_BIN_LINK"
    fi
    echo "Installed publshr → $PUBLSHR_BIN_LINK" >&2
}

_publshr_confirm() {
    [[ "$(uname -s)" != "Darwin" ]] && return 0
    [[ ! -t 0 ]] && return 0
    echo ""
    echo "Install Publshr to $PUBLSHR_MAC_APP ?"
    read -r -p "Press Enter to continue (Ctrl+C to cancel) ... " _
}

_publshr_require_root() {
    [[ "$(id -u)" -eq 0 ]] && return 0
    _publshr_confirm
    exec sudo -E \
        PUBLSHR_REPO="$PUBLSHR_REPO" \
        PUBLSHR_BRANCH="$PUBLSHR_BRANCH" \
        PUBLSHR_MAC_APP="$PUBLSHR_MAC_APP" \
        PUBLSHR_BIN_LINK="$PUBLSHR_BIN_LINK" \
        bash "$0" "$@"
}

publshr_install_main() {
    case "${1:-}" in
        -h|--help)
            cat <<EOF
Publshr installer (stable URL)

  curl -fsSL https://raw.githubusercontent.com/${PUBLSHR_REPO}/main/install-publshr.sh | bash

Environment:
  PUBLSHR_REPO, PUBLSHR_BRANCH, PUBLSHR_MAC_APP, PUBLSHR_BIN_LINK
EOF
            exit 0
            ;;
        --uninstall)
            _publshr_require_root "$@"
            rm -rf "$PUBLSHR_MAC_APP" "$PUBLSHR_BIN_LINK"
            echo "Removed Publshr."
            exit 0
            ;;
    esac

    if [[ "$(_publshr_platform)" == "unsupported" ]]; then
        echo "Unsupported operating system." >&2
        exit 1
    fi

    _publshr_require_root "$@"

    local tree="" cleanup=""
    if tree="$(_publshr_download_live_tree)"; then
        echo "Installed from GitHub live channel (${PUBLSHR_LIVE_TAG})." >&2
    elif tree="$(_publshr_clone_and_build)"; then
        echo "Installed from source build (${PUBLSHR_BRANCH})." >&2
    else
        echo "Install failed." >&2
        echo "  • Wait for GitHub Actions to publish the live release (after push to main), or" >&2
        echo "  • Install Xcode and retry so we can compile locally." >&2
        exit 1
    fi

    cleanup="$(dirname "$tree")"
    if [[ "$(_publshr_platform)" == "macos" ]]; then
        _publshr_install_macos_app "$tree"
    else
        _publshr_install_linux "$tree"
    fi
    [[ -d "$cleanup" && "$cleanup" == /tmp/* ]] && rm -rf "$cleanup" || true
}

# Only run when executed directly (mac/publshr/install.sh sources this file).
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
    if [[ "$(uname -s)" == "Darwin" ]]; then
        echo ""
        echo "Publshr installer"
        echo "  Repo:  ${PUBLSHR_REPO} @ ${PUBLSHR_BRANCH}"
        echo "  Live:  releases/tag/${PUBLSHR_LIVE_TAG}"
        echo ""
    fi
    publshr_install_main "$@"
fi
