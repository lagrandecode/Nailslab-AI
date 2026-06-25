import 'dart:math' as math;
import 'dart:ui';

import '../../models/nail_bed_geometry.dart';
import 'nail_shape_fitter.dart';

/// Pixel bounds of visible nail art inside [NailTextureCatalog.nailPlateAsset].
/// Full asset is 408×612; art occupies the center band (tip top, cuticle bottom).
const Rect kNailPlateContentRect = Rect.fromLTWH(86, 54, 236, 514);

/// Builds a perspective quad (tip-L, tip-R, cuticle-R, cuticle-L) balanced on the
/// detected nail bed — same frame the natural overlay uses.
List<Offset> balancedQuadFromPolygon(List<Offset> polygon) {
  if (polygon.length < 3) {
    return polygon;
  }

  final frame = computeNailFrame(polygon);
  final length = math.max(frame.length, 4.0);

  var tipMin = double.infinity;
  var tipMax = -double.infinity;
  var baseMin = double.infinity;
  var baseMax = -double.infinity;
  var tipCrossSum = 0.0;
  var baseCrossSum = 0.0;
  var tipCount = 0;
  var baseCount = 0;

  for (final p in polygon) {
    final rel = p - frame.cuticle;
    final along = rel.dx * frame.axis.dx + rel.dy * frame.axis.dy;
    final cross = rel.dx * frame.perp.dx + rel.dy * frame.perp.dy;
    final t = along / length;

    if (t > 0.65) {
      tipMin = math.min(tipMin, cross);
      tipMax = math.max(tipMax, cross);
      tipCrossSum += cross;
      tipCount++;
    } else if (t < 0.35) {
      baseMin = math.min(baseMin, cross);
      baseMax = math.max(baseMax, cross);
      baseCrossSum += cross;
      baseCount++;
    }
  }

  if (tipMin == double.infinity) {
    tipMin = -frame.baseHalfWidth * 0.88;
    tipMax = frame.baseHalfWidth * 0.88;
  }

  if (baseMin == double.infinity) {
    baseMin = -frame.baseHalfWidth;
    baseMax = frame.baseHalfWidth;
  }

  final tipCenter = tipCount > 0 ? tipCrossSum / tipCount : 0.0;
  final baseCenter = baseCount > 0 ? baseCrossSum / baseCount : 0.0;

  final tipHalf = math.max((tipMax - tipMin) * 0.5 * 0.94, frame.baseHalfWidth * 0.55);
  final baseHalf = math.max((baseMax - baseMin) * 0.5 * 1.04, frame.baseHalfWidth);

  final tipPoint = frame.cuticle + frame.axis * (length * 1.03);
  final basePoint = frame.cuticle - frame.axis * (length * 0.02);

  return [
    tipPoint + frame.perp * (tipCenter - tipHalf),
    tipPoint + frame.perp * (tipCenter + tipHalf),
    basePoint + frame.perp * (baseCenter + baseHalf),
    basePoint + frame.perp * (baseCenter - baseHalf),
  ];
}

/// Flat geometry aligned to the nail frame (fallback under perspective warp).
NailBedGeometry flatGeometryFromFrame(List<Offset> polygon) {
  final frame = computeNailFrame(polygon);
  final center = frame.cuticle + frame.axis * (frame.length * 0.5);
  final angle = math.atan2(frame.axis.dy, frame.axis.dx) + math.pi / 2;

  return NailBedGeometry(
    center: center,
    width: math.max(frame.baseHalfWidth * 2, 8),
    height: math.max(frame.length, 8),
    angle: angle,
    quad: null,
  );
}
