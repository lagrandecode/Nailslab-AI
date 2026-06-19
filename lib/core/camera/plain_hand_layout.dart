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
}

abstract final class PlainHandLayout {
  static const lightAsset = 'assets/hand3.png';
  static const brownAsset = 'assets/handbrown.png';
  static const aspectRatio = 375 / 666;

  /// Measured from hand3.png nail-bed pixels (not the geometric catalog arc).
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

  static Rect fitHandRect(Size viewport) {
    final viewportAspect = viewport.width / viewport.height;
    if (viewportAspect > aspectRatio) {
      final height = viewport.height * 0.82;
      final width = height * aspectRatio;
      return Rect.fromLTWH(
        (viewport.width - width) / 2,
        viewport.height * 0.08,
        width,
        height,
      );
    }
    final width = viewport.width * 0.88;
    final height = width / aspectRatio;
    return Rect.fromLTWH(
      (viewport.width - width) / 2,
      (viewport.height - height) / 2,
      width,
      height,
    );
  }
}
