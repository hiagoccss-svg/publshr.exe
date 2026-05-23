#!/usr/bin/env bash
# Shared install location — user-owned path enables passwordless live updates.
set -euo pipefail

publshr_user_applications_app() {
    printf '%s/Applications/Publshr.app\n' "${HOME}"
}

publshr_default_mac_app() {
    if [[ -n "${PUBLSHR_MAC_APP:-}" ]]; then
        printf '%s\n' "$PUBLSHR_MAC_APP"
        return 0
    fi
    publshr_user_applications_app
}

publshr_system_applications_app() {
    printf '/Applications/Publshr.app\n'
}

# True when the current user can replace the .app without administrator approval.
publshr_app_path_is_user_updatable() {
    local target="$1"
    local parent
    parent="$(dirname "$target")"
    mkdir -p "$parent" 2>/dev/null || true
    if [[ ! -d "$parent" ]] || [[ ! -w "$parent" ]]; then
        return 1
    fi
    if [[ -d "$target" ]]; then
        [[ -w "$target" ]] && return 0
        rm -f "${target}/.publshr-write-test" 2>/dev/null || true
        touch "${target}/.publshr-write-test" 2>/dev/null && {
            rm -f "${target}/.publshr-write-test"
            return 0
        }
        return 1
    fi
    touch "${parent}/.publshr-write-test" 2>/dev/null && {
        rm -f "${parent}/.publshr-write-test"
        return 0
    }
    return 1
}

# Live updates always target a user-writable install (never prompt for admin).
publshr_resolved_live_update_target() {
    local requested="${1:-$(publshr_default_mac_app)}"
    if publshr_app_path_is_user_updatable "$requested"; then
        printf '%s\n' "$requested"
        return 0
    fi
    local user_app
    user_app="$(publshr_user_applications_app)"
    echo "NOTE: ${requested} is not user-writable — updating ${user_app} instead (no administrator password)." >&2
    printf '%s\n' "$user_app"
}
