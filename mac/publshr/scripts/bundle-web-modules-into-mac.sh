#!/usr/bin/env bash
# Copy WebBundles into the app source tree (CI / local macOS packaging).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${SCRIPT_DIR}/../app/WebBundles"
DEST="${1:-${SCRIPT_DIR}/../app/WebBundles}"
echo "Web modules source: ${SRC}" >&2
echo "Ensure whiteboard/index.html exists before build-macos-app.sh" >&2
test -f "${SRC}/whiteboard/index.html"
