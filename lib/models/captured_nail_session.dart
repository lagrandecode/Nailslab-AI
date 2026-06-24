import 'dart:typed_data';

import 'nail_bed_geometry.dart';
import 'nail_finger.dart';

/// One captured hand photo with editable nail placements (YouCam-style).
class CapturedNailSession {
  const CapturedNailSession({
    required this.photoBytes,
    required this.imageWidth,
    required this.imageHeight,
    required this.placements,
  });

  final Uint8List photoBytes;
  final int imageWidth;
  final int imageHeight;
  final Map<NailFinger, NailBedGeometry> placements;

  CapturedNailSession copyWith({
    Map<NailFinger, NailBedGeometry>? placements,
  }) {
    return CapturedNailSession(
      photoBytes: photoBytes,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      placements: placements ?? this.placements,
    );
  }
}
