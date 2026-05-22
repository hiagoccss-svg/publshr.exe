#!/usr/bin/env python3
"""Bake a white background into icon.png so black transparent logos stay visible on macOS."""

from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image


def _lerp(a: float, b: float, t: np.ndarray) -> np.ndarray:
    return a + (b - a) * t


def premium_background(size: int) -> Image.Image:
    """Solid white — black mark-only logos must read in Dock and Finder."""
    rgb = np.full((size, size, 3), 255, dtype=np.uint8)
    alpha = np.full((size, size), 255, dtype=np.uint8)
    return Image.fromarray(np.dstack([rgb, alpha]), mode="RGBA")


def composite_mark(source: Image.Image, size: int) -> Image.Image:
    src = source.convert("RGBA")
    if max(src.size) != size:
        src = src.resize((size, size), Image.Resampling.LANCZOS)

    bg = premium_background(size)
    # Premultiplied-safe composite: mark over background
    return Image.alpha_composite(bg, src)


def main() -> int:
    repo_root = Path(__file__).resolve().parents[3]
    targets = [
        repo_root / "icon.png",
        Path(__file__).resolve().parents[1] / "app" / "icon.png",
    ]
    size = 1024
    if len(sys.argv) > 1:
        size = int(sys.argv[1])

    source = targets[0] if targets[0].is_file() else targets[1]
    if not source.is_file():
        print("No icon.png found at repo root or mac/publshr/app/", file=sys.stderr)
        return 1

    src_img = Image.open(source)
    out = composite_mark(src_img, size)

    for path in targets:
        path.parent.mkdir(parents=True, exist_ok=True)
        out.save(path, format="PNG", optimize=True)
        print(f"Wrote {path} ({size}×{size})")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
