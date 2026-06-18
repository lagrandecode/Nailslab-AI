import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hand_detection/hand_detection.dart';

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

class TrackedHandFrame {
  const TrackedHandFrame({
    required this.landmarks,
    required this.confidence,
    this.handedness,
  });

  final Map<HandLandmarkType, Offset> landmarks;
  final Handedness? handedness;
  final double confidence;
}

class HandTrackingService {
  HandDetector? _detector;
  bool _detecting = false;

  Future<void> ensureInitialized() async {
    _detector ??= await HandDetector.create(
      mode: HandMode.boxesAndLandmarks,
      detectorConf: 0.5,
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
      final sourceSize = detectionSize(
        width: image.width,
        height: image.height,
        rotation: rotation,
        maxDim: maxDim,
      );

      final hands = await detector.detectFromCameraImage(
        image,
        rotation: rotation,
        maxDim: maxDim,
      );

      if (hands.isEmpty || !hands.first.hasLandmarks) {
        return null;
      }

      final hand = hands.first;
      final mirrorHorizontally = isFrontCamera && Platform.isAndroid;

      final mapper = CameraPreviewMapper(
        sourceSize: sourceSize,
        screenSize: screenSize,
        mirrorHorizontally: mirrorHorizontally,
      );

      final mapped = <HandLandmarkType, Offset>{};
      for (final landmark in hand.landmarks) {
        if (landmark.visibility < 0.4) {
          continue;
        }
        mapped[landmark.type] = mapper.mapPoint(landmark.x, landmark.y);
      }

      if (mapped.length < 8) {
        return null;
      }

      return TrackedHandFrame(
        landmarks: mapped,
        handedness: hand.handedness,
        confidence: hand.score,
      );
    } catch (_) {
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

/// Computes transform to align a nail overlay image with detected hand landmarks.
Matrix4 computeNailOverlayTransform({
  required TrackedHandFrame hand,
  required Size overlaySize,
}) {
  Offset? point(HandLandmarkType type) => hand.landmarks[type];

  final wrist = point(HandLandmarkType.wrist);
  final indexMcp = point(HandLandmarkType.indexFingerMCP);
  final middleTip = point(HandLandmarkType.middleFingerTip);
  final pinkyMcp = point(HandLandmarkType.pinkyMCP);

  if (wrist == null || indexMcp == null || middleTip == null || pinkyMcp == null) {
    return Matrix4.identity();
  }

  final palmCenter = Offset(
    (indexMcp.dx + pinkyMcp.dx) / 2,
    (indexMcp.dy + pinkyMcp.dy) / 2,
  );
  final handSpan = (indexMcp - pinkyMcp).distance.clamp(40.0, 600.0);
  const referenceSpan = 220.0;
  final scale = handSpan / referenceSpan;

  final upVector = middleTip - wrist;
  final angle = math.atan2(upVector.dy, upVector.dx) - (math.pi / 2);

  final flip = hand.handedness == Handedness.left ? 1.0 : -1.0;

  return Matrix4.identity()
    ..translateByDouble(palmCenter.dx, palmCenter.dy, 0, 1)
    ..rotateZ(angle)
    ..scaleByDouble(scale * flip, scale, 1, 1)
    ..translateByDouble(-overlaySize.width * 0.5, -overlaySize.height * 0.72, 0, 1);
}
