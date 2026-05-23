#!/usr/bin/env bash
# Close pull requests superseded by main (run locally with gh auth as repo owner).
set -euo pipefail

STALE=(97 96 94 86 77 56 30)

for pr in "${STALE[@]}"; do
  echo "Closing #$pr …"
  gh pr close "$pr" --comment "Superseded by work merged to main. Safe to close." 2>/dev/null \
    || gh pr close "$pr" 2>/dev/null \
    || echo "  (skip #$pr — already closed or no access)"
done

echo "Done. Prune remote branches:"
echo "  cd mac/publshr && bash scripts/cleanup-github-branches.sh"
