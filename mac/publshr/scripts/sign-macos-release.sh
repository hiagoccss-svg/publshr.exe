#!/usr/bin/env bash
# Sign (and optionally notarize) macOS release artifacts. No-op when credentials are absent.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENTITLEMENTS="${SCRIPT_DIR}/../app/Publshr.entitlements"

sign_app() {
  local app="$1"
  [[ -d "$app" ]] || return 0
  local identity="${DEVELOPER_ID_APPLICATION:--}"
  echo "Signing $(basename "$app") with ${identity} …" >&2
  local ent_args=()
  if [[ -f "$ENTITLEMENTS" ]]; then
    ent_args=(--entitlements "$ENTITLEMENTS")
  fi
  codesign --force --options runtime --timestamp \
    "${ent_args[@]}" \
    --deep --sign "$identity" "$app"
  codesign --verify --deep --strict "$app"
}

notarize_dmg() {
  local dmg="$1"
  [[ -f "$dmg" ]] || return 0
  [[ -n "${APPLE_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]] || return 0
  local team="${APPLE_TEAM_ID:-}"
  local args=(notarytool submit "$dmg" --apple-id "$APPLE_ID" --password "$APPLE_APP_SPECIFIC_PASSWORD" --wait)
  if [[ -n "$team" ]]; then
    args+=(--team-id "$team")
  fi
  echo "Notarizing $(basename "$dmg") …" >&2
  xcrun "${args[@]}"
  xcrun stapler staple "$dmg"
  echo "Stapled notarization ticket to $(basename "$dmg")" >&2
}

notarize_app() {
  local app="$1"
  [[ -d "$app" ]] || return 0
  [[ -n "${APPLE_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]] || return 0
  local zip="${TMPDIR:-/tmp}/publshr-notarize-$$.zip"
  rm -f "$zip"
  ditto -c -k --keepParent "$app" "$zip"
  local team="${APPLE_TEAM_ID:-}"
  local args=(notarytool submit "$zip" --apple-id "$APPLE_ID" --password "$APPLE_APP_SPECIFIC_PASSWORD" --wait)
  if [[ -n "$team" ]]; then
    args+=(--team-id "$team")
  fi
  echo "Notarizing $(basename "$app") …" >&2
  xcrun "${args[@]}"
  xcrun stapler staple "$app"
  rm -f "$zip"
}

if [[ "${1:-}" == "--notarize-dmg" ]]; then
  notarize_dmg "${2:?dmg path}"
  exit 0
fi

TARGET="${1:?Usage: sign-macos-release.sh <Publshr.app|PublshrInstaller.app> [--notarize-app]}"
if [[ ! -d "$TARGET" ]]; then
  echo "ERROR: not a bundle: $TARGET" >&2
  exit 1
fi

if [[ -z "${DEVELOPER_ID_APPLICATION:-}" ]]; then
  echo "SKIP: DEVELOPER_ID_APPLICATION not set — ad-hoc sign only" >&2
  codesign --force --deep --sign - "$TARGET" 2>/dev/null || true
  exit 0
fi

sign_app "$TARGET"
if [[ "${2:-}" == "--notarize-app" ]]; then
  notarize_app "$TARGET"
fi
