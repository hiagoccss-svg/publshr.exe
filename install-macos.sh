#!/usr/bin/env bash
# Canonical macOS install URL (documented in AGENTS.md, README, INSTALL.md).
# Downloads the live tarball and installs to ~/Applications/Publshr.app — no manual download step.
#
# Usage:
#   curl -fsSL "https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install-macos.sh" | bash
set -euo pipefail

PUBLSHR_REPO="${PUBLSHR_REPO:-hiagoccss-svg/publshr.exe}"
PUBLSHR_BRANCH="${PUBLSHR_BRANCH:-main}"
INSTALLER_URL="https://raw.githubusercontent.com/${PUBLSHR_REPO}/refs/heads/${PUBLSHR_BRANCH}/install/macos/install-macos.sh"

printf '%s\n' '[Publshr] Loading native macOS installer…' >&2
exec bash <(curl -fsSL "$INSTALLER_URL")
