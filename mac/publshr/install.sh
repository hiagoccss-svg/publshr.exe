#!/usr/bin/env bash
# Thin wrapper — all logic lives in the repo-root install-publshr.sh (stable URL).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
exec bash "$ROOT/install-publshr.sh" "$@"
