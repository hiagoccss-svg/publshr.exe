#!/usr/bin/env bash
# =============================================================================
# Publshr — native macOS desktop IDE (Swift/SwiftUI, NOT a web app)
#
# Canonical install URL:
#   curl -fsSL "https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install-macos.sh" | bash
# =============================================================================
printf '%s\n' '[Publshr] Loading installer...' >&2
set -euo pipefail

INSTALLER_VERSION="12"
PUBLSHR_REPO="${PUBLSHR_REPO:-hiagoccss-svg/publshr.exe}"
PUBLSHR_BRANCH="${PUBLSHR_BRANCH:-main}"
PUBLSHR_INSTALLER_URL="https://raw.githubusercontent.com/${PUBLSHR_REPO}/refs/heads/${PUBLSHR_BRANCH}/install-macos.sh"
PUBLSHR_LIVE_TAG="${PUBLSHR_LIVE_TAG:-live}"
# Enterprise default: user-owned install only (passwordless live updates). Ignore system /Applications overrides.
PUBLSHR_MAC_APP="${HOME}/Applications/Publshr.app"
# Default CLI symlink: user-writable (no sudo). Override with PUBLSHR_BIN_LINK if needed.
PUBLSHR_BIN_LINK="${PUBLSHR_BIN_LINK:-${HOME}/bin/publshr}"
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

_publshr_is_mach_o_gui() {
    local path="$1"
    [[ -f "$path" ]] || return 1
    if [[ "$(uname -s)" == "Darwin" ]] && command -v file >/dev/null 2>&1; then
        file "$path" | grep -q 'Mach-O' && return 0
    fi
    local size
    size="$(wc -c < "$path" | tr -d ' ')"
    [[ "$size" -ge 500000 ]]
}

_publshr_validate_native_app() {
    local tree="$1"
    local macos="${tree}/Publshr.app/Contents/MacOS"
    local exec="${macos}/Publshr"
    [[ -d "${tree}/Publshr.app" ]] || return 1
    # Stale duplicate GUI binary from broken releases.
    [[ -f "${macos}/PublshrApp" ]] && return 1
    # Do NOT test for MacOS/publshr separately — on case-insensitive APFS it is the
    # same inode as Publshr and would falsely fail after a successful repair.
    _publshr_is_mach_o_gui "$exec"
}

# Fix outdated live releases that shipped PublshrApp instead of Publshr.
_publshr_repair_bundle() {
    local tree="$1"
    local app="${tree}/Publshr.app"
    local macos="${app}/Contents/MacOS"
    local gui="${macos}/Publshr"
    local legacy="${macos}/PublshrApp"
    local bin_gui="${tree}/bin/PublshrApp"
    local src=""

    if _publshr_validate_native_app "$tree"; then
        return 0
    fi

    if [[ -f "$legacy" ]] && _publshr_is_mach_o_gui "$legacy"; then
        src="$legacy"
    elif [[ -f "$bin_gui" ]] && _publshr_is_mach_o_gui "$bin_gui"; then
        src="$bin_gui"
    else
        return 1
    fi

    log "Repairing downloaded bundle (installing native GUI as Contents/MacOS/Publshr) …"
    rm -f "$legacy" "${macos}/publshr" "${macos}/Publshr" 2>/dev/null || true
    ditto "$src" "${macos}/Publshr"
    chmod 755 "${macos}/Publshr"
    xattr -cr "$app" 2>/dev/null || true
    if [[ "$(uname -s)" == "Darwin" ]]; then
        codesign --force --deep --sign - "$app" 2>/dev/null || true
    fi
    if _publshr_validate_native_app "$tree"; then
        log "Bundle repaired successfully."
        return 0
    fi
    return 1
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
    local build_log="${tmp}/build.log"
    if ! (
        cd "$repo"
        chmod +x scripts/*.sh scripts/lib-swift-build-paths.sh 2>/dev/null || true
        bash scripts/package-release.sh "$ver"
    ) >"$build_log" 2>&1; then
        log "ERROR: package-release.sh failed. Last lines:"
        tail -40 "$build_log" >&2 || true
        rm -rf "$tmp"
        return 1
    fi
    tree="$(find "$repo/dist" -maxdepth 1 -type d -name 'publshr-*-macos-aarch64' 2>/dev/null | tail -1)"
    if ! _publshr_validate_native_app "$tree"; then
        log "ERROR: Build failed — valid Publshr.app not produced."
        log "  Run: xcode-select -p && swift --version"
        tail -20 "$build_log" >&2 || true
        rm -rf "$tmp"
        return 1
    fi
    log "Build succeeded."
    echo "$tree"
}

_publshr_acquire_valid_tree() {
    local tree=""
    local tmp_tree=""

    if _publshr_live_exists; then
        tmp_tree="$(_publshr_download_live)" || tmp_tree=""
        if [[ -n "$tmp_tree" ]]; then
            _publshr_repair_bundle "$tmp_tree" || true
            if _publshr_validate_native_app "$tmp_tree"; then
                tree="$tmp_tree"
            fi
        fi
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

_publshr_cli_target() {
    if [[ -x "$PUBLSHR_MAC_APP/Contents/MacOS/publshr-cli" ]]; then
        echo "$PUBLSHR_MAC_APP/Contents/MacOS/publshr-cli"
    elif [[ -x "$PUBLSHR_MAC_APP/Contents/MacOS/Publshr" ]]; then
        echo "$PUBLSHR_MAC_APP/Contents/MacOS/Publshr"
    fi
}

# Symlink CLI without sudo — never fail the install if /usr/local/bin is not writable.
_publshr_link_cli() {
    local target="$1"
    local link path

    [[ -n "$target" ]] || return 0

    for link in "${PUBLSHR_BIN_LINK}" "${HOME}/bin/publshr" "${HOME}/.local/bin/publshr"; do
        [[ -n "$link" ]] || continue
        path="$(dirname "$link")"
        if ! mkdir -p "$path" 2>/dev/null; then
            continue
        fi
        if [[ ! -w "$path" ]]; then
            continue
        fi
        if ln -sf "$target" "$link" 2>/dev/null; then
            log "  CLI: $link"
            if [[ ":$PATH:" != *":${path}:"* ]]; then
                log "  Tip: add to PATH in ~/.zshrc:  export PATH=\"${path}:\$PATH\""
            fi
            return 0
        fi
    done

    log "  CLI: not linked (optional). Run the app from Applications or:"
    log "       open \"${PUBLSHR_MAC_APP}\""
}

_publshr_install_app() {
    local tree="$1"
    local app="${tree}/Publshr.app"
    local cli_target=""
    if [[ ! -d "$app" ]]; then
        log "ERROR: Publshr.app missing in $tree"
        exit 1
    fi
    log "Installing to ${PUBLSHR_MAC_APP} …"
    rm -rf "$PUBLSHR_MAC_APP"
    ditto "$app" "$PUBLSHR_MAC_APP"
    chmod -R 755 "$PUBLSHR_MAC_APP"
    xattr -cr "$PUBLSHR_MAC_APP" 2>/dev/null || true
    cli_target="$(_publshr_cli_target)"
    _publshr_link_cli "$cli_target"
    log "Installed."
    log "  App: $PUBLSHR_MAC_APP"
}

_publshr_install_with_privileges() {
    local tree="$1"
    mkdir -p "$(dirname "$PUBLSHR_MAC_APP")"
    if [[ ! -w "$(dirname "$PUBLSHR_MAC_APP")" ]]; then
        log "ERROR: Cannot write to $(dirname "$PUBLSHR_MAC_APP")."
        log "  Create ~/Applications or fix permissions, then re-run the installer."
        exit 1
    fi
    log "Installing to ${PUBLSHR_MAC_APP} (no administrator password) …"
    _publshr_install_app "$tree"
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

    # Install directly — GUI installer re-downloads the broken live tarball.
    _publshr_install_with_privileges "$tree"
    cleanup="$(dirname "$tree")"
    [[ "$cleanup" == /tmp/* || "$cleanup" == /var/folders/* ]] && rm -rf "$cleanup" || true

    log ""
    log "Launching Publshr …"
    open "$PUBLSHR_MAC_APP" 2>/dev/null || true
    _publshr_print_next_steps
}

_publshr_print_next_steps() {
    log ""
    log "Next steps (native Swift app — no npm, no admin password for updates):"
    log "  1. Sign in or create an account in the app window."
    log "  2. Settings → Sync now — refreshes GitHub live build + Supabase (Chat, Spaces, Media)."
    log "  3. Updates install to ~/Applications automatically (remove old /Applications/Publshr.app if present)."
    log "  4. Enterprise modules: Chat, Spaces, Planner, Media Monitoring — all native in this app."
    log ""
    log "This installer does NOT install the separate Tauri dev app under desktop/enterprise."
    log "To hack on that UI, clone the repo first:"
    log "  git clone https://github.com/${PUBLSHR_REPO}.git"
    log "  cd publshr.exe/desktop/enterprise && cp .env.example .env && npm install && npm run dev"
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
    _publshr_print_next_steps
}

log "Publshr native macOS installer v${INSTALLER_VERSION}"
log "Real Swift/SwiftUI desktop app — not Electron or a browser."
log ""

if [[ "${1:-}" == "--install-only" ]]; then
    _publshr_install_only_mode
else
    publshr_install_main "$@"
fi
