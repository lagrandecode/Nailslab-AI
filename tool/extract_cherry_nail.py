#!/usr/bin/env python3
"""Extract a single nail PNG from assets/cherry2.png.

Also writes assets/nail_shapes/cherry_middle_nail.svg (semantic, color-editable).
Re-run after changing cherry2.png: python3 tool/extract_cherry_nail.py middle
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets/cherry2.png"
OUT_PNG = ROOT / "assets/nail_shapes/cherry_middle_nail.png"
OUT_SVG = ROOT / "assets/nail_shapes/cherry_middle_nail.svg"

SLOTS = {
    "pinky": (0.059, 0.386),
    "ring": (0.283, 0.207),
    "middle": (0.487, 0.154),
    "index": (0.710, 0.216),
    "thumb": (0.935, 0.584),
}

DEFAULT_FINGER = "middle"


def extract_nail(finger: str = DEFAULT_FINGER, pad: int = 6) -> Path:
    img = Image.open(SRC).convert("RGBA")
    w, h = img.size
    arr = np.array(img)

    mask = (arr[..., :3].max(axis=2) > 12) | (arr[..., 3] > 12)
    ys, xs = np.where(mask)
    if len(xs) == 0:
        raise SystemExit(f"No nail pixels found in {SRC}")

    if finger not in SLOTS:
        raise SystemExit(f"Unknown finger {finger!r}. Choose from: {', '.join(SLOTS)}")

    nx, ny = SLOTS[finger]
    scx, scy = nx * w, ny * h
    dist = np.sqrt((xs - scx) ** 2 + (ys - scy) ** 2)
    radius = max(0.062 * w, 0.082 * h) * 0.75
    sel = dist <= radius
    if sel.sum() < 50:
        raise SystemExit(f"Too few pixels near {finger} slot")

    sel_x = xs[sel]
    sel_y = ys[sel]
    left = max(0, int(sel_x.min()) - pad)
    right = min(w, int(sel_x.max()) + pad + 1)
    top = max(0, int(sel_y.min()) - pad)
    bottom = min(h, int(sel_y.max()) + pad + 1)

    crop = img.crop((left, top, right, bottom))
    OUT_PNG.parent.mkdir(parents=True, exist_ok=True)
    crop.save(OUT_PNG)
    print(f"Extracted {finger} nail → {OUT_PNG} ({crop.size[0]}×{crop.size[1]})")
    print(f"SVG (edit colors): {OUT_SVG}")
    return OUT_PNG


if __name__ == "__main__":
    import sys

    extract_nail(sys.argv[1] if len(sys.argv) > 1 else DEFAULT_FINGER)
