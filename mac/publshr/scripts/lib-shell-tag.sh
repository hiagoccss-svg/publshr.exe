#!/usr/bin/env bash
# Single source: AppShellIdentity.distributionTag in Swift.
set -euo pipefail

resolve_publshr_shell_tag() {
    local swift_file="${1:?swift file required}"
    grep -E 'distributionTag\s*=\s*"' "$swift_file" | head -1 | sed -E 's/.*"([^"]+)".*/\1/'
}

# Numeric suffix from PublshrEnterpriseShell-N (0 when pattern does not match).
publshr_shell_tag_version() {
    local tag="${1:?tag required}"
    if [[ "$tag" =~ Shell-([0-9]+)$ ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo "0"
    fi
}
