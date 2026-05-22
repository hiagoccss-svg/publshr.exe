#!/usr/bin/env bash
# Replace the installed Publshr.app after the running instance exits, then relaunch.
# Transactional: backup current app, install new build, rollback on failure.
# User data under ~/Library/Application Support/Publshr is never touched.
# Invoked by the app with: apply-macos-update.sh <extracted-tree-dir> <parent-pid>
set -euo pipefail

TREE="${1:?extracted release tree directory required}"
PARENT_PID="${2:?parent process id required}"
TARGET="${PUBLSHR_MAC_APP:-/Applications/Publshr.app}"
LOG_DIR="${HOME}/Library/Application Support/Publshr/updates"
LOG="${LOG_DIR}/last-update.log"
BACKUP="${LOG_DIR}/Publshr.app.backup"
STAGING_OK="${LOG_DIR}/.update-staging-ok"

mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG") 2>&1

rollback() {
    local reason="${1:-unknown failure}"
    echo "ROLLBACK: $reason"
    if [[ -d "$BACKUP" ]]; then
        rm -rf "$TARGET"
        if ditto "$BACKUP" "$TARGET"; then
            chmod -R 755 "$TARGET"
            xattr -cr "$TARGET" 2>/dev/null || true
            echo "Restored previous Publshr.app from backup."
        else
            echo "ERROR: rollback ditto failed — manual reinstall may be required." >&2
        fi
        rm -rf "$BACKUP"
    else
        echo "WARNING: no backup available for rollback." >&2
    fi
    rm -f "$STAGING_OK"
}

trap 'rollback "interrupted"' INT TERM

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
    if [[ ! -f "$APP_BIN" ]]; then
        APP_BIN="${TREE}/Publshr.app/Contents/MacOS/Publshr"
    fi
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

# Verify the new bundle has a runnable binary before touching the installed app.
APP_BIN_CHECK="${APP_SRC}/Contents/MacOS/Publshr"
if [[ ! -f "$APP_BIN_CHECK" ]]; then
    echo "ERROR: new app binary missing at $APP_BIN_CHECK" >&2
    exit 1
fi

rm -rf "$BACKUP"
if [[ -d "$TARGET" ]]; then
    echo "Backing up current app to $BACKUP ..."
    ditto "$TARGET" "$BACKUP"
fi

echo "Installing to $TARGET ..."
rm -f "$STAGING_OK"
if ! ditto "$APP_SRC" "$TARGET"; then
    rollback "ditto install failed"
    exit 1
fi
chmod -R 755 "$TARGET"
xattr -cr "$TARGET" 2>/dev/null || true
touch "$STAGING_OK"

# Smoke-check installed binary exists after replace.
if [[ ! -f "${TARGET}/Contents/MacOS/Publshr" ]]; then
    rollback "installed binary missing after ditto"
    exit 1
fi

echo "Update installed successfully; removing backup."
rm -rf "$BACKUP"
rm -f "$STAGING_OK"
trap - INT TERM

echo "Launching Publshr ..."
open "$TARGET"
echo "Update complete."
