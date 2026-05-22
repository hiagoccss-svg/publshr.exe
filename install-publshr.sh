#!/usr/bin/env bash
# Install publshr from anywhere (no git clone required).
# Usage: curl -fsSL https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/main/install-publshr.sh | bash
set -euo pipefail

REPO="${PUBLSHR_REPO:-hiagoccss-svg/publshr.exe}"
BRANCH="${PUBLSHR_BRANCH:-main}"

# Pick the newest GitHub release that actually ships a macOS app bundle (not CLI-only).
resolve_latest_version() {
    local api asset_name
    case "$(uname -s)" in
        Darwin)
            case "$(uname -m)" in
                arm64|aarch64) asset_name="macos-aarch64" ;;
                *) asset_name="macos-x86_64" ;;
            esac
            ;;
        Linux)
            case "$(uname -m)" in
                arm64|aarch64) asset_name="linux-aarch64" ;;
                *) asset_name="linux-x86_64" ;;
            esac
            ;;
        *) asset_name="" ;;
    esac

    python3 - "$REPO" "$asset_name" <<'PY' 2>/dev/null || true
import json, sys, urllib.request

repo, arch_suffix = sys.argv[1], sys.argv[2]
url = f"https://api.github.com/repos/{repo}/releases?per_page=30"
req = urllib.request.Request(
    url,
    headers={
        "Accept": "application/vnd.github+json",
        "User-Agent": "Publshr-Installer/1.0",
    },
)
with urllib.request.urlopen(req, timeout=30) as resp:
    releases = json.load(resp)

def version_from_tag(tag: str) -> str:
    return tag.lstrip("v")

best = None
for release in releases:
    tag = release.get("tag_name") or ""
    version = version_from_tag(tag)
    for asset in release.get("assets") or []:
        name = asset.get("name") or ""
        size = int(asset.get("size") or 0)
        if arch_suffix and f"-{arch_suffix}.tar.gz" not in name:
            continue
        if not name.startswith(f"publshr-{version}-"):
            continue
        # macOS IDE releases include Publshr.app (> ~5 MB). Skip CLI-only tarballs.
        if "macos" in name and size < 5_000_000:
            continue
        build = 0
        parts = version.split(".")
        if len(parts) >= 2 and parts[-1].isdigit():
            build = int(parts[-1])
        score = (build, size)
        if best is None or score > best[0]:
            best = (score, version)

if best:
    print(best[1], end="")
PY
}

RESOLVED="$(resolve_latest_version)"
VERSION="${PUBLSHR_VERSION:-${RESOLVED:-0.1.0}}"
INSTALLER_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/mac/publshr/install.sh"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

echo "Fetching installer ..."
curl -fsSL "$INSTALLER_URL" -o "$TMP"
chmod +x "$TMP"

if [[ "$(uname -s)" == "Darwin" ]]; then
    echo ""
    echo "This installs Publshr to /Applications (Launchpad + Finder → Applications)"
    echo "and adds the publshr command for Terminal."
    echo "  Release: v${VERSION}"
    echo ""
fi

exec env \
    PUBLSHR_VERSION="$VERSION" \
    PUBLSHR_REPO="$REPO" \
    PUBLSHR_BRANCH="$BRANCH" \
    "$TMP" "$@"
