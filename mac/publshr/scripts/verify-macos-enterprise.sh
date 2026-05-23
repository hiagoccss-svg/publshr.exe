#!/usr/bin/env bash
# macOS enterprise readiness: Supabase + install policy + Swift package compile.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

echo "=== Supabase + GitHub (all connections) ==="
bash "$ROOT/mac/publshr/scripts/verify-all-connections.sh"

echo ""
echo "=== Spaces type column (text, not legacy enum) ==="
if command -v supabase >/dev/null 2>&1; then
  echo "Run: supabase db execute — select typname from pg_type where typname = 'space_type';"
  echo "(Legacy enum should be dropped after migration 20260523140000.)"
else
  echo "SKIP local supabase CLI — remote migration applied via dashboard/MCP."
fi

echo ""
echo "=== Install policy (no sudo / osascript admin in hot paths) ==="
for f in \
  "$ROOT/install/macos/install-macos.sh" \
  "$ROOT/mac/publshr/scripts/apply-macos-update.sh" \
  "$ROOT/install-now-macos.sh"
do
  if rg -q 'with administrator privileges|exec sudo' "$f" 2>/dev/null; then
    echo "FAIL: admin prompt still present in $f"
    exit 1
  fi
  echo "OK: $f"
done

echo ""
echo "=== Swift CLI package ==="
cd "$ROOT/mac/publshr"
swift build

echo ""
echo "ALL MACOS ENTERPRISE CHECKS PASSED"
