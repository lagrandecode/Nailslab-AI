#!/usr/bin/env python3
"""Local nail detection server for dev testing (same contract as future Firebase fn).

Setup (once):
  bash tool/setup_nail_seg_model.sh

Run:
  python tool/local_nail_detect_server.py
  # POST http://127.0.0.1:8765/detect  {"image_base64": "..."}

Health:
  GET http://127.0.0.1:8765/health
"""

from __future__ import annotations

import base64
import binascii
import io
import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

import numpy as np
from PIL import Image, ImageOps
from ultralytics import YOLO

ROOT = Path(__file__).resolve().parents[1]
MODEL = ROOT / "tool/models/nails_seg_yolov8/nails_seg_s_yolov8_v1.pt"
HOST = "0.0.0.0"
PORT = 8765
CONF = 0.25


def load_model() -> YOLO:
    if not MODEL.exists():
        raise SystemExit(
            f"Model missing: {MODEL}\nRun: bash tool/setup_nail_seg_model.sh"
        )
    return YOLO(str(MODEL))


MODEL = load_model()


def detect_nails(image_bytes: bytes) -> list[dict]:
    img = ImageOps.exif_transpose(
        Image.open(io.BytesIO(image_bytes)).convert("RGB")
    )
    w, h = img.size
    result = MODEL(np.array(img), verbose=False, conf=CONF)[0]

    nails: list[dict] = []
    if result.boxes is None or result.masks is None:
        return nails

    boxes = result.boxes
    for i in range(len(boxes)):
        conf = float(boxes.conf[i].item())
        cls_id = int(boxes.cls[i].item())
        class_name = result.names.get(cls_id, "Nail")

        xyxy = boxes.xyxy[i].cpu().numpy()
        left, top, right, bottom = (float(v) for v in xyxy)
        cx = (left + right) / 2
        cy = (top + bottom) / 2
        bw = right - left
        bh = bottom - top

        polygon: list[dict[str, float]] = []
        if hasattr(result.masks, "xy") and i < len(result.masks.xy):
            seg = result.masks.xy[i]
            if seg is not None and len(seg) >= 3:
                polygon = [{"x": float(x), "y": float(y)} for x, y in seg]

        if len(polygon) < 3:
            polygon = [
                {"x": left, "y": top},
                {"x": right, "y": top},
                {"x": right, "y": bottom},
                {"x": left, "y": bottom},
            ]

        nails.append(
            {
                "id": f"nail_{i}",
                "class_name": class_name,
                "confidence": conf,
                "polygon": polygon,
                "bounding_box": {
                    "x": cx,
                    "y": cy,
                    "width": bw,
                    "height": bh,
                },
                "image_width": w,
                "image_height": h,
            }
        )

    nails.sort(key=lambda n: n["confidence"], reverse=True)
    return nails


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt: str, *args) -> None:
        sys.stdout.write("%s - %s\n" % (self.address_string(), fmt % args))

    def _send_json(self, status: int, payload: dict) -> None:
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self) -> None:
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_GET(self) -> None:
        if self.path.rstrip("/") == "/health":
            self._send_json(200, {"ok": True, "model": MODEL.model_name})
            return
        self._send_json(404, {"error": "Not found. Use POST /detect"})

    def do_POST(self) -> None:
        if self.path.rstrip("/") != "/detect":
            self._send_json(404, {"error": "Not found. Use POST /detect"})
            return

        length = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(length) if length else b""
        if not raw:
            self._send_json(400, {"error": "Empty body"})
            return

        try:
            data = json.loads(raw.decode("utf-8"))
        except json.JSONDecodeError:
            self._send_json(400, {"error": "Body must be JSON"})
            return

        b64 = data.get("image_base64")
        if not isinstance(b64, str) or not b64.strip():
            self._send_json(400, {"error": "Missing image_base64"})
            return

        try:
            image_bytes = base64.b64decode(b64)
        except (ValueError, binascii.Error):
            self._send_json(400, {"error": "Invalid base64 image"})
            return

        try:
            nails = detect_nails(image_bytes)
        except Exception as exc:  # noqa: BLE001 — dev server
            self._send_json(500, {"error": f"Detection failed: {exc}"})
            return

        if not nails:
            self._send_json(
                422,
                {
                    "error": "No nails detected. Try a clearer photo with fingers spread.",
                    "nails": [],
                },
            )
            return

        self._send_json(200, {"nails": nails})


def main() -> None:
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"Nail detect server listening on http://127.0.0.1:{PORT}", flush=True)
    print("  Health: GET  /health", flush=True)
    print("  Detect: POST /detect  {\"image_base64\": \"...\"}", flush=True)
    print("Physical device: use your Mac IP instead of 127.0.0.1", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")


if __name__ == "__main__":
    main()
