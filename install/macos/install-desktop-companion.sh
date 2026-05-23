#!/usr/bin/env bash
# Install Publshr desktop companions (Spaces, Media Monitoring) from GitHub — no local repo.
#
#   curl -fsSL "https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install-desktop-spaces.sh" | bash
#   curl -fsSL "https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/refs/heads/main/install-desktop-media-monitoring.sh" | bash
#
set -euo pipefail

PRODUCT="${PUBLSHR_DESKTOP_PRODUCT:-}"
CHANNEL="${PUBLSHR_UPDATE_CHANNEL:-}"
REPO="${PUBLSHR_REPO:-hiagoccss-svg/publshr.exe}"
INSTALL_DIR="${PUBLSHR_DESKTOP_INSTALL_DIR:-${HOME}/Applications}"
MIN_BYTES=8000000

log() { echo "[Publshr] $*" >&2; }

usage() {
  cat >&2 <<EOF
Usage: install-desktop-companion.sh <spaces|media-monitoring>
  Or:  PUBLSHR_DESKTOP_PRODUCT=spaces bash install-desktop-companion.sh
EOF
  exit 1
}

[[ -n "$PRODUCT" ]] || PRODUCT="${1:-}"
[[ "$PRODUCT" == "spaces" || "$PRODUCT" == "media-monitoring" ]] || usage

if [[ "$(uname -s)" != "Darwin" ]]; then
  log "ERROR: macOS installer only. Linux/Windows: download from GitHub Releases."
  exit 1
fi

ASSET="Publshr-${PRODUCT}-shell-macos-aarch64.zip"
try_channels() {
  if [[ -n "$CHANNEL" ]]; then
    echo "$CHANNEL"
  else
    echo "production staging"
  fi
}

TAG=""
URL=""
for ch in $(try_channels); do
  candidate="${PRODUCT}-${ch}"
  u="https://github.com/${REPO}/releases/download/${candidate}/${ASSET}"
  code="$(curl -fsSIL -o /dev/null -w "%{http_code}" "$u" 2>/dev/null || echo 000)"
  if [[ "$code" == "200" || "$code" == "302" ]]; then
    TAG="$candidate"
    URL="$u"
    CHANNEL="$ch"
    break
  fi
done

MANIFEST_URL=""
[[ -n "$TAG" ]] && MANIFEST_URL="https://github.com/${REPO}/releases/download/${TAG}/${PRODUCT}-desktop-manifest.json"

log "Product: $PRODUCT"
log "Channel: ${CHANNEL:-unknown}"
log "Install to: $INSTALL_DIR"

tmpdir="$(mktemp -d)"
cleanup() { rm -rf "$tmpdir"; }
trap cleanup EXIT

if [[ -z "$URL" ]] || ! curl -fSL --progress-bar "$URL" -o "$tmpdir/$ASSET"; then
  log "ERROR: Could not download macOS shell for $PRODUCT."
  log "  Push to main (desktop/) so CI publishes ${PRODUCT}-production or ${PRODUCT}-staging."
  exit 1
fi

size="$(wc -c < "$tmpdir/$ASSET" | tr -d ' ')"
if [[ "$size" -lt "$MIN_BYTES" ]]; then
  log "ERROR: Download too small ($size bytes)."
  exit 1
fi

unzip -q "$tmpdir/$ASSET" -d "$tmpdir/extract"
app_path="$(find "$tmpdir/extract" -maxdepth 4 -name '*.app' -print -quit)"
if [[ -z "$app_path" ]]; then
  log "ERROR: No .app found inside $ASSET"
  exit 1
fi

app_name="$(basename "$app_path")"
dest="${INSTALL_DIR}/${app_name}"
mkdir -p "$INSTALL_DIR"
rm -rf "$dest"
ditto "$app_path" "$dest"
xattr -cr "$dest" 2>/dev/null || true
codesign --force --deep --sign - "$dest" 2>/dev/null || true

log "Installed: $dest"
if command -v open >/dev/null; then
  open "$dest"
fi

if curl -fsSL "$MANIFEST_URL" -o "$tmpdir/manifest.json" 2>/dev/null; then
  ver="$(python3 -c "import json; print(json.load(open('$tmpdir/manifest.json')).get('appVersion','?'))" 2>/dev/null || echo '?')"
  log "App version (manifest): $ver — auto-updates from ${TAG} on launch."
fi

log "Cloud: Supabase lboesdtsrqfvosznjpdy (sign in inside the app). No local npm or repo required."
