#!/usr/bin/env bash
# Replace the installed Publshr.app after the running instance exits, then relaunch.
# Invoked by the app with: apply-macos-update.sh <extracted-tree-dir> <parent-pid>
set -euo pipefail

TREE="${1:?extracted release tree directory required}"
PARENT_PID="${2:?parent process id required}"
TARGET="${PUBLSHR_MAC_APP:-/Applications/Publshr.app}"
LOG_DIR="${HOME}/Library/Application Support/Publshr/updates"
LOG="${LOG_DIR}/last-update.log"

mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG") 2>&1

echo "=== Publshr update $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
echo "Tree: $TREE"
echo "Target: $TARGET"
echo "Waiting for PID $PARENT_PID to exit ..."

for _ in $(seq 1 120); do
    if ! kill -0 "$PARENT_PID" 2>/dev/null; then
        break
    fi
    sleep 0.5
done

APP_SRC="${TREE}/Publshr.app"
if [[ ! -d "$APP_SRC" ]]; then
    APP_BIN="${TREE}/bin/PublshrApp"
    if [[ -f "$APP_BIN" ]]; then
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        bash "${SCRIPT_DIR}/build-macos-app.sh" "$APP_BIN" "${PUBLSHR_SHORT_VERSION:-0.2.0}" "${PUBLSHR_BUILD_NUMBER:-0}" "$TREE"
        APP_SRC="${TREE}/Publshr.app"
    fi
fi

if [[ ! -d "$APP_SRC" ]]; then
    echo "ERROR: Publshr.app not found in update tree" >&2
    exit 1
fi

echo "Installing to $TARGET ..."
rm -rf "$TARGET"
ditto "$APP_SRC" "$TARGET"
chmod -R 755 "$TARGET"
/usr/bin/touch "$TARGET"
xattr -cr "$TARGET" 2>/dev/null || true

echo "Launching Publshr ..."
open "$TARGET"
echo "Update complete."
