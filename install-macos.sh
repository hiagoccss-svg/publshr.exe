#!/usr/bin/env bash
# Publshr macOS install — use the release installer (not a raw curl pipe).
set -euo pipefail

REPO="${PUBLSHR_REPO:-hiagoccss-svg/publshr.exe}"
LIVE_DMG="https://github.com/${REPO}/releases/download/live/Publshr-Install-macos.dmg"
LIVE_ZIP="https://github.com/${REPO}/releases/download/live/Publshr-Install-macos.zip"
RELEASES="https://github.com/${REPO}/releases/tag/live"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Publshr macOS installer requires a Mac. See ${RELEASES}" >&2
  exit 1
fi

echo ""
echo "  Publshr — macOS install"
echo "  -----------------------"
echo ""
echo "  Recommended: download the disk image from Releases (live channel):"
echo "    ${LIVE_DMG}"
echo ""
echo "  1. Open Publshr-Install-macos.dmg"
echo "  2. Double-click PublshrInstaller.app"
echo "  3. Click Install"
echo ""
echo "  Zip alternative: ${LIVE_ZIP}"
echo ""

TMP_DMG="$(mktemp -t publshr-install.XXXXXX.dmg)"
cleanup() { rm -f "$TMP_DMG" 2>/dev/null || true; }
trap cleanup EXIT

if curl -fL --retry 3 -o "$TMP_DMG" "$LIVE_DMG" 2>/dev/null; then
  MOUNT="$(hdiutil attach -nobrowse -quiet "$TMP_DMG" | awk '/\/Volumes\// {print $3; exit}')"
  if [[ -n "${MOUNT:-}" ]]; then
    if [[ -d "${MOUNT}/PublshrInstaller.app" ]]; then
      open "${MOUNT}/PublshrInstaller.app"
      echo "  Opened Publshr Installer from the downloaded disk image."
      exit 0
    fi
    if [[ -d "${MOUNT}/Publshr.app" ]]; then
      DEST="${HOME}/Applications/Publshr.app"
      mkdir -p "$(dirname "$DEST")"
      rm -rf "$DEST"
      ditto "${MOUNT}/Publshr.app" "$DEST"
      xattr -cr "$DEST" 2>/dev/null || true
      open "$DEST"
      hdiutil detach "$MOUNT" -quiet || true
      echo "  Installed to ${DEST}"
      exit 0
    fi
    hdiutil detach "$MOUNT" -quiet 2>/dev/null || true
  fi
fi

echo "  Could not open the live DMG automatically." >&2
echo "  Download manually: ${RELEASES}" >&2
exit 1
