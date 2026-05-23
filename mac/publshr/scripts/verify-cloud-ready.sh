#!/usr/bin/env bash
# Enterprise readiness: GitHub live delivery + Supabase data plane (no Mac-local dependency).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=============================================="
echo " Publshr cloud readiness"
echo " Required: GitHub (live) + Supabase only"
echo " Optional:  Mac Application Support cache"
echo "=============================================="
echo

FAIL=0

echo "=== 1. GitHub live channel ==="
if bash scripts/verify-github-live.sh; then
  VER="$(curl -fsSL "https://github.com/hiagoccss-svg/publshr.exe/releases/download/live/VERSION.txt" | head -1 | tr -d '[:space:]')"
  echo "    Live version: ${VER}"
  DMG_CODE="$(curl -sL -o /dev/null -w "%{http_code}" "https://github.com/hiagoccss-svg/publshr.exe/releases/download/live/Publshr-Install-macos.dmg")"
  if [[ "$DMG_CODE" == "200" ]]; then
    echo "    Install DMG: OK"
  else
    echo "    Install DMG: HTTP $DMG_CODE (merge DMG installer PR if missing)"
  fi
else
  FAIL=1
fi
echo

echo "=== 2. Supabase (auth) ==="
bash scripts/verify-auth.sh || FAIL=1
echo

echo "=== 3. Supabase (chat + spaces) ==="
bash scripts/verify-chat-spaces.sh || FAIL=1
echo

echo "=== 4. Supabase (enterprise) ==="
bash scripts/verify-enterprise.sh || FAIL=1
echo

if [[ "$FAIL" -ne 0 ]]; then
  echo "CLOUD NOT READY — fix failures above." >&2
  exit 1
fi

echo "=============================================="
echo " CLOUD READY"
echo " - Ship app: GitHub live release"
echo " - Run data: Supabase (signed-in users)"
echo " - Mac disk: optional cache only"
echo "=============================================="
