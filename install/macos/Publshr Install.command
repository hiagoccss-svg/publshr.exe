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
