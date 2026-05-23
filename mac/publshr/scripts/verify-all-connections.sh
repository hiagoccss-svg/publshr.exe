#!/usr/bin/env bash
# Run GitHub live + Supabase auth + Chat/Spaces smoke tests.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== GitHub (live release) ==="
bash scripts/verify-github-live.sh
echo
echo "=== Supabase (auth + profile) ==="
bash scripts/verify-auth.sh
echo
echo "=== Supabase (chat + spaces) ==="
bash scripts/verify-chat-spaces.sh
echo
echo "=== Supabase (enterprise tables) ==="
bash scripts/verify-enterprise.sh
echo
echo "All connection checks passed."
