#!/usr/bin/env bash
# Resolve SwiftPM release binary paths (varies: .build/release vs .build/arm64-apple-macosx/release).
find_swift_release_binary() {
    local product="$1"
    local pkg_root="${2:?package root directory}"
    local candidate found=""

    for candidate in \
        "${pkg_root}/.build/release/${product}" \
        "${pkg_root}/.build/arm64-apple-macosx/release/${product}" \
        "${pkg_root}/.build/x86_64-apple-macosx/release/${product}"; do
        if [[ -f "$candidate" ]]; then
            echo "$candidate"
            return 0
        fi
    done

    found="$(find "${pkg_root}/.build" -type f -path "*/release/${product}" 2>/dev/null | head -1)"
    if [[ -n "$found" && -f "$found" ]]; then
        echo "$found"
        return 0
    fi
    return 1
}
