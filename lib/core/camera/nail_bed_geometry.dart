import 'dart:math' as math;
import 'dart:ui';

import '../../models/nail_bed_geometry.dart';
import '../../models/nail_finger.dart';

/// Nudge live camera nails toward the fingertip (fraction of distal phalanx length).
const double kCameraNailTipShiftBed = 0.17;

NailBedGeometry nudgeCameraNailTowardTip(
  NailBedGeometry geometry, {
  required Offset along,
  required double bedLength,
}) {
  if (bedLength < 1) {
    return geometry;
  }
  return NailBedGeometry(
    center: geometry.center + along * (bedLength * kCameraNailTipShiftBed),
    width: geometry.width,
    height: geometry.height,
    angle: geometry.angle,
  );
}

/// Computes on-screen size, rotation, and center for painting one nail.
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
  final bedLength = axis.distance;
  if (bedLength < 8) {
    return null;
  }

  final direction = axis / bedLength;
  final perpendicular = Offset(-direction.dy, direction.dx);
  final knuckleWidth = (pip - mcp).distance.clamp(8.0, 999.0);

  final double width;
  final double height;
  final double centerAlongBed;
  final double angleOffset;
  final double alongOffset;
  final double acrossOffset;

  if (metrics != null) {
    width = (bedLength * metrics.widthOverBed * scale).clamp(10.0, 110.0);
    height = (bedLength * metrics.heightOverBed * scale).clamp(12.0, 130.0);
    centerAlongBed = metrics.centerAlongBed;
    angleOffset = metrics.angleOffset;
    alongOffset = metrics.alongOffsetBed;
    acrossOffset = metrics.acrossOffsetBed;
  } else {
    final widthFactor = switch (placement.finger) {
      NailFinger.thumb => 0.95,
      NailFinger.pinky => 0.82,
      NailFinger.middle => 0.88,
      _ => 0.85,
    };
    width = (knuckleWidth * widthFactor * scale).clamp(12.0, 110.0);
    height = (bedLength * 1.05 * scale).clamp(14.0, 130.0);
    centerAlongBed = 0.50;
    angleOffset = 0;
    alongOffset = 0;
    acrossOffset = 0;
  }

  // Tip-anchored: pull center back from tip so cuticle sits near the joint.
  // centerAlongBed 0.5 ≈ nail centered on distal phalanx.
  final tipPullback = height * (0.52 - (centerAlongBed - 0.5) * 0.9);
  var center = tip - direction * tipPullback;
  center += direction * (bedLength * alongOffset);
  center += perpendicular * (bedLength * acrossOffset);

  // Nail art tip points along the finger toward the tip landmark.
  final angle = math.atan2(direction.dy, direction.dx) + math.pi / 2 + angleOffset;

  return nudgeCameraNailTowardTip(
    NailBedGeometry(
      center: center,
      width: width,
      height: height,
      angle: angle,
    ),
    along: direction,
    bedLength: bedLength,
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
