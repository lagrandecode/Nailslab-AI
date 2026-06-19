import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hand_detection/hand_detection.dart';

import '../models/nail_finger.dart';

/// Maps detector coordinates to on-screen preview coordinates (BoxFit.cover).
class CameraPreviewMapper {
  CameraPreviewMapper({
    required this.sourceSize,
    required this.screenSize,
    this.mirrorHorizontally = false,
  });

  final Size sourceSize;
  final Size screenSize;
  final bool mirrorHorizontally;

  Offset mapPoint(double x, double y) {
    final mappedX = mirrorHorizontally ? sourceSize.width - x : x;

    final scale = math.max(
      screenSize.width / sourceSize.width,
      screenSize.height / sourceSize.height,
    );
    final scaledWidth = sourceSize.width * scale;
    final scaledHeight = sourceSize.height * scale;
    final dx = (screenSize.width - scaledWidth) / 2;
    final dy = (screenSize.height - scaledHeight) / 2;
    return Offset(mappedX * scale + dx, y * scale + dy);
  }
}

class HandTrackingService {
  HandDetector? _detector;
  bool _detecting = false;

  Future<void> ensureInitialized() async {
    _detector ??= await HandDetector.create(
      mode: HandMode.boxesAndLandmarks,
      detectorConf: 0.35,
      maxDetections: 1,
    );
  }

  Future<TrackedHandFrame?> detect({
    required CameraImage image,
    required CameraController controller,
    required Size screenSize,
  }) async {
    final detector = _detector;
    if (detector == null || _detecting) {
      return null;
    }

    _detecting = true;
    try {
      final isFrontCamera =
          controller.description.lensDirection == CameraLensDirection.front;

      final rotation = rotationForFrame(
        width: image.width,
        height: image.height,
        sensorOrientation: controller.description.sensorOrientation,
        isFrontCamera: isFrontCamera,
        deviceOrientation: DeviceOrientation.portraitUp,
      );

      const maxDim = 640;
      final hands = await detector.detectFromCameraImage(
        image,
        rotation: rotation,
        maxDim: maxDim,
      );

      if (hands.isEmpty || !hands.first.hasLandmarks) {
        return null;
      }

      final hand = hands.first;
      final sourceSize = Size(hand.imageWidth.toDouble(), hand.imageHeight.toDouble());
      final mirrorHorizontally = isFrontCamera && Platform.isAndroid;

      final mapper = CameraPreviewMapper(
        sourceSize: sourceSize,
        screenSize: screenSize,
        mirrorHorizontally: mirrorHorizontally,
      );

      final mapped = <HandLandmarkType, Offset>{};
      final visibility = <HandLandmarkType, double>{};
      for (final landmark in hand.landmarks) {
        if (landmark.visibility < 0.2) {
          continue;
        }
        mapped[landmark.type] = mapper.mapPoint(landmark.x, landmark.y);
        visibility[landmark.type] = landmark.visibility;
      }

      final frame = TrackedHandFrame(
        landmarks: mapped,
        visibility: visibility,
        handedness: hand.handedness,
        confidence: hand.score,
      );

      if (countActiveFingers(frame) < 1) {
        return null;
      }

      return frame;
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('Hand tracking error: $error');
        debugPrint('$stack');
      }
      return null;
    } finally {
      _detecting = false;
    }
  }

  Future<void> dispose() async {
    await _detector?.dispose();
    _detector = null;
  }
}
