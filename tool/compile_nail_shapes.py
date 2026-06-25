#!/usr/bin/env python3
"""Compile nail shape SVG paths to normalized JSON polygons for the Flutter app."""

from __future__ import annotations

import json
import math
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SHAPES_DIR = ROOT / "assets" / "nail_shapes"


def _tokenize_path(d: str) -> list[str]:
    return re.findall(r"[a-zA-Z]|-?\d*\.?\d+(?:e[-+]?\d+)?", d)


def sample_path(d: str, curve_steps: int = 12) -> list[tuple[float, float]]:
    tokens = _tokenize_path(d)
    points: list[tuple[float, float]] = []
    i = 0
    cmd = ""
    cx = cy = 0.0
    sx = sy = 0.0

    def read_float() -> float:
        nonlocal i
        val = float(tokens[i])
        i += 1
        return val

    while i < len(tokens):
        if tokens[i].isalpha():
            cmd = tokens[i]
            i += 1
        if cmd in ("M", "m"):
            x = read_float()
            y = read_float()
            if cmd == "m":
                x += cx
                y += cy
            cx, cy = x, y
            sx, sy = cx, cy
            points.append((cx, cy))
        elif cmd in ("L", "l"):
            x = read_float()
            y = read_float()
            if cmd == "l":
                x += cx
                y += cy
            cx, cy = x, y
            points.append((cx, cy))
        elif cmd in ("C", "c"):
            x1 = read_float()
            y1 = read_float()
            x2 = read_float()
            y2 = read_float()
            x = read_float()
            y = read_float()
            if cmd == "c":
                x1 += cx
                y1 += cy
                x2 += cx
                y2 += cy
                x += cx
                y += cy
            x0, y0 = cx, cy
            for step in range(1, curve_steps + 1):
                t = step / curve_steps
                u = 1 - t
                px = u * u * u * x0 + 3 * u * u * t * x1 + 3 * u * t * t * x2 + t * t * t * x
                py = u * u * u * y0 + 3 * u * u * t * y1 + 3 * u * t * t * y2 + t * t * t * y
                points.append((px, py))
            cx, cy = x, y
        elif cmd in ("Z", "z"):
            cx, cy = sx, sy
            if points and points[0] != (cx, cy):
                points.append((cx, cy))
        else:
            raise ValueError(f"Unsupported path command: {cmd}")

    return points


def extract_path_d(svg_text: str) -> str:
    match = re.search(r'<path[^>]*\sd="([^"]+)"', svg_text, re.S)
    if not match:
        raise ValueError("No <path d=...> found in SVG")
    return re.sub(r"\s+", " ", match.group(1).strip())


def normalize(points: list[tuple[float, float]]) -> list[dict[str, float]]:
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    min_x, max_x = min(xs), max(xs)
    min_y, max_y = min(ys), max(ys)
    height = max(max_y - min_y, 1e-6)
    cx = (min_x + max_x) / 2
    half_w = max((max_x - min_x) / 2, 1e-6)

    out: list[dict[str, float]] = []
    for x, y in points:
        out.append(
            {
                "x": round((x - cx) / half_w, 4),
                "y": round((max_y - y) / height, 4),
            }
        )
    return _dedupe(out)


def _dedupe(points: list[dict[str, float]]) -> list[dict[str, float]]:
    if not points:
        return points
    out = [points[0]]
    for p in points[1:]:
        last = out[-1]
        if math.hypot(p["x"] - last["x"], p["y"] - last["y"]) > 0.01:
            out.append(p)
    return out


def compile_svg(svg_path: Path) -> dict:
    d = extract_path_d(svg_path.read_text())
    raw = sample_path(d)
    return {
        "source": svg_path.name,
        "points": normalize(raw),
    }


def main() -> None:
    svgs = sorted(
        p
        for p in SHAPES_DIR.glob("*.svg")
        if not p.name.startswith("cherry_")
    )
    if not svgs:
        raise SystemExit(f"No shape SVG files in {SHAPES_DIR}")

    for svg in svgs:
        data = compile_svg(svg)
        out = svg.with_suffix(".json")
        out.write_text(json.dumps(data, indent=2) + "\n")
        print(f"Wrote {out.name} ({len(data['points'])} points)")


if __name__ == "__main__":
    main()
