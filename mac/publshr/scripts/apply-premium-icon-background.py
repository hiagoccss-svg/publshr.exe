#!/usr/bin/env python3
"""Bake a white background into icon.png (mark-only or full icon)."""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image


def white_background(size: int) -> Image.Image:
    """Solid white plate for Dock/Finder (macOS app icon)."""
    n = size
    rgb = np.full((n, n, 3), 255, dtype=np.uint8)
    alpha = np.full((n, n), 255, dtype=np.uint8)
    return Image.fromarray(np.dstack([rgb, alpha]), mode="RGBA")


def composite_mark(source: Image.Image, size: int) -> Image.Image:
    src = source.convert("RGBA")
    if max(src.size) != size:
        src = src.resize((size, size), Image.Resampling.LANCZOS)

    bg = white_background(size)
    # Premultiplied-safe composite: mark over background
    return Image.alpha_composite(bg, src)


def main() -> int:
    repo_root = Path(__file__).resolve().parents[3]
    root_icon = repo_root / "icon.png"
    app_icon = Path(__file__).resolve().parents[1] / "app" / "icon.png"
    app_size = 1024
    if len(sys.argv) > 1:
        app_size = int(sys.argv[1])

    source = root_icon if root_icon.is_file() else app_icon
    if not source.is_file():
        print("No icon.png found at repo root or mac/publshr/app/", file=sys.stderr)
        return 1

    src_img = Image.open(source)
    root_side = max(src_img.size)
    root_out = composite_mark(src_img, root_side)
    app_out = composite_mark(src_img, app_size)

    root_icon.parent.mkdir(parents=True, exist_ok=True)
    app_icon.parent.mkdir(parents=True, exist_ok=True)
    root_out.save(root_icon, format="PNG", optimize=True)
    app_out.save(app_icon, format="PNG", optimize=True)
    print(f"Wrote {root_icon} ({root_side}×{root_side})")
    print(f"Wrote {app_icon} ({app_size}×{app_size})")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
