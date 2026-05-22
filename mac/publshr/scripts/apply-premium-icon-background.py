#!/usr/bin/env python3
"""Bake a pure white background and scale the mark to fill the app icon canvas."""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

# Pixels at or above this luminance (and not part of the ink mark) become #FFFFFF.
# The source artwork includes a grey rounded frame (~170–210); older builds only
# whitened >=210, which left the visible grey ring in Dock/Finder.
_BACKGROUND_LUM_THRESHOLD = 140


def white_background(size: int) -> Image.Image:
    """Solid #FFFFFF plate for Dock/Finder (macOS app icon)."""
    n = size
    rgb = np.full((n, n, 3), 255, dtype=np.uint8)
    alpha = np.full((n, n), 255, dtype=np.uint8)
    return Image.fromarray(np.dstack([rgb, alpha]), mode="RGBA")


def _ink_mark_mask(rgb: np.ndarray, alpha: np.ndarray) -> np.ndarray:
    lum = rgb.mean(axis=2)
    return (alpha > 32) & (lum < _BACKGROUND_LUM_THRESHOLD)


def _force_white_outside_mark(arr: np.ndarray, mark: np.ndarray) -> None:
    arr[~mark, :3] = 255
    arr[~mark, 3] = 255


def flatten_to_full_white_icon(source: Image.Image, size: int) -> Image.Image:
    """Remove grey frame/anti-alias, force #FFFFFF, and scale logo to fill the square."""
    src = source.convert("RGBA")
    arr = np.array(src)
    rgb = arr[:, :, :3]
    alpha = arr[:, :, 3]

    mark = _ink_mark_mask(rgb, alpha)
    _force_white_outside_mark(arr, mark)

    if not mark.any():
        layer = Image.fromarray(arr, mode="RGBA").resize((size, size), Image.Resampling.LANCZOS)
        return Image.alpha_composite(white_background(size), layer)

    ys, xs = np.where(mark)
    span = max(ys.max() - ys.min(), xs.max() - xs.min())
    pad = max(4, int(0.03 * span))
    y0, y1 = max(0, ys.min() - pad), min(arr.shape[0], ys.max() + pad + 1)
    x0, x1 = max(0, xs.min() - pad), min(arr.shape[1], xs.max() + pad + 1)
    crop = arr[y0:y1, x0:x1]
    crop_img = Image.fromarray(crop, mode="RGBA")

    cw, ch = crop_img.size
    # ~92% of canvas: fills the squircle without clipping the mark.
    target_side = max(1, int(round(size * 0.92)))
    scale = target_side / max(cw, ch)
    nw = max(1, int(round(cw * scale)))
    nh = max(1, int(round(ch * scale)))
    scaled = crop_img.resize((nw, nh), Image.Resampling.LANCZOS)

    out = white_background(size)
    x_off = (size - nw) // 2
    y_off = (size - nh) // 2
    out.paste(scaled, (x_off, y_off), scaled)

    final = np.array(out)
    final_mark = _ink_mark_mask(final[:, :, :3], final[:, :, 3])
    _force_white_outside_mark(final, final_mark)
    return Image.fromarray(final, mode="RGBA")


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
    root_out = flatten_to_full_white_icon(src_img, root_side)
    app_out = flatten_to_full_white_icon(src_img, app_size)

    root_icon.parent.mkdir(parents=True, exist_ok=True)
    app_icon.parent.mkdir(parents=True, exist_ok=True)
    root_out.save(root_icon, format="PNG", optimize=True)
    app_out.save(app_icon, format="PNG", optimize=True)
    print(f"Wrote {root_icon} ({root_side}×{root_side})")
    print(f"Wrote {app_icon} ({app_size}×{app_size})")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
