#!/usr/bin/env bash
# Confirms GitHub live + desktop releases + Supabase — no local dev machine required.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
REPO="${PUBLSHR_REPO:-hiagoccss-svg/publshr.exe}"

check_url() {
  local name=$1 url=$2 min=${3:-1000}
  local code size
  code="$(curl -fsSIL -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo 000)"
  size="$(curl -fsSIL "$url" 2>/dev/null | awk 'tolower($1)=="content-length:" {print $2}' | tr -d '\r' | tail -1)"
  if [[ "$code" != "200" && "$code" != "302" ]]; then
    echo "FAIL: $name (HTTP $code)"
    return 1
  fi
  if [[ -n "${size:-}" && "$size" -lt "$min" ]]; then
    echo "FAIL: $name (size $size < $min)"
    return 1
  fi
  echo "OK: $name"
}

echo "=== GitHub live (macOS IDE) ==="
LIVE_BASE="https://github.com/${REPO}/releases/download/live"
check_url "VERSION.txt" "${LIVE_BASE}/VERSION.txt" 3
check_url "live tarball" "${LIVE_BASE}/Publshr-macos-aarch64.tar.gz" 4000000
check_url "install-macos.sh" "https://raw.githubusercontent.com/${REPO}/refs/heads/main/install-macos.sh" 50

echo ""
echo "=== GitHub desktop companions (macOS shell) ==="
for product in spaces media-monitoring; do
  ok=0
  for ch in production staging; do
    url="https://github.com/${REPO}/releases/download/${product}-${ch}/Publshr-${product}-shell-macos-aarch64.zip"
    if check_url "${product}-${ch}" "$url" 8000000 2>/dev/null; then
      ok=1
      break
    fi
  done
  if [[ "$ok" != "1" ]]; then
    echo "WARN: No macOS shell yet for $product — merge main to trigger deliver-desktop.yml"
  fi
done

echo ""
echo "=== Supabase enterprise ==="
bash "$ROOT/mac/publshr/scripts/verify-enterprise.sh"

echo ""
echo "Fully live checks complete."
