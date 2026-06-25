import 'dart:math' as math;
import 'dart:ui';

import '../../models/detected_nail.dart';
import '../../models/nail_beauty_shape.dart';
import '../../models/nail_finger.dart';
import 'nail_shape_catalog.dart';

/// How much larger than detection the square nail template is drawn.
const double kSquareNailFitScale = 1.38;

class NailFrame {
  const NailFrame({
    required this.cuticle,
    required this.axis,
    required this.perp,
    required this.length,
    required this.baseHalfWidth,
  });

  final Offset cuticle;
  final Offset axis;
  final Offset perp;
  final double length;
  final double baseHalfWidth;
}

NailFrame computeNailFrame(List<Offset> polygon) {
  if (polygon.length < 3) {
    return const NailFrame(
      cuticle: Offset.zero,
      axis: Offset(0, -1),
      perp: Offset(1, 0),
      length: 1,
      baseHalfWidth: 1,
    );
  }

  var cx = 0.0;
  var cy = 0.0;
  for (final p in polygon) {
    cx += p.dx;
    cy += p.dy;
  }
  cx /= polygon.length;
  cy /= polygon.length;

  var sxx = 0.0;
  var syy = 0.0;
  var sxy = 0.0;
  for (final p in polygon) {
    final dx = p.dx - cx;
    final dy = p.dy - cy;
    sxx += dx * dx;
    syy += dy * dy;
    sxy += dx * dy;
  }

  final theta = 0.5 * math.atan2(2 * sxy, sxx - syy);
  var axis = Offset(math.cos(theta), math.sin(theta));
  var perp = Offset(-axis.dy, axis.dx);

  var minAlong = double.infinity;
  var maxAlong = -double.infinity;
  final alongValues = <double>[];
  final perpValues = <double>[];

  for (final p in polygon) {
    final rel = p - Offset(cx, cy);
    final along = rel.dx * axis.dx + rel.dy * axis.dy;
    final cross = rel.dx * perp.dx + rel.dy * perp.dy;
    alongValues.add(along);
    perpValues.add(cross);
    minAlong = math.min(minAlong, along);
    maxAlong = math.max(maxAlong, along);
  }

  double widthNear(double target) {
    var maxAbs = 0.0;
    for (var i = 0; i < polygon.length; i++) {
      if ((alongValues[i] - target).abs() < (maxAlong - minAlong) * 0.18) {
        maxAbs = math.max(maxAbs, perpValues[i].abs());
      }
    }
    return maxAbs;
  }

  final widthAtMin = widthNear(minAlong);
  final widthAtMax = widthNear(maxAlong);
  if (widthAtMax > widthAtMin) {
    axis = -axis;
    perp = -perp;
    final tmp = minAlong;
    minAlong = -maxAlong;
    maxAlong = -tmp;
  }

  final length = math.max(maxAlong - minAlong, 4.0);
  final cuticle = Offset(cx, cy) + axis * minAlong;

  var baseHalfWidth = widthNear(minAlong);
  if (baseHalfWidth < 2) {
    baseHalfWidth = perpValues.map((v) => v.abs()).reduce(math.max);
  }

  return NailFrame(
    cuticle: cuticle,
    axis: axis,
    perp: perp,
    length: length,
    baseHalfWidth: math.max(baseHalfWidth, 2.0),
  );
}

Offset _centroid(List<Offset> polygon) {
  var x = 0.0;
  var y = 0.0;
  for (final p in polygon) {
    x += p.dx;
    y += p.dy;
  }
  return Offset(x / polygon.length, y / polygon.length);
}

bool _isThumb(DetectedNail nail, List<DetectedNail> all) {
  if (nail.finger == NailFinger.thumb) {
    return true;
  }
  if (nail.finger != null) {
    return false;
  }
  return _fallbackThumb(all)?.id == nail.id;
}

DetectedNail? _fallbackThumb(List<DetectedNail> nails) {
  if (nails.length <= 1) {
    return nails.isEmpty ? null : nails.first;
  }

  final centroids = nails.map((n) => _centroid(n.detectionPolygon)).toList();
  final xs = centroids.map((c) => c.dx).toList()..sort();
  final medianX = xs[xs.length ~/ 2];

  DetectedNail? best;
  var bestScore = -1.0;
  for (var i = 0; i < nails.length; i++) {
    final xDist = (centroids[i].dx - medianX).abs();
    final frame = computeNailFrame(nails[i].detectionPolygon);
    final score = xDist + frame.baseHalfWidth * 0.15;
    if (score > bestScore) {
      bestScore = score;
      best = nails[i];
    }
  }
  return best;
}

NailPlateRole roleForNail(DetectedNail nail, List<DetectedNail> all) {
  if (!_isThumb(nail, all)) {
    return NailPlateRole.finger;
  }

  if (all.length == 1 || nail.finger == NailFinger.thumb) {
    final frame = computeNailFrame(nail.detectionPolygon);
    final aspect = frame.length / (frame.baseHalfWidth * 2);
    if (all.length == 1) {
      return NailPlateRole.thumbFront;
    }
    return aspect < 1.35 ? NailPlateRole.thumbFront : NailPlateRole.thumbSpread;
  }

  return NailPlateRole.thumbSpread;
}

List<Offset> fitTemplateToPolygon(
  List<Offset> sourcePolygon,
  List<Offset> template, {
  double scale = 1.0,
}) {
  if (template.length < 3) {
    return sourcePolygon;
  }

  final frame = computeNailFrame(sourcePolygon);
  final center = frame.cuticle + frame.axis * (frame.length * 0.5);
  final nudgedCenter =
      center + frame.axis * (frame.length * 0.05 * (scale - 1).clamp(0.0, 0.2));

  return template
      .map((p) {
        final y = p.dy * frame.length;
        final x = p.dx * frame.baseHalfWidth;
        final point = frame.cuticle + frame.axis * y + frame.perp * x;
        if (scale == 1.0) {
          return point;
        }
        return nudgedCenter + (point - center) * scale;
      })
      .toList(growable: false);
}

Future<DetectedNail> applyShapeToNail(
  DetectedNail nail,
  List<DetectedNail> allNails,
  NailBeautyShape shape, {
  List<Offset>? fingerTemplate,
}) async {
  final source = nail.detectionPolygon;
  if (shape == NailBeautyShape.natural) {
    return nail.copyWith(polygon: source, shape: shape);
  }

  if (_isThumb(nail, allNails)) {
    final role = roleForNail(nail, allNails);
    final template = await NailShapeCatalog.instance.templatePoints(
      shape: shape,
      role: role,
    );
    return nail.copyWith(
      polygon: fitTemplateToPolygon(
        source,
        template,
        scale: kSquareNailFitScale,
      ),
      shape: shape,
    );
  }

  final template = fingerTemplate ??
      await NailShapeCatalog.instance.templatePoints(
        shape: shape,
        role: NailPlateRole.finger,
      );

  return nail.copyWith(
    polygon: fitTemplateToPolygon(
      source,
      template,
      scale: kSquareNailFitScale,
    ),
    shape: shape,
  );
}

Future<List<DetectedNail>> applyShapeToNails(
  List<DetectedNail> nails,
  NailBeautyShape shape,
) async {
  if (shape == NailBeautyShape.natural) {
    return nails
        .map(
          (n) => n.copyWith(
            polygon: n.detectionPolygon,
            shape: shape,
          ),
        )
        .toList(growable: false);
  }

  final fingerTemplate = await NailShapeCatalog.instance.templatePoints(
    shape: shape,
    role: NailPlateRole.finger,
  );

  final out = <DetectedNail>[];
  for (final nail in nails) {
    out.add(
      await applyShapeToNail(
        nail,
        nails,
        shape,
        fingerTemplate: fingerTemplate,
      ),
    );
  }
  return out;
}

/// Perspective quad for texture warping (tip-left, tip-right, cuticle-right, cuticle-left).
List<Offset> quadFromPolygon(List<Offset> polygon) {
  if (polygon.length < 3) {
    return polygon;
  }

  final frame = computeNailFrame(polygon);

  var tipMinPerp = double.infinity;
  var tipMaxPerp = -double.infinity;
  var baseMinPerp = double.infinity;
  var baseMaxPerp = -double.infinity;

  for (final p in polygon) {
    final rel = p - frame.cuticle;
    final along = rel.dx * frame.axis.dx + rel.dy * frame.axis.dy;
    final cross = rel.dx * frame.perp.dx + rel.dy * frame.perp.dy;
    if (along > frame.length * 0.68) {
      tipMinPerp = math.min(tipMinPerp, cross);
      tipMaxPerp = math.max(tipMaxPerp, cross);
    } else if (along < frame.length * 0.32) {
      baseMinPerp = math.min(baseMinPerp, cross);
      baseMaxPerp = math.max(baseMaxPerp, cross);
    }
  }

  if (tipMinPerp == double.infinity) {
    tipMinPerp = -frame.baseHalfWidth * 0.94;
    tipMaxPerp = frame.baseHalfWidth * 0.94;
  }
  if (baseMinPerp == double.infinity) {
    baseMinPerp = -frame.baseHalfWidth;
    baseMaxPerp = frame.baseHalfWidth;
  }

  final tip = frame.cuticle + frame.axis * frame.length;
  return [
    tip + frame.perp * tipMinPerp,
    tip + frame.perp * tipMaxPerp,
    frame.cuticle + frame.perp * baseMaxPerp,
    frame.cuticle + frame.perp * baseMinPerp,
  ];
}
