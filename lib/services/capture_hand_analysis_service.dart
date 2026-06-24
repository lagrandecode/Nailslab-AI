import 'dart:typed_data';
import 'dart:ui';

import 'package:hand_detection/hand_detection.dart';
import 'package:image/image.dart' as img;

import '../core/camera/nail_bed_geometry.dart';
import '../models/nail_bed_geometry.dart';
import '../models/captured_nail_session.dart';
import '../models/nail_finger.dart';
import '../models/nail_look.dart';
import 'hand_tracking_service.dart';

/// Finds the hand and nail positions on a still photo (snap flow).
class CaptureHandAnalysisService {
  HandDetector? _detector;

  Future<void> ensureInitialized() async {
    _detector ??= await HandDetector.create(
      mode: HandMode.boxesAndLandmarks,
      detectorConf: 0.35,
      maxDetections: 1,
    );
  }

  Future<CapturedNailSession?> analyze({
    required Uint8List photoBytes,
    required Size viewSize,
    required NailLook look,
    double overlayScale = 1.0,
  }) async {
    await ensureInitialized();
    final detector = _detector;
    if (detector == null) {
      return null;
    }

    final decoded = img.decodeImage(photoBytes);
    if (decoded == null) {
      return null;
    }

    final hands = await detector.detect(photoBytes);
    if (hands.isEmpty || !hands.first.hasLandmarks) {
      return null;
    }

    final hand = hands.first;
    final sourceSize = Size(
      hand.imageWidth.toDouble(),
      hand.imageHeight.toDouble(),
    );
    final mapper = CameraPreviewMapper(
      sourceSize: sourceSize,
      screenSize: viewSize,
    );

    final sourceLandmarks = <HandLandmarkType, Offset>{};
    final mapped = <HandLandmarkType, Offset>{};
    final visibility = <HandLandmarkType, double>{};
    final depth = <HandLandmarkType, double>{};
    for (final landmark in hand.landmarks) {
      if (landmark.visibility < 0.2) {
        continue;
      }
      sourceLandmarks[landmark.type] = Offset(landmark.x, landmark.y);
      mapped[landmark.type] = mapper.mapPoint(landmark.x, landmark.y);
      visibility[landmark.type] = landmark.visibility;
      depth[landmark.type] = landmark.z;
    }

    final frame = TrackedHandFrame(
      landmarks: mapped,
      visibility: visibility,
      handedness: hand.handedness,
      confidence: hand.score,
      sourceLandmarks: sourceLandmarks,
      sourceImageSize: sourceSize,
      landmarkDepth: depth,
    );

    if (countActiveFingers(frame) < 1) {
      return null;
    }

    final metrics = look.cameraNailMetrics;
    final placements = <NailFinger, NailBedGeometry>{};

    for (final placement in NailFingerPlacement.all) {
      if (!isFingerActiveForPaint(frame, placement)) {
        continue;
      }

      final base = computeNailBedGeometry(
        hand: frame,
        placement: placement,
        scale: overlayScale,
        metrics: metrics[placement.finger],
      );
      if (base == null) {
        continue;
      }

      final geometry = attachPerspectiveQuad(
        geometry: base,
        hand: frame,
        placement: placement,
      );

      placements[placement.finger] = geometry;
    }

    if (placements.isEmpty) {
      return null;
    }

    return CapturedNailSession(
      photoBytes: photoBytes,
      imageWidth: decoded.width,
      imageHeight: decoded.height,
      placements: placements,
    );
  }

  Future<void> dispose() async {
    await _detector?.dispose();
    _detector = null;
  }
}
