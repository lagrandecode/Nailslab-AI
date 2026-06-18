import 'package:flutter/material.dart';

import 'hand_trace_painter.dart';

/// Vector hand guide for the camera overlay.
class HandTraceOverlay extends StatelessWidget {
  const HandTraceOverlay({
    super.key,
    required this.isLeftHand,
    required this.height,
    this.scale = 1.0,
  });

  final bool isLeftHand;
  final double height;
  final double scale;

  static const double _aspectRatio = 0.58;

  @override
  Widget build(BuildContext context) {
    final width = height * _aspectRatio;

    return Transform.scale(
      scale: scale,
      child: CustomPaint(
        painter: HandTracePainter(isLeftHand: isLeftHand),
        size: Size(width, height),
      ),
    );
  }
}
