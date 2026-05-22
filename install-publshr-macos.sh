#!/usr/bin/env bash
# Canonical macOS installer entry (new path — bypasses stale raw CDN cache on install-macos.sh).
# Usage:
#   curl -fsSL "https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install-publshr-macos.sh" | bash
set -euo pipefail
INSTALLER_URL="https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install/macos/install-macos.sh"
printf '%s\n' '[Publshr] Loading installer (v9+)...' >&2
exec bash <(curl -fsSL "$INSTALLER_URL")
