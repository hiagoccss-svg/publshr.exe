#!/usr/bin/env bash
# Pre/post deploy: GitHub live channel + Supabase chat/spaces smoke tests.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== Enterprise chat + live deploy checks ==="
bash scripts/verify-github-live.sh
echo
bash scripts/verify-chat-spaces.sh
echo
REMOTE_VER="$(curl -fsSL "https://github.com/hiagoccss-svg/publshr.exe/releases/download/live/VERSION.txt" | head -1 || true)"
echo "Live VERSION.txt line: ${REMOTE_VER:-unknown}"
echo "OK — ready for deliver-macos on main push."
