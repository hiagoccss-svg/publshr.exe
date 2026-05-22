#!/usr/bin/env bash
# Redirect to canonical installer (install-publshr.sh is often cached stale on GitHub raw CDN).
set -euo pipefail
INSTALLER_URL="https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install-macos.sh"
printf '%s\n' '[Publshr] Fetching latest installer...' >&2
exec bash <(curl -fsSL "$INSTALLER_URL")
