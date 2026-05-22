#!/usr/bin/env bash
# Build a lightweight installer zip for GitHub Releases and direct download.
# Contains install-macos.sh + double-click Publshr Install.command + README.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
DIST="$SCRIPT_DIR/../dist"
STAGE="$DIST/installer-macos-stage"
ZIP="$DIST/Publshr-Install-macos.zip"
INSTALL_SH_SRC="$REPO_ROOT/install-macos.sh"

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

cat >"$STAGE/README.txt" <<'EOF'
Publshr — macOS native desktop installer
========================================

WHAT YOU GET
  • Publshr.app — Swift/SwiftUI IDE (not a web app or Electron shell)
  • Auto-updates from GitHub after the first install

OPTION A — Double-click (easiest)
  1. Unzip this folder
  2. Double-click "Publshr Install.command"
  3. Follow the native Installer window, or allow Terminal to install to Applications
  4. Publshr opens when finished

OPTION B — Terminal (one line)
  curl -fsSL "https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install-macos.sh" | bash

OPTION C — Run the script in this folder
  bash install-macos.sh

REQUIREMENTS
  • macOS 14 or later (Apple Silicon recommended)
  • Internet access to download the app (~5–15 MB from GitHub)
  • Administrator password for /Applications (one time)

AFTER INSTALL
  • App: /Applications/Publshr.app
  • Updates: automatic from the "live" release (no reinstall needed)

Full app package (advanced / offline): see GitHub Releases → Publshr-macos-aarch64.tar.gz
EOF

mkdir -p "$DIST"
(
    cd "$STAGE"
    zip -r "$ZIP" . -x "*.DS_Store"
)
rm -rf "$STAGE"

# Standalone copy for workflows that upload the shell script directly
cp "$INSTALL_SH_SRC" "$DIST/Publshr-install-macos.sh"
chmod 755 "$DIST/Publshr-install-macos.sh"

echo "Created $ZIP" >&2
echo "Created $DIST/Publshr-install-macos.sh" >&2
ls -lh "$ZIP" "$DIST/Publshr-install-macos.sh" >&2
