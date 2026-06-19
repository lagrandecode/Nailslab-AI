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

  return extensionRatio >= placement.minExtensionRatio;
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
