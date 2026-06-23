import 'dart:math' as math;
import 'dart:ui';

import '../../models/nail_bed_geometry.dart';
import '../../models/nail_finger.dart';
import '../../models/nail_look.dart';

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

  /// Finger slots measured from assets/cherry2.png on the 434×576 hand canvas.
  static const slots = <PlainHandNailSlot>[
    PlainHandNailSlot(
      finger: NailFinger.pinky,
      centerX: 0.059,
      centerY: 0.386,
      width: 0.062,
      height: 0.066,
      angle: -0.18,
    ),
    PlainHandNailSlot(
      finger: NailFinger.ring,
      centerX: 0.283,
      centerY: 0.207,
      width: 0.065,
      height: 0.080,
      angle: -0.08,
    ),
    PlainHandNailSlot(
      finger: NailFinger.middle,
      centerX: 0.487,
      centerY: 0.154,
      width: 0.062,
      height: 0.082,
      angle: 0,
    ),
    PlainHandNailSlot(
      finger: NailFinger.indexFinger,
      centerX: 0.710,
      centerY: 0.216,
      width: 0.065,
      height: 0.077,
      angle: 0.10,
    ),
    PlainHandNailSlot(
      finger: NailFinger.thumb,
      centerX: 0.935,
      centerY: 0.584,
      width: 0.078,
      height: 0.066,
      angle: 0.55,
    ),
  ];

  /// Build paint slots from a look sheet catalog entry (same canvas as the hand).
  static List<PlainHandNailSlot> slotsForLook(NailLook? look) {
    if (look == null || look.nailCrops.isEmpty) {
      return slots;
    }
    return NailFinger.values.map((finger) {
      final crop = look.nailCrops[finger];
      final fallback = slots.firstWhere((slot) => slot.finger == finger);
      if (crop == null) {
        return fallback;
      }
      return PlainHandNailSlot(
        finger: finger,
        centerX: crop.x + crop.w / 2,
        centerY: crop.y + crop.h / 2,
        width: crop.w,
        height: crop.h,
        angle: fallback.angle,
      );
    }).toList();
  }

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
