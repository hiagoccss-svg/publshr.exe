#!/usr/bin/env bash
# Install publshr for THIS machine into the repo's .local/ (Mac/Linux native CLI).
# No sudo. Run from repository root.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$ROOT/native/publshr"
VERSION="${PUBLSHR_VERSION:-0.1.0}"
LOCAL_ROOT="$ROOT/.local"
INSTALL_DIR="$LOCAL_ROOT/publshr/$VERSION"
BIN_DIR="$LOCAL_ROOT/bin"

if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "Error: $PROJECT_DIR not found. Clone the repo with the native/ folder." >&2
    exit 1
fi

if ! command -v swift >/dev/null 2>&1; then
    echo "Swift not found. Install from https://www.swift.org/install/ (Linux) or Xcode (macOS)." >&2
    exit 1
fi

echo "Building publshr $VERSION for $(uname -s)-$(uname -m) ..."
bash "$PROJECT_DIR/scripts/package-release.sh" "$VERSION"

ASSET="$(cd "$PROJECT_DIR/dist" && ls -d "publshr-${VERSION}-"* 2>/dev/null | grep -v '.tar.gz$' | head -1)"
if [[ -z "$ASSET" ]]; then
    echo "Error: package step did not produce dist/publshr-${VERSION}-*" >&2
    exit 1
fi

rm -rf "$INSTALL_DIR"
mkdir -p "$LOCAL_ROOT/publshr" "$BIN_DIR"
cp -a "$PROJECT_DIR/dist/$ASSET" "$INSTALL_DIR"
chmod 755 "$INSTALL_DIR/bin/publshr"

rm -f "$BIN_DIR/publshr"
if [[ -d "$INSTALL_DIR/lib" ]] && [[ -n "$(ls -A "$INSTALL_DIR/lib" 2>/dev/null)" ]]; then
    cat >"$BIN_DIR/publshr" <<WRAP
#!/usr/bin/env bash
export LD_LIBRARY_PATH="${INSTALL_DIR}/lib:\${LD_LIBRARY_PATH:-}"
exec "${INSTALL_DIR}/bin/publshr" "\$@"
WRAP
    chmod 755 "$BIN_DIR/publshr"
else
    ln -sf "$INSTALL_DIR/bin/publshr" "$BIN_DIR/publshr"
fi

echo ""
echo "Installed publshr $VERSION on this machine:"
echo "  App:     $INSTALL_DIR/bin/publshr"
echo "  Command: $BIN_DIR/publshr"
echo ""
echo "Add to your shell (copy once):"
echo "  export PATH=\"$BIN_DIR:\$PATH\""
echo ""
export PATH="$BIN_DIR:$PATH"
"$BIN_DIR/publshr" --version
