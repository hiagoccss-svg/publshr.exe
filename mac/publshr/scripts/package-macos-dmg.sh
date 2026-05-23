#!/usr/bin/env bash
# Build a macOS disk image for end-user install (GUI installer + drag-to-Applications).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST="$SCRIPT_DIR/../dist"
STAGE="$DIST/dmg-stage"
DMG_RAW="$DIST/Publshr-Install-macos.raw.dmg"
DMG="$DIST/Publshr-Install-macos.dmg"
LIVE_TAR="$DIST/Publshr-macos-aarch64.tar.gz"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "SKIP: DMG packaging requires macOS (run in deliver-macos.yml)" >&2
  exit 0
fi

if [[ ! -f "$LIVE_TAR" ]]; then
  echo "ERROR: Build $LIVE_TAR first (package-release.sh)" >&2
  exit 1
fi

bash "${SCRIPT_DIR}/sync-app-icon.sh"

rm -rf "$STAGE" "$DMG_RAW" "$DMG"
mkdir -p "$STAGE"

TMP_EXTRACT="$(mktemp -d)"
trap 'rm -rf "$TMP_EXTRACT"' EXIT
tar -xzf "$LIVE_TAR" -C "$TMP_EXTRACT"
TREE="$(find "$TMP_EXTRACT" -mindepth 1 -maxdepth 1 -type d | head -1)"
APP_SRC="$(find "$TREE" -path '*/Publshr.app' -type d | head -1)"
if [[ -z "$APP_SRC" || ! -d "$APP_SRC" ]]; then
  echo "ERROR: Publshr.app not found in $LIVE_TAR" >&2
  exit 1
fi

ditto "$APP_SRC" "$STAGE/Publshr.app"

INSTALLER_APP="$(find "$DIST" -maxdepth 2 -type d -name 'PublshrInstaller.app' 2>/dev/null | head -1)"
if [[ -z "$INSTALLER_APP" ]]; then
  INSTALLER_APP="$(find "$TREE" -type d -name 'PublshrInstaller.app' 2>/dev/null | head -1)"
fi
if [[ -n "$INSTALLER_APP" && -d "$INSTALLER_APP" ]]; then
  ditto "$INSTALLER_APP" "$STAGE/PublshrInstaller.app"
else
  echo "WARN: PublshrInstaller.app not found — DMG will use drag-to-Applications only" >&2
fi

ln -sf /Applications "$STAGE/Applications"

if [[ -f "$DIST/VERSION.txt" ]]; then
  cp "$DIST/VERSION.txt" "$STAGE/VERSION.txt"
fi

cat >"$STAGE/README.txt" <<'EOF'
Install Publshr
===============

Recommended
  Double-click "PublshrInstaller.app" and follow the steps.
  Installs to ~/Applications (live updates without admin password).

Alternative
  Drag Publshr.app onto the Applications folder in this window.

Updates
  After install, Publshr checks GitHub "live" and updates itself automatically.
EOF

if [[ -f "${SCRIPT_DIR}/../app/icon.png" ]]; then
  chmod +x "${SCRIPT_DIR}/set-mac-file-icon.swift" 2>/dev/null || true
  for target in "$STAGE/Publshr.app" "$STAGE/PublshrInstaller.app"; do
    [[ -e "$target" ]] || continue
    swift "${SCRIPT_DIR}/set-mac-file-icon.swift" "$target" "${SCRIPT_DIR}/../app/icon.png" 2>/dev/null || true
  done
fi

if [[ -n "${DEVELOPER_ID_APPLICATION:-}" ]]; then
  bash "${SCRIPT_DIR}/sign-macos-release.sh" "$STAGE/Publshr.app"
  [[ -d "$STAGE/PublshrInstaller.app" ]] && bash "${SCRIPT_DIR}/sign-macos-release.sh" "$STAGE/PublshrInstaller.app"
fi

VOLNAME="Publshr"
hdiutil create -volname "$VOLNAME" -srcfolder "$STAGE" -ov -format UDRW -fs HFS+ "$DMG_RAW" >/dev/null

MOUNT="$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_RAW" | awk '/\/Volumes\// {print $3; exit}')"
if [[ -n "$MOUNT" ]]; then
  # Finder window: installer on the left, Applications alias on the right.
  echo '
     tell application "Finder"
       tell disk "'"$VOLNAME"'"
         open
         set current view of container window to icon view
         set toolbar visible of container window to false
         set statusbar visible of container window to false
         set bounds of container window to {120, 100, 720, 420}
         set theViewOptions to the icon view options of container window
         set arrangement of theViewOptions to not arranged
         set icon size of theViewOptions to 96
         try
           set position of item "PublshrInstaller.app" of container window to {140, 160}
         end try
         try
           set position of item "Publshr.app" of container window to {280, 160}
         end try
         try
           set position of item "Applications" of container window to {500, 160}
         end try
         close
         open
       end tell
     end tell
  ' | osascript >/dev/null 2>&1 || true
  hdiutil detach "$MOUNT" -quiet || true
fi

hdiutil convert "$DMG_RAW" -format UDZO -imagekey zlib-level=9 -o "$DMG" >/dev/null
rm -f "$DMG_RAW"
rm -rf "$STAGE"

if [[ -n "${DEVELOPER_ID_APPLICATION:-}" && -n "${APPLE_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]]; then
  bash "${SCRIPT_DIR}/sign-macos-release.sh" --notarize-dmg "$DMG"
fi

echo "Created $DMG ($(du -sh "$DMG" | awk '{print $1}'))" >&2
ls -lh "$DMG" >&2
