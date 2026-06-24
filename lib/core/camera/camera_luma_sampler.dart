import 'dart:math' as math;
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:hand_detection/hand_detection.dart';

/// Samples Y-channel brightness from a camera frame in detection-image space
/// (same rotated + downscaled coordinates as hand_detection landmarks).
class CameraLumaSampler {
  CameraLumaSampler({
    required this.image,
    required this.rotation,
    required this.detectionSize,
    required this.maxDim,
  });

  final CameraImage image;
  final CameraFrameRotation? rotation;
  final math.Rectangle<int> detectionSize;
  final int maxDim;

  int get _rotatedWidth {
    if (rotation == CameraFrameRotation.cw90 ||
        rotation == CameraFrameRotation.cw270) {
      return image.height;
    }
    return image.width;
  }

  int get _rotatedHeight {
    if (rotation == CameraFrameRotation.cw90 ||
        rotation == CameraFrameRotation.cw270) {
      return image.width;
    }
    return image.height;
  }

  double get _scale {
    final longest = math.max(_rotatedWidth, _rotatedHeight);
    if (longest <= maxDim) {
      return 1;
    }
    return maxDim / longest;
  }

  /// Returns average luma in detection space, or null when out of bounds.
  double? sample(double x, double y) {
    final cam = _detectionToCamera(x, y);
    if (cam == null) {
      return null;
    }
    return _lumaAt(cam.dx.round(), cam.dy.round());
  }

  /// Samples along a segment in detection space.
  List<double> sampleLine(Offset start, Offset end, {int steps = 16}) {
    final values = <double>[];
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = start.dx + (end.dx - start.dx) * t;
      final y = start.dy + (end.dy - start.dy) * t;
      final luma = sample(x, y);
      if (luma != null) {
        values.add(luma);
      }
    }
    return values;
  }

  Offset? _detectionToCamera(double dx, double dy) {
    if (dx < 0 ||
        dy < 0 ||
        dx >= detectionSize.width ||
        dy >= detectionSize.height) {
      return null;
    }

    final rx = dx / _scale;
    final ry = dy / _scale;

    return switch (rotation) {
      CameraFrameRotation.cw90 => Offset(
          rx,
          image.width - 1 - ry,
        ),
      CameraFrameRotation.cw270 => Offset(
          image.height - 1 - rx,
          ry,
        ),
      CameraFrameRotation.cw180 => Offset(
          image.width - 1 - rx,
          image.height - 1 - ry,
        ),
      null => Offset(rx, ry),
    };
  }

  double? _lumaAt(int x, int y) {
    if (x < 0 || y < 0 || x >= image.width || y >= image.height) {
      return null;
    }
    final plane = image.planes.first;
    final index = y * plane.bytesPerRow + x * (plane.bytesPerPixel ?? 1);
    if (index < 0 || index >= plane.bytes.length) {
      return null;
    }
    return plane.bytes[index].toDouble();
  }
}
