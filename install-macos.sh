#!/usr/bin/env bash
# =============================================================================
# Publshr — native macOS desktop IDE (Swift/SwiftUI, NOT a web app)
#
# Canonical install URL:
#   curl -fsSL "https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install-macos.sh" | bash
# =============================================================================
printf '%s\n' '[Publshr] Loading installer...' >&2
set -euo pipefail

INSTALLER_VERSION="9"
PUBLSHR_REPO="${PUBLSHR_REPO:-hiagoccss-svg/publshr.exe}"
PUBLSHR_BRANCH="${PUBLSHR_BRANCH:-main}"
PUBLSHR_INSTALLER_URL="https://raw.githubusercontent.com/${PUBLSHR_REPO}/refs/heads/${PUBLSHR_BRANCH}/install-macos.sh"
PUBLSHR_LIVE_TAG="${PUBLSHR_LIVE_TAG:-live}"
PUBLSHR_MAC_APP="${PUBLSHR_MAC_APP:-/Applications/Publshr.app}"
PUBLSHR_BIN_LINK="${PUBLSHR_BIN_LINK:-/usr/local/bin/publshr}"
PUBLSHR_LIVE_ASSET_MACOS_ARM64="Publshr-macos-aarch64.tar.gz"
PUBLSHR_MIN_APP_BYTES=4000000
PUBLSHR_PREPARED_TREE_FILE="${PUBLSHR_PREPARED_TREE_FILE:-${HOME}/Library/Application Support/Publshr/install-prepared.tree}"

log() { echo "[Publshr] $*" >&2; }

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
    if [[ "$(_publshr_platform)" == "macos" && "$(_publshr_arch)" == "aarch64" ]]; then
        echo "$PUBLSHR_LIVE_ASSET_MACOS_ARM64"
    else
        echo "publshr-live-$(_publshr_platform)-$(_publshr_arch).tar.gz"
    fi
}

_publshr_live_url() {
    echo "https://github.com/${PUBLSHR_REPO}/releases/download/${PUBLSHR_LIVE_TAG}/$(_publshr_live_asset_name)"
}

_publshr_live_exists() {
    local size
    size="$(curl -fsSIL "$(_publshr_live_url)" 2>/dev/null | awk 'tolower($1)=="content-length:" {print $2}' | tr -d '\r' | tail -1)"
    [[ -n "${size:-}" && "$size" -ge "$PUBLSHR_MIN_APP_BYTES" ]]
}

_publshr_tree_has_app() {
    local tree="$1"
    local app_bin="${tree}/Publshr.app/Contents/MacOS/Publshr"
    [[ -n "$tree" && -d "${tree}/Publshr.app" && -f "$app_bin" ]]
}

_publshr_validate_native_app() {
    local tree="$1"
    local exec="${tree}/Publshr.app/Contents/MacOS/Publshr"
    _publshr_tree_has_app "$tree" || return 1
    if [[ -f "${tree}/Publshr.app/Contents/MacOS/PublshrApp" ]]; then
        return 1
    fi
    if [[ -f "${tree}/Publshr.app/Contents/MacOS/publshr" && ! -L "${tree}/Publshr.app/Contents/MacOS/publshr" ]]; then
        return 1
    fi
    if head -1 "$exec" 2>/dev/null | grep -q '^#!'; then
        return 1
    fi
    local size
    size="$(wc -c < "$exec" | tr -d ' ')"
    [[ "$size" -ge 500000 ]]
}

# Fix outdated live releases that shipped PublshrApp instead of Publshr.
_publshr_repair_bundle() {
    local tree="$1"
    local app="${tree}/Publshr.app"
    local macos="${app}/Contents/MacOS"
    local gui="${macos}/Publshr"
    local legacy="${macos}/PublshrApp"

    if _publshr_validate_native_app "$tree"; then
        return 0
    fi

    if [[ ! -f "$legacy" ]]; then
        return 1
    fi

    local size
    size="$(wc -c < "$legacy" | tr -d ' ')"
    if [[ "$size" -lt 500000 ]]; then
        return 1
    fi

    log "Repairing downloaded bundle (PublshrApp → Publshr) …"
    cp "$legacy" "$gui"
    chmod 755 "$gui"
    rm -f "$legacy" "${macos}/publshr"
    xattr -cr "$app" 2>/dev/null || true
    if [[ "$(uname -s)" == "Darwin" ]]; then
        codesign --force --deep --sign - "$app" 2>/dev/null || true
    fi
    _publshr_validate_native_app "$tree"
}

_publshr_find_extract_tree() {
    local tmp="$1" candidate
    for candidate in "$tmp"/*; do
        [[ -d "$candidate" ]] || continue
        candidate="${candidate%/}"
        _publshr_repair_bundle "$candidate" || true
        if _publshr_validate_native_app "$candidate"; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

_publshr_download_live() {
    local url asset tmp tree
    url="$(_publshr_live_url)"
    asset="$(_publshr_live_asset_name)"
    tmp="$(mktemp -d)"
    log "Downloading native desktop build (live channel) …"
    log "  $url"
    curl -fSL --progress-bar "$url" -o "$tmp/$asset"
    tar -xzf "$tmp/$asset" -C "$tmp"
    tree="$(_publshr_find_extract_tree "$tmp")" || tree=""
    if ! _publshr_validate_native_app "$tree"; then
        rm -rf "$tmp"
        return 1
    fi
    echo "$tree"
}

_publshr_build_from_github() {
    local tmp repo ver os arch tree
    command -v git >/dev/null || { log "ERROR: git required. Run: xcode-select --install"; return 1; }
    command -v swift >/dev/null || { log "ERROR: Xcode required. Install from App Store."; return 1; }

    tmp="$(mktemp -d)"
    log "Building native Publshr.app from source (${PUBLSHR_BRANCH}) …"
    log "  First build takes 3–8 minutes (Swift/Xcode)."
    git clone --depth 1 --branch "$PUBLSHR_BRANCH" "https://github.com/${PUBLSHR_REPO}.git" "$tmp/repo"
    repo="$tmp/repo/mac/publshr"
    ver="$(tr -d '[:space:]' < "$repo/VERSION" 2>/dev/null || echo 0.2.0)"
    (
        cd "$repo"
        chmod +x scripts/*.sh
        bash scripts/package-release.sh "$ver"
    )
    os="$(_publshr_platform)"
    arch="$(_publshr_arch)"
    tree="$repo/dist/publshr-${ver}-${os}-${arch}"
    _publshr_repair_bundle "$tree" || true
    if ! _publshr_validate_native_app "$tree"; then
        log "ERROR: Build failed — valid Publshr.app not produced."
        log "  Run: xcode-select -p && swift --version"
        rm -rf "$tmp"
        return 1
    fi
    log "Build succeeded."
    echo "$tree"
}

_publshr_acquire_valid_tree() {
    local tree=""

    if _publshr_live_exists; then
        tree="$(_publshr_download_live)" || tree=""
    fi

    if ! _publshr_validate_native_app "${tree:-}"; then
        log "Live release is missing or outdated — preparing a correct native build …"
        tree="$(_publshr_build_from_github)" || tree=""
    fi

    if _publshr_validate_native_app "${tree:-}"; then
        echo "$tree"
        return 0
    fi
    return 1
}

_publshr_install_app() {
    local tree="$1"
    local app="${tree}/Publshr.app"
    if [[ ! -d "$app" ]]; then
        log "ERROR: Publshr.app missing in $tree"
        exit 1
    fi
    log "Installing to ${PUBLSHR_MAC_APP} …"
    rm -rf "$PUBLSHR_MAC_APP"
    ditto "$app" "$PUBLSHR_MAC_APP"
    chmod -R 755 "$PUBLSHR_MAC_APP"
    xattr -cr "$PUBLSHR_MAC_APP" 2>/dev/null || true
    mkdir -p "$(dirname "$PUBLSHR_BIN_LINK")"
    if [[ -x "$PUBLSHR_MAC_APP/Contents/MacOS/publshr-cli" ]]; then
        ln -sf "$PUBLSHR_MAC_APP/Contents/MacOS/publshr-cli" "$PUBLSHR_BIN_LINK"
    elif [[ -x "$PUBLSHR_MAC_APP/Contents/MacOS/Publshr" ]]; then
        ln -sf "$PUBLSHR_MAC_APP/Contents/MacOS/Publshr" "$PUBLSHR_BIN_LINK"
    fi
    log "Installed."
    log "  App: $PUBLSHR_MAC_APP"
    log "  CLI: $PUBLSHR_BIN_LINK"
}

_publshr_install_with_privileges() {
    local tree="$1"
    if [[ "$(id -u)" -eq 0 ]]; then
        _publshr_install_app "$tree"
        return 0
    fi

    mkdir -p "$(dirname "$PUBLSHR_PREPARED_TREE_FILE")"
    printf '%s\n' "$tree" >"$PUBLSHR_PREPARED_TREE_FILE"

    log ""
    log "Administrator password required (installing to /Applications)."
    if [[ ! -t 0 ]]; then
        log "Enter your Mac password when prompted."
    else
        echo ""
        read -r -p "Press Enter to install to /Applications (Ctrl+C to cancel) … " _
    fi
    log ""

    local sudo_env=(
        "PUBLSHR_REPO=${PUBLSHR_REPO}"
        "PUBLSHR_BRANCH=${PUBLSHR_BRANCH}"
        "PUBLSHR_MAC_APP=${PUBLSHR_MAC_APP}"
        "PUBLSHR_BIN_LINK=${PUBLSHR_BIN_LINK}"
        "PUBLSHR_PREPARED_TREE_FILE=${PUBLSHR_PREPARED_TREE_FILE}"
        "INSTALLER_VERSION=${INSTALLER_VERSION}"
    )

    if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
        exec sudo -E env "${sudo_env[@]}" bash "${BASH_SOURCE[0]}" --install-only
    fi

    exec sudo -E env "${sudo_env[@]}" bash -c \
        'curl -fsSL "$1" | bash -s -- --install-only"' _ "${PUBLSHR_INSTALLER_URL}"
}

_publshr_try_gui_installer() {
    local tree="$1"
    if [[ -d "${tree}/PublshrInstaller.app" ]]; then
        local marker="${HOME}/Library/Application Support/Publshr/install-source.tree"
        mkdir -p "$(dirname "$marker")"
        printf '%s\n' "$tree" >"$marker"
        log "Opening Publshr Installer …"
        open "${tree}/PublshrInstaller.app"
        return 0
    fi
    return 1
}

publshr_install_main() {
    if [[ "$(_publshr_platform)" != "macos" ]]; then
        log "ERROR: This installer is for macOS only."
        exit 1
    fi

    local tree cleanup=""
    tree="$(_publshr_acquire_valid_tree)" || {
        log "ERROR: Could not download, repair, or build a valid Publshr.app."
        exit 1
    }

    if _publshr_try_gui_installer "$tree"; then
        cleanup="$(dirname "$tree")"
        [[ "$cleanup" == /tmp/* || "$cleanup" == /var/folders/* ]] && rm -rf "$cleanup" || true
        exit 0
    fi

    _publshr_install_with_privileges "$tree"
    cleanup="$(dirname "$tree")"
    [[ "$cleanup" == /tmp/* || "$cleanup" == /var/folders/* ]] && rm -rf "$cleanup" || true

    log ""
    log "Launching Publshr …"
    open "$PUBLSHR_MAC_APP" 2>/dev/null || true
}

_publshr_install_only_mode() {
    local tree=""
    if [[ -f "${PUBLSHR_PREPARED_TREE_FILE}" ]]; then
        tree="$(tr -d '\n' < "${PUBLSHR_PREPARED_TREE_FILE}")"
    fi
    if [[ -z "$tree" ]] || ! _publshr_validate_native_app "$tree"; then
        log "ERROR: Prepared install tree missing or invalid."
        exit 1
    fi
    _publshr_install_app "$tree"
    rm -f "${PUBLSHR_PREPARED_TREE_FILE}"
    log "Opening Publshr …"
    open "$PUBLSHR_MAC_APP" 2>/dev/null || true
}

log "Publshr native macOS installer v${INSTALLER_VERSION}"
log "Real Swift/SwiftUI desktop app — not Electron or a browser."
log ""

if [[ "${1:-}" == "--install-only" ]]; then
    _publshr_install_only_mode
else
    publshr_install_main "$@"
fi
