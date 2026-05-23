#!/usr/bin/env bash
# Smoke test: GitHub live release + installer URLs (macOS auto-update channel).
set -euo pipefail

REPO="${PUBLSHR_GITHUB_REPO:-hiagoccss-svg/publshr.exe}"
TAG="${PUBLSHR_RELEASE_TAG:-live}"
BASE="https://github.com/${REPO}/releases/download/${TAG}"

check_url() {
  local label="$1"
  local url="$2"
  local code
  code="$(curl -sL -o /dev/null -w "%{http_code}" "$url")"
  if [[ "$code" != "200" && "$code" != "302" ]]; then
    echo "FAIL $label HTTP $code — $url" >&2
    exit 1
  fi
  echo "OK   $label ($code)"
}

echo "GitHub repo: $REPO (tag: $TAG)"
check_url "VERSION.txt" "${BASE}/VERSION.txt"
check_url "Publshr-macos tarball" "${BASE}/Publshr-macos-aarch64.tar.gz"
check_url "Install zip" "${BASE}/Publshr-Install-macos.zip"
check_url "install-macos.sh (main)" "https://raw.githubusercontent.com/${REPO}/refs/heads/main/install-macos.sh"

ver="$(curl -fsSL "${BASE}/VERSION.txt" 2>/dev/null | head -1 || true)"
echo "Live build: ${ver:-unknown}"
echo "OK — GitHub live channel reachable."
