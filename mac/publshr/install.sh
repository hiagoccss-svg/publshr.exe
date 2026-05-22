#!/usr/bin/env bash
# Delegates to the stable root installer (same URL users curl).
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
exec bash "$ROOT/install-publshr.sh" "$@"
