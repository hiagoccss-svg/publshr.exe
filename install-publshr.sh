#!/usr/bin/env bash
set -euo pipefail
INSTALLER_URL="https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install-publshr-macos.sh"
printf '%s\n' '[Publshr] Loading latest installer...' >&2
exec bash <(curl -fsSL "$INSTALLER_URL")
