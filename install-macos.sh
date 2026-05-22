#!/usr/bin/env bash
# Redirect — GitHub raw CDN often caches an old copy of this filename. Use install/macos path.
set -euo pipefail
INSTALLER_URL="https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install/macos/install-macos.sh"
printf '%s\n' '[Publshr] Loading latest installer (bypassing CDN cache)...' >&2
exec bash <(curl -fsSL "$INSTALLER_URL")
