#!/usr/bin/env python3
"""Test mnemic/nails_seg_yolov8 on a hand/thumb image.

Setup (once):
  cd tool && python3 -m venv .venv && source .venv/bin/activate
  pip install ultralytics huggingface_hub pillow

Download model (once):
  huggingface-cli download mnemic/nails_seg_yolov8 nails_seg_s_yolov8_v1.pt \
    --local-dir models/nails_seg_yolov8

Run:
  python tool/test_nails_seg_yolov8.py assets/thumb.png
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image
from ultralytics import YOLO

ROOT = Path(__file__).resolve().parents[1]
MODEL = ROOT / "tool/models/nails_seg_yolov8/nails_seg_s_yolov8_v1.pt"
OUT = ROOT / "tool/output/nails_seg_yolov8"


def main() -> None:
    image_path = Path(sys.argv[1] if len(sys.argv) > 1 else ROOT / "assets/thumb.png")
    if not MODEL.exists():
        raise SystemExit(f"Model missing: {MODEL}\nSee script header for download steps.")
    if not image_path.exists():
        raise SystemExit(f"Image missing: {image_path}")

    OUT.mkdir(parents=True, exist_ok=True)
    model = YOLO(str(MODEL))
    result = model(str(image_path), verbose=False)[0]

    img = Image.open(image_path).convert("RGBA")
    w, h = img.size
    combined = np.zeros((h, w), dtype=np.uint8)

    if result.masks is not None:
        for mask_tensor in result.masks.data:
            mask = mask_tensor.cpu().numpy()
            if mask.shape != (h, w):
                resized = Image.fromarray((mask * 255).astype(np.uint8)).resize((w, h), Image.BILINEAR)
                mask = np.array(resized) / 255.0
            combined = np.maximum(combined, (mask > 0.5).astype(np.uint8) * 255)

    stem = image_path.stem
    mask_path = OUT / f"{stem}_mask.png"
    overlay_path = OUT / f"{stem}_overlay.png"
    plot_path = OUT / f"{stem}_yolo_plot.png"

    Image.fromarray(combined).save(mask_path)

    arr = np.array(img)
    alpha = combined.astype(np.float32) / 255.0
    polish = np.array([233, 30, 140], dtype=np.float32)
    for c in range(3):
        arr[..., c] = (arr[..., c] * (1 - alpha * 0.65) + polish[c] * alpha * 0.65).astype(np.uint8)
    Image.fromarray(arr).save(overlay_path)

    plot = result.plot()
    Image.fromarray(plot[..., ::-1]).save(plot_path)

    detections = len(result.boxes) if result.boxes is not None else 0
    masks = len(result.masks) if result.masks is not None else 0
    print(f"Detections: {detections}, masks: {masks}")
    print(f"Wrote {mask_path}")
    print(f"Wrote {overlay_path}")
    print(f"Wrote {plot_path}")


if __name__ == "__main__":
    main()
