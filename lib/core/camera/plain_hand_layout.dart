import 'dart:math' as math;
import 'dart:ui';

import '../../models/nail_finger.dart';
import 'nail_bed_geometry.dart';

/// Fixed nail positions on the plain hand photo assets (375×666, fingers up).
class PlainHandNailSlot {
  const PlainHandNailSlot({
    required this.finger,
    required this.centerX,
    required this.centerY,
    required this.width,
    required this.height,
    this.angle = 0,
  });

  final NailFinger finger;
  /// Normalized center X within the hand image (0–1).
  final double centerX;
  /// Normalized center Y within the hand image (0–1).
  final double centerY;
  /// Normalized width relative to hand image width.
  final double width;
  /// Normalized height relative to hand image height.
  final double height;
  final double angle;

  NailBedGeometry toGeometry(Size handSize, double scale) {
    return NailBedGeometry(
      center: Offset(centerX * handSize.width, centerY * handSize.height),
      width: width * handSize.width * scale,
      height: height * handSize.height * scale,
      angle: angle,
    );
  }

  /// Hit test in hand-local coordinates (same space as [toGeometry]).
  bool containsHandPoint(Offset point, Size handSize, {double scale = 1.0}) {
    final geometry = toGeometry(handSize, scale);
    final local = point - geometry.center;
    final cosA = math.cos(-geometry.angle);
    final sinA = math.sin(-geometry.angle);
    final unrotated = Offset(
      local.dx * cosA - local.dy * sinA,
      local.dx * sinA + local.dy * cosA,
    );
    final halfW = geometry.width / 2;
    final halfH = geometry.height / 2;
    return unrotated.dx.abs() <= halfW && unrotated.dy.abs() <= halfH;
  }

  static NailFinger? fingerAtHandPoint(Offset point, Size handSize, {double scale = 1.0}) {
    for (final slot in PlainHandLayout.slots.reversed) {
      if (slot.containsHandPoint(point, handSize, scale: scale)) {
        return slot.finger;
      }
    }
    return null;
  }
}

abstract final class PlainHandLayout {
  static const lightAsset = 'assets/handlight.png';
  static const brownAsset = 'assets/handbrown2.png';
  static const cherryAsset = 'assets/cherry2.png';
  static const aspectRatio = 434 / 576;

  /// Finger tap zones on the 434×576 hand photo.
  static const slots = <PlainHandNailSlot>[
    PlainHandNailSlot(
      finger: NailFinger.pinky,
      centerX: 0.088,
      centerY: 0.402,
      width: 0.072,
      height: 0.052,
      angle: -0.18,
    ),
    PlainHandNailSlot(
      finger: NailFinger.ring,
      centerX: 0.278,
      centerY: 0.358,
      width: 0.074,
      height: 0.054,
      angle: -0.08,
    ),
    PlainHandNailSlot(
      finger: NailFinger.middle,
      centerX: 0.478,
      centerY: 0.330,
      width: 0.078,
      height: 0.056,
      angle: 0,
    ),
    PlainHandNailSlot(
      finger: NailFinger.indexFinger,
      centerX: 0.665,
      centerY: 0.348,
      width: 0.074,
      height: 0.054,
      angle: 0.10,
    ),
    PlainHandNailSlot(
      finger: NailFinger.thumb,
      centerX: 0.848,
      centerY: 0.438,
      width: 0.082,
      height: 0.050,
      angle: 0.55,
    ),
  ];

  /// Slight downward shift so fingers sit nearer the visual center (below top bar).
  static const verticalCenterBias = 0.05;

  /// Largest hand rect that fits [viewport] while keeping the photo aspect ratio.
  static Rect fitHandRect(Size viewport) {
    final viewportAspect = viewport.width / viewport.height;

    late final double width;
    late final double height;

    if (viewportAspect > aspectRatio) {
      height = viewport.height;
      width = height * aspectRatio;
    } else {
      width = viewport.width;
      height = width / aspectRatio;
    }

    final top = (viewport.height - height) / 2 + viewport.height * verticalCenterBias;
    final clampedTop = top.clamp(0.0, viewport.height - height);

    return Rect.fromLTWH(
      (viewport.width - width) / 2,
      clampedTop,
      width,
      height,
    );
  }
}
