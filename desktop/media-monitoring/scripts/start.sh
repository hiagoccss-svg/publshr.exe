#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -d node_modules ]]; then
  echo "Installing dependencies…"
  npm install
fi

if [[ ! -f out/main/index.js ]]; then
  echo "Building application…"
  npm run build
fi

echo "Starting Publshr Media Monitoring…"
if [[ -z "${DISPLAY:-}" ]] && command -v xvfb-run >/dev/null 2>&1; then
  exec xvfb-run -a npm run start
else
  exec npm run start
fi
