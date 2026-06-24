import 'package:hand_detection/hand_detection.dart';

import '../../models/nail_finger.dart';

/// Reference assets and sizing tuned from [assets/real.png] nail plate photo.
abstract final class ThumbNailProfile {
  static const sourceAsset = 'assets/real.png';
  static const maskAsset = 'assets/looks/reference/thumb_nail_mask.png';
  static const textureAsset = 'assets/looks/reference/thumb_nail_extracted.png';

  /// Sized to real thumb nail plate — not the full distal phalanx.
  static const metrics = CameraNailMetrics(
    widthOverBed: 0.72,
    heightOverBed: 0.86,
    centerAlongBed: 0.52,
    angleOffset: -0.18,
    acrossOffsetBed: 0.04,
  );

  static const thumbPlacement = NailFingerPlacement(
    finger: NailFinger.thumb,
    tip: HandLandmarkType.thumbTip,
    joint: HandLandmarkType.thumbIP,
    pip: HandLandmarkType.thumbMCP,
    mcp: HandLandmarkType.thumbCMC,
    minExtensionRatio: 1.02,
  );
}
