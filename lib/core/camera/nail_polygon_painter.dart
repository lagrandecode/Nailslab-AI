import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../models/detected_nail.dart';
import 'nail_bed_geometry.dart' show isValidNailQuad, nailQuadPath;
import 'nail_plate_balancer.dart';
import 'nail_warp_painter.dart' show paintNailFlat, paintNailOnQuadMesh;

/// Paints a nail plate PNG balanced on the detected nail bed (YouCam-style).
void paintDetectedNailTexture(
  Canvas canvas,
  List<Offset> polygon,
  ui.Image texture, {
  Rect? contentRect,
  Color? tintColor,
  double tintOpacity = 0.84,
  bool selected = false,
}) {
  if (polygon.length < 3) {
    return;
  }

  final quad = balancedQuadFromPolygon(polygon);
  if (!isValidNailQuad(quad)) {
    return;
  }

  final src = contentRect ?? kNailPlateContentRect;
  final clip = nailQuadPath(quad);
  final flat = flatGeometryFromFrame(polygon);

  canvas.save();
  canvas.clipPath(clip);

  // Flat fill under warp — visible even when mesh is weak on device.
  paintNailFlat(canvas, texture, flat, textureRect: src);
  paintNailOnQuadMesh(
    canvas,
    texture,
    quad,
    subdivisions: 6,
    textureRect: src,
  );

  if (tintColor != null) {
    canvas.drawPath(
      clip,
      Paint()
        ..color = tintColor.withValues(alpha: tintOpacity)
        ..blendMode = BlendMode.color,
    );
    canvas.drawPath(
      clip,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..blendMode = BlendMode.softLight,
    );
  }

  canvas.restore();

  if (selected) {
    canvas.drawPath(
      clip,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = const Color(0xFFE91E8C).withValues(alpha: 0.85)
        ..isAntiAlias = true,
    );
  }
}

/// Paints polish color inside a nail polygon (YouCam / Roboflow style).
void paintDetectedNailShader(
  Canvas canvas,
  List<Offset> polygon, {
  required Color color,
  double opacity = 0.78,
  bool selected = false,
}) {
  if (polygon.length < 3) {
    return;
  }

  final path = _polygonPath(polygon);

  canvas.drawPath(
    path,
    Paint()
      ..color = color.withValues(alpha: opacity)
      ..blendMode = BlendMode.hardLight
      ..isAntiAlias = true,
  );

  canvas.drawPath(
    path,
    Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..blendMode = BlendMode.softLight
      ..isAntiAlias = true,
  );

  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 2.4 : 1.4
      ..color = selected
          ? Colors.white.withValues(alpha: 0.95)
          : Colors.white.withValues(alpha: 0.45)
      ..isAntiAlias = true,
  );
}

void paintDetectedNailOutline(
  Canvas canvas,
  DetectedNail nail, {
  required bool selected,
  required bool hasColor,
}) {
  if (nail.polygon.length < 3) {
    return;
  }

  final path = _polygonPath(nail.polygon);
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 2.6 : 1.6
      ..color = selected
          ? const Color(0xFFE91E8C)
          : Colors.white.withValues(alpha: hasColor ? 0.35 : 0.75)
      ..isAntiAlias = true,
  );
}

Path _polygonPath(List<Offset> polygon) {
  final path = Path()..moveTo(polygon.first.dx, polygon.first.dy);
  for (var i = 1; i < polygon.length; i++) {
    path.lineTo(polygon[i].dx, polygon[i].dy);
  }
  return path..close();
}

int? hitTestNailIndex(
  Offset screenPoint,
  List<List<Offset>> screenPolygons, {
  double tapPadding = 18,
}) {
  for (var i = screenPolygons.length - 1; i >= 0; i--) {
    final polygon = screenPolygons[i];
    if (polygon.length < 3) {
      continue;
    }
    final path = _polygonPath(polygon);
    if (path.contains(screenPoint)) {
      return i;
    }
    final bounds = path.getBounds().inflate(tapPadding);
    if (bounds.contains(screenPoint)) {
      return i;
    }
  }
  return null;
}
