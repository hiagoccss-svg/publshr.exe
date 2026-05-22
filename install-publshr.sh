#!/usr/bin/env bash
# =============================================================================
# Publshr — native macOS desktop IDE (Swift/SwiftUI, NOT a web app)
#
# Always use this exact command:
#   curl -fsSL https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/main/install-publshr.sh | bash
#
# Installs: /Applications/Publshr.app  (real Mac app, Launchpad, offline-capable)
# Updates:  push to GitHub main → app auto-updates from the "live" release
# =============================================================================
set -euo pipefail

INSTALLER_VERSION="3"
PUBLSHR_REPO="${PUBLSHR_REPO:-hiagoccss-svg/publshr.exe}"
PUBLSHR_BRANCH="${PUBLSHR_BRANCH:-main}"
PUBLSHR_LIVE_TAG="${PUBLSHR_LIVE_TAG:-live}"
PUBLSHR_MAC_APP="${PUBLSHR_MAC_APP:-/Applications/Publshr.app}"
PUBLSHR_BIN_LINK="${PUBLSHR_BIN_LINK:-/usr/local/bin/publshr}"
PUBLSHR_LIVE_ASSET_MACOS_ARM64="Publshr-macos-aarch64.tar.gz"
PUBLSHR_MIN_APP_BYTES=4000000

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
    [[ -d "${tree}/Publshr.app/Contents/MacOS/PublshrApp" ]]
}

_publshr_download_live() {
    local url asset tmp tree
    url="$(_publshr_live_url)"
    asset="$(_publshr_live_asset_name)"
    tmp="$(mktemp -d)"
    log "Downloading native desktop build (live channel) ..."
    log "  $url"
    curl -fSL --progress-bar "$url" -o "$tmp/$asset"
    tar -xzf "$tmp/$asset" -C "$tmp"
    tree="$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -1)"
    if ! _publshr_tree_has_app "$tree"; then
        log "ERROR: Downloaded package does not contain Publshr.app"
        rm -rf "$tmp"
        return 1
    fi
    echo "$tree"
}

_publshr_build_from_github() {
    local tmp repo ver os arch tree asset
    command -v git >/dev/null || { log "ERROR: git required. Run: xcode-select --install"; return 1; }
    command -v swift >/dev/null || { log "ERROR: Xcode required. Install from App Store."; return 1; }

    tmp="$(mktemp -d)"
    log "Building native Publshr.app from source (${PUBLSHR_BRANCH}) ..."
    log "  This is a real Swift desktop app — first build takes 3–8 minutes."
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
    if ! _publshr_tree_has_app "$tree"; then
        log "ERROR: Build failed — Publshr.app not produced."
        log "  Check Xcode: xcode-select -p && swift --version"
        rm -rf "$tmp"
        return 1
    fi
    log "Build succeeded."
    echo "$tree"
}

_publshr_install_app() {
    local tree="$1"
    local app="${tree}/Publshr.app"
    if [[ ! -d "$app" ]]; then
        log "ERROR: Publshr.app missing in $tree"
        exit 1
    fi
    log "Installing to ${PUBLSHR_MAC_APP} ..."
    rm -rf "$PUBLSHR_MAC_APP"
    ditto "$app" "$PUBLSHR_MAC_APP"
    chmod -R 755 "$PUBLSHR_MAC_APP"
    xattr -cr "$PUBLSHR_MAC_APP" 2>/dev/null || true
    mkdir -p "$(dirname "$PUBLSHR_BIN_LINK")"
    if [[ -x "$PUBLSHR_MAC_APP/Contents/MacOS/publshr" ]]; then
        ln -sf "$PUBLSHR_MAC_APP/Contents/MacOS/publshr" "$PUBLSHR_BIN_LINK"
    else
        ln -sf "$PUBLSHR_MAC_APP/Contents/MacOS/Publshr" "$PUBLSHR_BIN_LINK"
    fi
    log "Done."
    log "  App:  $PUBLSHR_MAC_APP"
    log "  CLI:  $PUBLSHR_BIN_LINK"
}

_publshr_require_root() {
    [[ "$(id -u)" -eq 0 ]] && return 0
    if [[ ! -t 0 ]]; then
        log ""
        log "Administrator password required (installing to /Applications)."
        log "If nothing seems to happen, enter your Mac password — it may be waiting silently."
        log ""
    else
        echo ""
        read -r -p "Press Enter to install Publshr to /Applications (Ctrl+C to cancel) ... "
    fi
    exec sudo -E \
        PUBLSHR_REPO="$PUBLSHR_REPO" \
        PUBLSHR_BRANCH="$PUBLSHR_BRANCH" \
        PUBLSHR_MAC_APP="$PUBLSHR_MAC_APP" \
        PUBLSHR_BIN_LINK="$PUBLSHR_BIN_LINK" \
        INSTALLER_VERSION="$INSTALLER_VERSION" \
        bash "$0" "$@"
}

publshr_install_main() {
    if [[ "$(_publshr_platform)" != "macos" ]]; then
        log "ERROR: This installer is for macOS native desktop Publshr.app only."
        log "  Linux CLI: use mac/publshr/install.sh from a clone."
        exit 1
    fi

    _publshr_require_root "$@"

    local tree="" cleanup=""
    if _publshr_live_exists; then
        tree="$(_publshr_download_live)" && log "Using pre-built live release."
    else
        log "Live release not published yet — compiling on your Mac ..."
        tree="$(_publshr_build_from_github)"
    fi

    cleanup="$(dirname "$tree")"
    _publshr_install_app "$tree"
    [[ "$cleanup" == /tmp/* ]] && rm -rf "$cleanup" || true

    log ""
    log "Open the desktop app:"
    log "  open \"$PUBLSHR_MAC_APP\""
    open "$PUBLSHR_MAC_APP" 2>/dev/null || true
}

if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
    log "Publshr native macOS desktop installer v${INSTALLER_VERSION}"
    log "Swift/SwiftUI app — not a browser or Electron web app."
    log ""
    publshr_install_main "$@"
fi
