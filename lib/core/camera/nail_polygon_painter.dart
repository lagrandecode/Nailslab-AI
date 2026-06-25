import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/detected_nail.dart';

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
