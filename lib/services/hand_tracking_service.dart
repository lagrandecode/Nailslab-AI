import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hand_detection/hand_detection.dart';

import '../models/nail_finger.dart';
import 'hand_landmark_smoother.dart';
import 'nail_plate_refiner.dart';

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

  double get scale => math.max(
        screenSize.width / sourceSize.width,
        screenSize.height / sourceSize.height,
      );

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
  final _smoother = HandLandmarkSmoother();
  final _nailRefiner = NailPlateRefiner();

  static const int _maxDim = 640;

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
    Map<NailFinger, CameraNailMetrics?> metricsByFinger = const {},
    double overlayScale = 1.0,
    bool thumbOnly = false,
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

      const maxDim = _maxDim;
      final hands = await detector.detectFromCameraImage(
        image,
        rotation: rotation,
        maxDim: maxDim,
      );

      if (hands.isEmpty || !hands.first.hasLandmarks) {
        return null;
      }

      final hand = hands.first;
      final sourceSize = detectionSize(
        width: image.width,
        height: image.height,
        rotation: rotation,
        maxDim: maxDim,
      );
      final mirrorHorizontally = isFrontCamera && Platform.isAndroid;

      final mapper = CameraPreviewMapper(
        sourceSize: sourceSize,
        screenSize: screenSize,
        mirrorHorizontally: mirrorHorizontally,
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

      var frame = TrackedHandFrame(
        landmarks: mapped,
        visibility: visibility,
        handedness: hand.handedness,
        confidence: hand.score,
        sourceLandmarks: sourceLandmarks,
        sourceImageSize: sourceSize,
        landmarkDepth: depth,
      );

      if (thumbOnly) {
        if (!isThumbVisibleForAr(frame)) {
          return null;
        }
      } else if (countActiveFingers(frame) < 1) {
        return null;
      }

      frame = _smoother.smooth(frame);

      final nailGeometry = _nailRefiner.refine(
        hand: frame,
        sourceLandmarks: frame.sourceLandmarks,
        sourceImageSize: sourceSize,
        mapper: mapper,
        image: image,
        rotation: rotation,
        maxDim: maxDim,
        overlayScale: overlayScale,
        metricsByFinger: metricsByFinger,
        thumbOnly: thumbOnly,
      );

      return TrackedHandFrame(
        landmarks: frame.landmarks,
        visibility: frame.visibility,
        handedness: frame.handedness,
        confidence: frame.confidence,
        sourceLandmarks: frame.sourceLandmarks,
        sourceImageSize: sourceSize,
        landmarkDepth: frame.landmarkDepth,
        nailGeometry: nailGeometry,
      );
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
    _smoother.reset();
    _nailRefiner.reset();
    await _detector?.dispose();
    _detector = null;
  }
}
