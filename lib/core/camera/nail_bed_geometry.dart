import 'dart:math' as math;
import 'dart:ui';

import 'package:hand_detection/hand_detection.dart';

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
    quad: geometry.quad
        ?.map((corner) => corner + along * (bedLength * kCameraNailTipShiftBed))
        .toList(),
  );
}

/// Builds a perspective quad locked to landmarks — shape changes when the hand rotates.
List<Offset>? computeNailPerspectiveQuad({
  required NailBedGeometry base,
  required TrackedHandFrame hand,
  required NailFingerPlacement placement,
}) {
  final tip = hand.landmarks[placement.tip];
  final joint = hand.landmarks[placement.joint];
  if (tip == null || joint == null) {
    return null;
  }

  final axis = tip - joint;
  final bedLen = axis.distance;
  if (bedLen < 4) {
    return null;
  }

  var along = axis / bedLen;
  var perp = Offset(-along.dy, along.dx);
  final halfW = base.width * 0.5;

  final pip = hand.landmarks[placement.pip];
  final mcp = hand.landmarks[placement.mcp];
  final indexMcp = hand.landmarks[HandLandmarkType.indexFingerMCP];

  // 2D palm angle — thumb vs index knuckle shifts when the hand rotates.
  var lateralAsym = 0.0;
  if (pip != null && indexMcp != null) {
    final palm = indexMcp - pip;
    if (palm.distance > 5) {
      final palmN = palm / palm.distance;
      lateralAsym = (perp.dx * palmN.dx + perp.dy * palmN.dy).clamp(-1.0, 1.0);
      along = Offset.lerp(along, palmN, lateralAsym.abs() * 0.12)!;
      along = along / along.distance;
      perp = Offset(-along.dy, along.dx);
    }
  }

  if (pip != null && mcp != null) {
    final prox = pip - mcp;
    if (prox.distance > 4) {
      final proxN = prox / prox.distance;
      final roll2d = proxN.dx * along.dy - proxN.dy * along.dx;
      perp = Offset.lerp(perp, Offset(-proxN.dy, proxN.dx), roll2d.abs() * 0.28)!;
      perp = perp / perp.distance;
    }
  }

  final tipZ = hand.landmarkDepth[placement.tip] ?? 0;
  final jointZ = hand.landmarkDepth[placement.joint] ?? 0;
  final pipZ = hand.landmarkDepth[placement.pip] ?? jointZ;
  final indexMcpZ = hand.landmarkDepth[HandLandmarkType.indexFingerMCP] ?? pipZ;

  final zScale = bedLen * 3.4;
  // Pitch: finger toward/away from camera (face-on vs pointing at you).
  final pitch = ((tipZ - jointZ) * zScale).clamp(-halfW, halfW);
  // Roll: twist around the finger — one nail edge closer than the other.
  final roll = ((jointZ - pipZ) * zScale * 0.58).clamp(-halfW * 0.85, halfW * 0.85);
  // Yaw: whole hand turned left/right.
  final yaw = ((tipZ - indexMcpZ) * zScale * 0.48).clamp(-halfW * 0.75, halfW * 0.75);

  final cuticle = joint + along * (bedLen * 0.10);
  final nailTip = joint + along * (bedLen * 0.96);

  final pitchNorm = pitch / halfW;
  final tipW = halfW * (1.0 - pitchNorm.abs() * 0.52).clamp(0.28, 1.0);
  final baseW = halfW * 1.02;

  // Asymmetric width when hand rotates — like a face narrowing in profile.
  final rollSide = roll / halfW;
  final yawSide = yaw / halfW;
  final latSide = lateralAsym * 0.32;
  var leftScale = (1.0 + rollSide * 0.38 + yawSide * 0.28 + latSide).clamp(0.32, 1.45);
  var rightScale = (1.0 - rollSide * 0.38 - yawSide * 0.28 - latSide).clamp(0.32, 1.45);

  final pitchSkew = perp * pitch * 0.52;
  final yawAlong = along * yaw * 0.16;

  return [
    nailTip - perp * tipW * leftScale + pitchSkew + yawAlong,
    nailTip + perp * tipW * rightScale + pitchSkew + yawAlong,
    cuticle + perp * baseW * rightScale * 0.96 + yawAlong * 0.42,
    cuticle - perp * baseW * leftScale * 0.96 - yawAlong * 0.42,
  ];
}

NailBedGeometry attachPerspectiveQuad({
  required NailBedGeometry geometry,
  required TrackedHandFrame hand,
  required NailFingerPlacement placement,
}) {
  final quad = computeNailPerspectiveQuad(
    base: geometry,
    hand: hand,
    placement: placement,
  );
  if (quad == null) {
    return geometry;
  }
  return NailBedGeometry(
    center: geometry.center,
    width: geometry.width,
    height: geometry.height,
    angle: geometry.angle,
    quad: quad,
  );
}

/// Thumb nail geometry — works with only tip + IP visible (common in live camera).
NailBedGeometry? computeThumbNailBedGeometry({
  required TrackedHandFrame hand,
  required double scale,
  CameraNailMetrics? metrics,
}) {
  const placement = NailFingerPlacement(
    finger: NailFinger.thumb,
    tip: HandLandmarkType.thumbTip,
    joint: HandLandmarkType.thumbIP,
    pip: HandLandmarkType.thumbMCP,
    mcp: HandLandmarkType.thumbCMC,
    minExtensionRatio: 1.02,
  );

  final tip = hand.landmarks[placement.tip];
  final joint = hand.landmarks[placement.joint];
  if (tip == null || joint == null) {
    return null;
  }

  final axis = tip - joint;
  final bedLength = axis.distance;
  if (bedLength < 6) {
    return null;
  }

  final direction = axis / bedLength;
  final perpendicular = Offset(-direction.dy, direction.dx);
  final m = metrics ?? const CameraNailMetrics(widthOverBed: 1.08, heightOverBed: 1.04);

  final width = (bedLength * m.widthOverBed * scale).clamp(12.0, 120.0);
  final height = (bedLength * m.heightOverBed * scale).clamp(14.0, 130.0);
  final tipPullback = height * (0.52 - (m.centerAlongBed - 0.5) * 0.9);
  var center = tip - direction * tipPullback;
  center += direction * (bedLength * m.alongOffsetBed);
  center += perpendicular * (bedLength * m.acrossOffsetBed);

  final angle =
      math.atan2(direction.dy, direction.dx) + math.pi / 2 + m.angleOffset;

  return attachPerspectiveQuad(
    geometry: NailBedGeometry(
      center: center,
      width: width,
      height: height,
      angle: angle,
    ),
    hand: hand,
    placement: placement,
  );
}

bool isValidNailQuad(List<Offset> quad) {
  if (quad.length != 4) {
    return false;
  }
  for (final point in quad) {
    if (!point.dx.isFinite || !point.dy.isFinite) {
      return false;
    }
  }
  var area = 0.0;
  for (var i = 0; i < 4; i++) {
    final a = quad[i];
    final b = quad[(i + 1) % 4];
    area += a.dx * b.dy - b.dx * a.dy;
  }
  return area.abs() > 16;
}

Path nailQuadPath(List<Offset> quad) {
  return Path()
    ..moveTo(quad[0].dx, quad[0].dy)
    ..lineTo(quad[1].dx, quad[1].dy)
    ..lineTo(quad[2].dx, quad[2].dy)
    ..lineTo(quad[3].dx, quad[3].dy)
    ..close();
}

/// Derives a rotated rect from perspective quad corners (reliable on all devices).
NailBedGeometry flatGeometryFromPerspective(NailBedGeometry geometry) {
  final quad = geometry.quad;
  if (quad == null || !isValidNailQuad(quad)) {
    return geometry;
  }

  final tipMid = Offset.lerp(quad[0], quad[1], 0.5)!;
  final baseMid = Offset.lerp(quad[2], quad[3], 0.5)!;
  final along = tipMid - baseMid;
  final height = along.distance.clamp(10.0, 200.0);
  if (height < 8) {
    return geometry;
  }

  final width = ((quad[0] - quad[1]).distance + (quad[3] - quad[2]).distance) * 0.5;
  final angle = math.atan2(along.dy, along.dx) + math.pi / 2;
  final center = Offset.lerp(tipMid, baseMid, 0.5)!;

  return NailBedGeometry(
    center: center,
    width: width.clamp(10.0, 180.0),
    height: height,
    angle: angle,
    quad: quad,
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

  return attachPerspectiveQuad(
    geometry: nudgeCameraNailTowardTip(
      NailBedGeometry(
        center: center,
        width: width,
        height: height,
        angle: angle,
      ),
      along: direction,
      bedLength: bedLength,
    ),
    hand: hand,
    placement: placement,
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
