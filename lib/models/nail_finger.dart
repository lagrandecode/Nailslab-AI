import 'dart:ui';

import 'package:hand_detection/hand_detection.dart';

enum NailFinger {
  thumb,
  indexFinger,
  middle,
  ring,
  pinky,
}

class NailFingerCrop {
  const NailFingerCrop({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  final double x;
  final double y;
  final double w;
  final double h;

  factory NailFingerCrop.fromJson(Map<String, dynamic> json) {
    return NailFingerCrop(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      w: (json['w'] as num).toDouble(),
      h: (json['h'] as num).toDouble(),
    );
  }

  Rect rectForSize(Size sourceSize) {
    return Rect.fromLTWH(
      x * sourceSize.width,
      y * sourceSize.height,
      w * sourceSize.width,
      h * sourceSize.height,
    );
  }
}

/// Per-finger sizing for live camera, measured from the baked plain-hand look.
class CameraNailMetrics {
  const CameraNailMetrics({
    required this.widthOverBed,
    this.heightOverBed = 1.0,
    this.centerAlongBed = 0.58,
  });

  /// Nail width ÷ reference nail-bed length on the baked hand photo.
  final double widthOverBed;
  /// Nail height ÷ reference nail-bed length on the baked hand photo.
  final double heightOverBed;
  /// Position along the tip–joint axis (0 = joint, 1 = tip).
  final double centerAlongBed;

  factory CameraNailMetrics.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('width_over_bed')) {
      return CameraNailMetrics(
        widthOverBed: (json['width_over_bed'] as num).toDouble(),
        heightOverBed: (json['height_over_bed'] as num?)?.toDouble() ?? 1.0,
        centerAlongBed: (json['center_along_bed'] as num?)?.toDouble() ?? 0.58,
      );
    }

    // Legacy catalog entries sized by finger width — convert approximately.
    final widthOverFinger = (json['width_over_finger'] as num?)?.toDouble() ?? 0.5;
    final heightOverWidth = (json['height_over_width'] as num?)?.toDouble() ?? 1.1;
    return CameraNailMetrics(
      widthOverBed: widthOverFinger * 0.55,
      heightOverBed: heightOverWidth * 0.45,
      centerAlongBed: (json['center_along_bed'] as num?)?.toDouble() ?? 0.58,
    );
  }
}

class NailFingerPlacement {
  const NailFingerPlacement({
    required this.finger,
    required this.tip,
    required this.joint,
    required this.pip,
    required this.mcp,
    this.minExtensionRatio = 1.15,
  });

  final NailFinger finger;
  final HandLandmarkType tip;
  final HandLandmarkType joint;
  final HandLandmarkType pip;
  final HandLandmarkType mcp;
  final double minExtensionRatio;

  static const List<NailFingerPlacement> all = [
    NailFingerPlacement(
      finger: NailFinger.thumb,
      tip: HandLandmarkType.thumbTip,
      joint: HandLandmarkType.thumbIP,
      pip: HandLandmarkType.thumbMCP,
      mcp: HandLandmarkType.thumbCMC,
      minExtensionRatio: 1.05,
    ),
    NailFingerPlacement(
      finger: NailFinger.indexFinger,
      tip: HandLandmarkType.indexFingerTip,
      joint: HandLandmarkType.indexFingerDIP,
      pip: HandLandmarkType.indexFingerPIP,
      mcp: HandLandmarkType.indexFingerMCP,
    ),
    NailFingerPlacement(
      finger: NailFinger.middle,
      tip: HandLandmarkType.middleFingerTip,
      joint: HandLandmarkType.middleFingerDIP,
      pip: HandLandmarkType.middleFingerPIP,
      mcp: HandLandmarkType.middleFingerMCP,
    ),
    NailFingerPlacement(
      finger: NailFinger.ring,
      tip: HandLandmarkType.ringFingerTip,
      joint: HandLandmarkType.ringFingerDIP,
      pip: HandLandmarkType.ringFingerPIP,
      mcp: HandLandmarkType.ringFingerMCP,
    ),
    NailFingerPlacement(
      finger: NailFinger.pinky,
      tip: HandLandmarkType.pinkyTip,
      joint: HandLandmarkType.pinkyDIP,
      pip: HandLandmarkType.pinkyPIP,
      mcp: HandLandmarkType.pinkyMCP,
    ),
  ];
}

/// Returns true when this finger is visible and extended (pointing), not curled.
bool isFingerActiveForPaint(
  TrackedHandFrame hand,
  NailFingerPlacement placement,
) {
  final tip = hand.landmarks[placement.tip];
  final joint = hand.landmarks[placement.joint];
  final pip = hand.landmarks[placement.pip];
  final mcp = hand.landmarks[placement.mcp];
  if (tip == null || joint == null || pip == null || mcp == null) {
    return false;
  }

  if ((hand.visibility[placement.tip] ?? 0) < 0.4) {
    return false;
  }
  if ((hand.visibility[placement.joint] ?? 0) < 0.25) {
    return false;
  }

  final segmentLength = (tip - joint).distance;
  if (segmentLength < 8) {
    return false;
  }

  final pipToMcp = (pip - mcp).distance.clamp(5.0, 999.0);
  final tipToMcp = (tip - mcp).distance;
  final extensionRatio = tipToMcp / pipToMcp;

  final visibleTips = NailFingerPlacement.all
      .where(
        (p) =>
            hand.landmarks[p.tip] != null && (hand.visibility[p.tip] ?? 0) >= 0.45,
      )
      .length;
  final minRatio = visibleTips >= 4 ? 1.06 : placement.minExtensionRatio;

  return extensionRatio >= minRatio;
}

int countActiveFingers(TrackedHandFrame hand) {
  var count = 0;
  for (final placement in NailFingerPlacement.all) {
    if (isFingerActiveForPaint(hand, placement)) {
      count++;
    }
  }
  return count;
}

/// Shared hand frame used by tracking + nail painting.
class TrackedHandFrame {
  const TrackedHandFrame({
    required this.landmarks,
    required this.visibility,
    required this.confidence,
    this.handedness,
  });

  final Map<HandLandmarkType, Offset> landmarks;
  final Map<HandLandmarkType, double> visibility;
  final Handedness? handedness;
  final double confidence;
}
