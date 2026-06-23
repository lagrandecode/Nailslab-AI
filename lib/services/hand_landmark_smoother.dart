import 'dart:ui';

import 'package:hand_detection/hand_detection.dart';

import '../models/nail_finger.dart';

/// Exponential smoothing to reduce jitter between camera frames.
class HandLandmarkSmoother {
  TrackedHandFrame? _previous;

  static const double _alpha = 0.50;
  static const double _depthAlpha = 0.38;

  TrackedHandFrame smooth(TrackedHandFrame current) {
    final previous = _previous;
    if (previous == null) {
      _previous = current;
      return current;
    }

    final smoothed = <HandLandmarkType, Offset>{};
    for (final entry in current.landmarks.entries) {
      final prior = previous.landmarks[entry.key];
      smoothed[entry.key] = prior == null
          ? entry.value
          : Offset.lerp(prior, entry.value, _alpha)!;
    }

    final sourceSmoothed = <HandLandmarkType, Offset>{};
    for (final entry in current.sourceLandmarks.entries) {
      final prior = previous.sourceLandmarks[entry.key];
      sourceSmoothed[entry.key] = prior == null
          ? entry.value
          : Offset.lerp(prior, entry.value, _alpha)!;
    }

    final depthSmoothed = <HandLandmarkType, double>{};
    for (final entry in current.landmarkDepth.entries) {
      final prior = previous.landmarkDepth[entry.key];
      depthSmoothed[entry.key] = prior == null
          ? entry.value
          : prior + (entry.value - prior) * _depthAlpha;
    }

    final frame = TrackedHandFrame(
      landmarks: smoothed,
      visibility: current.visibility,
      handedness: current.handedness,
      confidence: current.confidence,
      sourceLandmarks: sourceSmoothed,
      sourceImageSize: current.sourceImageSize,
      landmarkDepth: depthSmoothed,
      nailGeometry: current.nailGeometry,
    );
    _previous = frame;
    return frame;
  }

  void reset() {
    _previous = null;
  }
}
