#!/usr/bin/env python3
"""Normalize repository-root icon.png onto a full white canvas for macOS + in-app branding."""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

REPO_ROOT = Path(__file__).resolve().parents[3]
ROOT_ICON = REPO_ROOT / "icon.png"
APP_ICON = Path(__file__).resolve().parents[1] / "app" / "icon.png"
DEFAULT_SIZE = 1024


def white_background(size: int) -> Image.Image:
    return Image.new("RGBA", (size, size), (255, 255, 255, 255))


def composite_on_white(source: Image.Image, size: int) -> Image.Image:
    src = source.convert("RGBA")
    if max(src.size) != size:
        src = src.resize((size, size), Image.Resampling.LANCZOS)
    bg = white_background(size)
    return Image.alpha_composite(bg, src)


def main() -> int:
    size = DEFAULT_SIZE
    if len(sys.argv) > 1:
        size = int(sys.argv[1])

    source = ROOT_ICON if ROOT_ICON.is_file() else APP_ICON
    if not source.is_file():
        print("No icon.png at repository root (single source of truth).", file=sys.stderr)
        return 1

    out = composite_on_white(Image.open(source), size)
    APP_ICON.parent.mkdir(parents=True, exist_ok=True)
    out.save(APP_ICON, format="PNG", optimize=True)
    print(f"normalize-brand-icon: {source} → {APP_ICON} ({size}×{size}, white background)" )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
