import 'dart:math' as math;
import 'dart:ui';

import '../../models/nail_finger.dart';

/// Computes on-screen size, rotation, and center for painting one nail.
class NailBedGeometry {
  const NailBedGeometry({
    required this.center,
    required this.width,
    required this.height,
    required this.angle,
  });

  final Offset center;
  final double width;
  final double height;
  final double angle;
}

NailBedGeometry? computeNailBedGeometry({
  required TrackedHandFrame hand,
  required NailFingerPlacement placement,
  required double scale,
  CameraNailMetrics? metrics,
}) {
  final tip = hand.landmarks[placement.tip];
  final joint = hand.landmarks[placement.joint];
  final pip = hand.landmarks[placement.pip];
  final mcp = hand.landmarks[placement.mcp];
  if (tip == null || joint == null || pip == null || mcp == null) {
    return null;
  }

  final axis = tip - joint;
  final nailBedLength = axis.distance;
  if (nailBedLength < 8) {
    return null;
  }

  final direction = axis / nailBedLength;
  final fingerWidth = (pip - mcp).distance;

  final double width;
  final double height;
  final double centerAlongBed;

  if (metrics != null) {
    width = (nailBedLength * metrics.widthOverBed * scale).clamp(10.0, 100.0);
    height = (nailBedLength * metrics.heightOverBed * scale).clamp(12.0, 120.0);
    centerAlongBed = metrics.centerAlongBed;
  } else {
    final widthFactor = switch (placement.finger) {
      NailFinger.thumb => 0.58,
      NailFinger.pinky => 0.46,
      NailFinger.middle => 0.50,
      _ => 0.48,
    };
    final heightFactor = switch (placement.finger) {
      NailFinger.thumb => 1.05,
      _ => 1.12,
    };

    width = (fingerWidth * widthFactor * scale).clamp(14.0, 120.0);
    height = (nailBedLength * heightFactor * scale).clamp(16.0, 140.0);
    centerAlongBed = 0.56;
  }

  final center = joint + direction * (nailBedLength * centerAlongBed);

  // Align nail art so the cuticle edge sits toward the joint and tip points outward.
  final angle = math.atan2(direction.dy, direction.dx) + math.pi / 2;

  return NailBedGeometry(
    center: center,
    width: width,
    height: height,
    angle: angle,
  );
}

Path buildNailClipPath(double width, double height) {
  final rect = Rect.fromCenter(
    center: Offset.zero,
    width: width,
    height: height,
  );
  final radius = Size(width, height).shortestSide * 0.46;
  return Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
}
