#!/usr/bin/env bash
# Enterprise live-mode verification: GitHub + Supabase + frontend builds.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

echo "=== GitHub + Supabase (mac/publshr scripts) ==="
bash "$ROOT/mac/publshr/scripts/verify-all-connections.sh"

echo ""
echo "=== Enterprise TypeScript ==="
cd "$ROOT/desktop/spaces"
npm run typecheck
cd "$ROOT/desktop/enterprise"
npm run typecheck

echo ""
echo "=== Enterprise Vite build ==="
npm run build

echo ""
echo "=== Live Supabase sign-in + REST (enterprise .env) ==="
if [[ -f "$ROOT/desktop/enterprise/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/desktop/enterprise/.env"
  set +a
fi
export SUPABASE_URL="${VITE_SUPABASE_URL:-https://lboesdtsrqfvosznjpdy.supabase.co}"
export SUPABASE_KEY="${VITE_SUPABASE_ANON_KEY:-sb_publishable_mHARlRkK4iHkkn9wn_-uAw_EkW-jRXP}"
bash "$ROOT/mac/publshr/scripts/verify-auth.sh"
bash "$ROOT/mac/publshr/scripts/verify-enterprise.sh"

echo ""
echo "ALL ENTERPRISE LIVE CHECKS PASSED"
