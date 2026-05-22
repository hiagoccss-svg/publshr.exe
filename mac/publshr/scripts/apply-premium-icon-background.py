#!/usr/bin/env python3
"""Bake a premium dark metallic background into icon.png (mark-only or full icon)."""

from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image


def _lerp(a: float, b: float, t: np.ndarray) -> np.ndarray:
    return a + (b - a) * t


def premium_background(size: int) -> Image.Image:
    """Obsidian base with soft spotlight and subtle warm rim."""
    n = size
    y, x = np.mgrid[0:n, 0:n].astype(np.float32)
    nx = x / (n - 1)
    ny = y / (n - 1)

    # Vertical depth: lighter top, deep bottom
    vertical = ny
    base_r = _lerp(42.0, 14.0, vertical)
    base_g = _lerp(44.0, 15.0, vertical)
    base_b = _lerp(50.0, 18.0, vertical)

    # Radial spotlight (upper-center)
    cx, cy = 0.5, 0.34
    dist = np.sqrt((nx - cx) ** 2 + (ny - cy) ** 2)
    spot = np.clip(1.0 - dist / 0.72, 0.0, 1.0) ** 1.8
    base_r += spot * 38.0
    base_g += spot * 40.0
    base_b += spot * 46.0

    # Warm bronze vignette at corners
    corner = np.maximum(np.abs(nx - 0.5), np.abs(ny - 0.5)) * 2.0
    vignette = np.clip((corner - 0.55) / 0.45, 0.0, 1.0) ** 1.2
    base_r += vignette * 18.0
    base_g += vignette * 10.0
    base_b += vignette * 4.0

    # Subtle horizontal sheen (brushed metal)
    sheen = np.exp(-((ny - 0.22) ** 2) / 0.018) * 0.35
    base_r += sheen * 22.0
    base_g += sheen * 24.0
    base_b += sheen * 28.0

    # Fine grain
    rng = np.random.default_rng(42)
    grain = (rng.random((n, n), dtype=np.float32) - 0.5) * 6.0

    rgb = np.stack([base_r, base_g, base_b], axis=-1) + grain[..., None]
    rgb = np.clip(rgb, 0, 255).astype(np.uint8)
    alpha = np.full((n, n), 255, dtype=np.uint8)
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
