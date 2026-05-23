#!/usr/bin/env bash
# Delete merged cursor/* branches on GitHub. Keeps main and any branch with an open PR.
set -euo pipefail

REPO="${PUBLSHR_GITHUB_REPO:-hiagoccss-svg/publshr.exe}"
DRY_RUN="${DRY_RUN:-0}"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI required." >&2
  exit 1
fi

mapfile -t OPEN < <(gh pr list --repo "$REPO" --state open --json headRefName -q '.[].headRefName' | sort -u)
mapfile -t REMOTE < <(git ls-remote --heads origin 'cursor/*' 2>/dev/null | awk '{print $2}' | sed 's|refs/heads/||' | sort -u)

deleted=0
kept=0
for b in "${REMOTE[@]}"; do
  if printf '%s\n' "${OPEN[@]}" | grep -qx "$b"; then
    echo "keep (open PR): $b"
    kept=$((kept + 1))
    continue
  fi
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "would delete: $b"
    deleted=$((deleted + 1))
    continue
  fi
  if gh api -X DELETE "repos/${REPO}/git/refs/heads/${b}" >/dev/null 2>&1; then
    echo "deleted: $b"
    deleted=$((deleted + 1))
  else
    echo "skip: $b" >&2
  fi
done

echo "Done. deleted=$deleted kept_open_pr=$kept (set DRY_RUN=1 to preview)"
