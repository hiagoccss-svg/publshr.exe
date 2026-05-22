#!/usr/bin/env bash
# Single source: AppShellIdentity.distributionTag in Swift.
set -euo pipefail

resolve_publshr_shell_tag() {
    local swift_file="${1:?swift file required}"
    grep -E 'distributionTag\s*=\s*"' "$swift_file" | head -1 | sed -E 's/.*"([^"]+)".*/\1/'
}
