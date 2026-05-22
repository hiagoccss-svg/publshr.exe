#!/usr/bin/env bash
# Build the ONE macOS installer zip for GitHub Releases (canonical team download).
# Contains: Publshr.app (full build) + Publshr Install.command + install-macos.sh + README
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
DIST="$SCRIPT_DIR/../dist"
STAGE="$DIST/installer-macos-stage"
ZIP="$DIST/Publshr-Install-macos.zip"
INSTALL_SH_SRC="$REPO_ROOT/install/macos/install-macos.sh"
LIVE_TAR="$DIST/Publshr-macos-aarch64.tar.gz"
bash "${SCRIPT_DIR}/sync-app-icon.sh"
ICON_SRC="${SCRIPT_DIR}/../app/icon.png"

if [[ ! -f "$INSTALL_SH_SRC" ]]; then
    echo "ERROR: install/macos/install-macos.sh not found at $INSTALL_SH_SRC" >&2
    exit 1
fi

if [[ ! -f "$LIVE_TAR" ]]; then
    echo "ERROR: Build $LIVE_TAR first (run package-release.sh)" >&2
    exit 1
fi

rm -rf "$STAGE" "$ZIP"
mkdir -p "$STAGE"

# Embed full Publshr.app — one zip, no second download required.
TMP_EXTRACT="$(mktemp -d)"
trap 'rm -rf "$TMP_EXTRACT"' EXIT
tar -xzf "$LIVE_TAR" -C "$TMP_EXTRACT"
APP_SRC="$(find "$TMP_EXTRACT" -path '*/Publshr.app' -type d | head -1)"
if [[ -z "$APP_SRC" || ! -d "$APP_SRC" ]]; then
    echo "ERROR: Publshr.app not found inside $LIVE_TAR" >&2
    exit 1
fi
ditto "$APP_SRC" "$STAGE/Publshr.app"
echo "Bundled Publshr.app in install zip ($(du -sh "$STAGE/Publshr.app" | awk '{print $1}'))" >&2

cp "$INSTALL_SH_SRC" "$STAGE/install-macos.sh"
chmod 755 "$STAGE/install-macos.sh"

cat >"$STAGE/Publshr Install.command" <<'EOF'
#!/bin/bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"
APP_DEST="${HOME}/Applications/Publshr.app"

echo ""
echo "  Publshr — Install"
echo "  -----------------"
echo ""

install_bundled_app() {
    [[ -d "$DIR/Publshr.app" ]] || return 1
    echo "Installing to ${APP_DEST} …"
    mkdir -p "$(dirname "$APP_DEST")"
    rm -rf "$APP_DEST"
    ditto "$DIR/Publshr.app" "$APP_DEST"
    chmod -R 755 "$APP_DEST"
    xattr -cr "$APP_DEST" 2>/dev/null || true
    mkdir -p "${HOME}/bin"
    if [[ -x "${APP_DEST}/Contents/MacOS/publshr-cli" ]]; then
        ln -sf "${APP_DEST}/Contents/MacOS/publshr-cli" "${HOME}/bin/publshr" 2>/dev/null || true
    fi
    echo ""
    echo "  Installed. Opening Publshr …"
    echo ""
    open "$APP_DEST"
    return 0
}

if install_bundled_app; then
    exit 0
fi

if [[ -d "$DIR/PublshrInstaller.app" ]]; then
    open "$DIR/PublshrInstaller.app"
    exit 0
fi

if [[ -f "$DIR/install-macos.sh" ]]; then
    exec bash "$DIR/install-macos.sh"
fi

echo "ERROR: Publshr.app missing from this folder. Re-download Publshr-Install-macos.zip from GitHub." >&2
exit 1
EOF
chmod 755 "$STAGE/Publshr Install.command"

INSTALLER_APP="$(find "$DIST" -maxdepth 2 -type d -name 'PublshrInstaller.app' 2>/dev/null | head -1)"
if [[ -n "$INSTALLER_APP" && -d "$INSTALLER_APP" ]]; then
    ditto "$INSTALLER_APP" "$STAGE/PublshrInstaller.app"
    echo "Bundled PublshrInstaller.app in install zip" >&2
fi

if [[ "$(uname -s)" == "Darwin" && -f "$ICON_SRC" ]]; then
    chmod +x "${SCRIPT_DIR}/set-mac-file-icon.swift" 2>/dev/null || true
    for target in "$STAGE/Publshr Install.command" "$STAGE/Publshr.app"; do
        swift "${SCRIPT_DIR}/set-mac-file-icon.swift" "$target" "$ICON_SRC" 2>/dev/null \
            && echo "Set icon on $(basename "$target")" >&2 \
            || true
    done
    if [[ -d "$STAGE/PublshrInstaller.app" ]]; then
        bash "${SCRIPT_DIR}/icon-build.sh" "$STAGE/PublshrInstaller.app/Contents/Resources/AppIcon.icns" 2>/dev/null || true
    fi
fi

# Version label inside zip
if [[ -f "$DIST/VERSION.txt" ]]; then
    cp "$DIST/VERSION.txt" "$STAGE/VERSION.txt"
fi

cat >"$STAGE/README.txt" <<'EOF'
Publshr for macOS — ONE-FILE INSTALLER
======================================

This zip IS the app. Everything in main on GitHub is built into Publshr.app here.

INSTALL (30 seconds)
  1. Unzip Publshr-Install-macos.zip
  2. Double-click "Publshr Install.command"
  3. If macOS blocks it: right-click → Open → Open
  4. Publshr installs to ~/Applications/Publshr.app and opens

No Terminal required. No second download.

SUPABASE (already configured in the app)
  • Sign in with your email
  • Create or pick a workspace
  • Chat + Spaces sync to your project

UPDATES
  After install, Publshr checks GitHub "live" and updates itself.
  To reinstall manually, download this zip again from:
  https://github.com/hiagoccss-svg/publshr.exe/releases/download/live/Publshr-Install-macos.zip

TERMINAL (optional)
  bash install-macos.sh

REQUIREMENTS
  • macOS 14+ (Apple Silicon Mac)
  • Internet for sign-in and sync (app works offline for cached data)
EOF

mkdir -p "$DIST"
(
    cd "$STAGE"
    zip -ry "$ZIP" . -x "*.DS_Store"
)
rm -rf "$STAGE"

cp "$INSTALL_SH_SRC" "$DIST/Publshr-install-macos.sh"
chmod 755 "$DIST/Publshr-install-macos.sh"

echo "Created $ZIP ($(du -sh "$ZIP" | awk '{print $1}'))" >&2
echo "Created $DIST/Publshr-install-macos.sh" >&2
ls -lh "$ZIP" "$DIST/Publshr-install-macos.sh" 2>&1
