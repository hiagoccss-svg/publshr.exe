#!/usr/bin/env bash
# Build a lightweight installer zip for GitHub Releases and direct download.
# Contains install-macos.sh + double-click Publshr Install.command + README + optional PublshrInstaller.app
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
DIST="$SCRIPT_DIR/../dist"
STAGE="$DIST/installer-macos-stage"
ZIP="$DIST/Publshr-Install-macos.zip"
INSTALL_SH_SRC="$REPO_ROOT/install-macos.sh"
ICON_SRC="${SCRIPT_DIR}/../app/icon.png"

# Keep repo-root icon.png in sync when present (user uploads to project root).
if [[ -f "$REPO_ROOT/icon.png" && ! -f "$ICON_SRC" ]] || [[ -f "$REPO_ROOT/icon.png" && "$REPO_ROOT/icon.png" -nt "$ICON_SRC" ]]; then
    cp "$REPO_ROOT/icon.png" "$ICON_SRC"
fi

if [[ ! -f "$INSTALL_SH_SRC" ]]; then
    echo "ERROR: install-macos.sh not found at $INSTALL_SH_SRC" >&2
    exit 1
fi

rm -rf "$STAGE" "$ZIP"
mkdir -p "$STAGE"

cp "$INSTALL_SH_SRC" "$STAGE/install-macos.sh"
chmod 755 "$STAGE/install-macos.sh"

cat >"$STAGE/Publshr Install.command" <<'EOF'
#!/bin/bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"
echo ""
echo "  Publshr — native macOS desktop installer"
echo "  ----------------------------------------"
echo ""
if [[ -d "$DIR/PublshrInstaller.app" ]]; then
    open "$DIR/PublshrInstaller.app"
    exit 0
fi
if [[ -f "$DIR/install-macos.sh" ]]; then
    exec bash "$DIR/install-macos.sh"
fi
INSTALL_URL="https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install-macos.sh"
TMP="$(mktemp -t publshr-install.XXXXXX.sh)"
curl -fsSL "$INSTALL_URL" -o "$TMP"
chmod 755 "$TMP"
exec bash "$TMP"
EOF
chmod 755 "$STAGE/Publshr Install.command"

# Native installer app (same icon as Publshr.app) when built in dist/
INSTALLER_APP="$(find "$DIST" -maxdepth 2 -type d -name 'PublshrInstaller.app' 2>/dev/null | head -1)"
if [[ -n "$INSTALLER_APP" && -d "$INSTALLER_APP" ]]; then
    ditto "$INSTALLER_APP" "$STAGE/PublshrInstaller.app"
    echo "Bundled PublshrInstaller.app in install zip" >&2
fi

if [[ "$(uname -s)" == "Darwin" && -f "$ICON_SRC" ]]; then
    chmod +x "${SCRIPT_DIR}/set-mac-file-icon.swift" 2>/dev/null || true
    swift "${SCRIPT_DIR}/set-mac-file-icon.swift" "$STAGE/Publshr Install.command" "$ICON_SRC" 2>/dev/null \
        && echo "Set custom icon on Publshr Install.command" >&2 \
        || echo "WARN: could not set .command icon" >&2
    if [[ -d "$STAGE/PublshrInstaller.app" ]]; then
        bash "${SCRIPT_DIR}/icon-build.sh" "$STAGE/PublshrInstaller.app/Contents/Resources/AppIcon.icns" || true
    fi
fi

cat >"$STAGE/README.txt" <<'EOF'
Publshr — macOS native desktop installer
========================================

WHAT YOU GET
  • Publshr.app — Swift/SwiftUI desktop (Chat, Spaces, Settings)
  • Auto-updates from GitHub live channel after first install

OPTION A — Double-click (easiest)
  1. Unzip this folder
  2. Double-click "Publshr Install.command" (or open PublshrInstaller.app)
  3. Follow the installer — installs to Applications with your Publshr icon
  4. Publshr opens when finished

OPTION B — Terminal (one line)
  curl -fsSL "https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install-macos.sh" | bash

OPTION C — Run the script in this folder
  bash install-macos.sh

REQUIREMENTS
  • macOS 14 or later (Apple Silicon recommended)
  • Internet access to download the app from GitHub
  • Administrator password for /Applications (one time)

AFTER INSTALL
  • App: /Applications/Publshr.app (Dock icon matches your brand)
  • Updates: automatic from the live release (no reinstall needed)
EOF

mkdir -p "$DIST"
(
    cd "$STAGE"
    zip -r "$ZIP" . -x "*.DS_Store"
)
rm -rf "$STAGE"

cp "$INSTALL_SH_SRC" "$DIST/Publshr-install-macos.sh"
chmod 755 "$DIST/Publshr-install-macos.sh"

echo "Created $ZIP" >&2
echo "Created $DIST/Publshr-install-macos.sh" >&2
ls -lh "$ZIP" "$DIST/Publshr-install-macos.sh" >&2
