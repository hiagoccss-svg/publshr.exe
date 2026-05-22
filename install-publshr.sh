#!/usr/bin/env bash
# Install publshr from anywhere (no git clone required).
# Usage: curl -fsSL https://raw.githubusercontent.com/hiagoccss-svg/publshr.exe/main/install-publshr.sh | bash
set -euo pipefail

REPO="${PUBLSHR_REPO:-hiagoccss-svg/publshr.exe}"
BRANCH="${PUBLSHR_BRANCH:-main}"

platform_asset_suffix() {
    case "$(uname -s)" in
        Darwin)
            case "$(uname -m)" in
                arm64|aarch64) echo "macos-aarch64" ;;
                *) echo "macos-x86_64" ;;
            esac
            ;;
        Linux)
            case "$(uname -m)" in
                arm64|aarch64) echo "linux-aarch64" ;;
                *) echo "linux-x86_64" ;;
            esac
            ;;
        *) echo "" ;;
    esac
}

# Newest GitHub release with a full macOS app (>5MB), not CLI-only.
resolve_latest_mac_app_version() {
    local arch_suffix repo api
    arch_suffix="$(platform_asset_suffix)"
    [[ "$arch_suffix" == macos-* ]] || return 1
    repo="$REPO"
    api="https://api.github.com/repos/${repo}/releases?per_page=30"

    if command -v python3 >/dev/null 2>&1; then
        python3 - "$repo" "$arch_suffix" <<'PY' || return 1
import json, sys, urllib.request

repo, arch_suffix = sys.argv[1], sys.argv[2]
url = f"https://api.github.com/repos/{repo}/releases?per_page=30"
req = urllib.request.Request(
    url,
    headers={"Accept": "application/vnd.github+json", "User-Agent": "Publshr-Installer/1.0"},
)
with urllib.request.urlopen(req, timeout=60) as resp:
    releases = json.load(resp)

best = None
for release in releases:
    tag = (release.get("tag_name") or "").lstrip("v")
    for asset in release.get("assets") or []:
        name = asset.get("name") or ""
        size = int(asset.get("size") or 0)
        if f"-{arch_suffix}.tar.gz" not in name:
            continue
        if not name.startswith(f"publshr-{tag}-"):
            continue
        if size < 5_000_000:
            continue
        parts = tag.split(".")
        build = int(parts[-1]) if len(parts) >= 2 and parts[-1].isdigit() else 0
        score = (build, size)
        if best is None or score > best[0]:
            best = (score, tag)
if best:
    print(best[1], end="")
PY
        return 0
    fi
    return 1
}

VERSION="${PUBLSHR_VERSION:-}"
if [[ -z "$VERSION" && "$(uname -s)" == "Darwin" ]]; then
    if RESOLVED="$(resolve_latest_mac_app_version 2>/dev/null)" && [[ -n "$RESOLVED" ]]; then
        VERSION="$RESOLVED"
    else
        # No full Mac release on GitHub yet — install.sh will clone and compile.
        VERSION=""
    fi
elif [[ -z "$VERSION" ]]; then
    VERSION="0.1.0"
fi

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
    if [[ -n "$VERSION" ]]; then
        echo "  Release: v${VERSION}"
    else
        echo "  No pre-built Mac release found — will build from GitHub (${BRANCH})."
        echo "  (Requires Xcode; first install takes a few minutes.)"
    fi
    echo ""
fi

exec env \
    PUBLSHR_VERSION="$VERSION" \
    PUBLSHR_REPO="$REPO" \
    PUBLSHR_BRANCH="$BRANCH" \
    "$TMP" "$@"
