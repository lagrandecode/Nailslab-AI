#!/usr/bin/env bash
# Download and export the Hugging Face nail segmentation model for the Flutter app.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENV="$ROOT/tool/.venv"
MODEL_DIR="$ROOT/tool/models/nails_seg_yolov8"
ASSET="$ROOT/assets/models/nails_seg_yolov8.onnx"

mkdir -p "$MODEL_DIR" "$ROOT/assets/models"

if [[ ! -d "$VENV" ]]; then
  python3 -m venv "$VENV"
  source "$VENV/bin/activate"
  pip install ultralytics huggingface_hub onnx onnxruntime
else
  source "$VENV/bin/activate"
fi

if [[ ! -f "$MODEL_DIR/nails_seg_s_yolov8_v1.pt" ]]; then
  huggingface-cli download mnemic/nails_seg_yolov8 nails_seg_s_yolov8_v1.pt \
    --local-dir "$MODEL_DIR"
fi

if [[ ! -f "$MODEL_DIR/nails_seg_s_yolov8_v1.onnx" ]]; then
  yolo export model="$MODEL_DIR/nails_seg_s_yolov8_v1.pt" format=onnx imgsz=320 simplify=True
fi

cp "$MODEL_DIR/nails_seg_s_yolov8_v1.onnx" "$ASSET"
echo "Installed $ASSET"
