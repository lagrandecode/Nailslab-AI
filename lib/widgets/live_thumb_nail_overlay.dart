import 'package:flutter/material.dart';

import '../core/camera/nail_bed_geometry.dart';
import '../core/camera/nail_warp_painter.dart';
import '../core/camera/thumb_nail_profile.dart';
import '../models/nail_finger.dart';

/// Thumb-only live AR — YouCam-style color shader on the detected nail bed.
class LiveThumbNailOverlay extends StatelessWidget {
  const LiveThumbNailOverlay({
    super.key,
    required this.hand,
    required this.polishColor,
    this.finish = NailPolishFinish.cream,
    this.opacity = 0.76,
  });

  final TrackedHandFrame hand;
  final Color polishColor;
  final NailPolishFinish finish;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    if (!isThumbVisibleForAr(hand)) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _LiveThumbNailPainter(
            hand: hand,
            polishColor: polishColor,
            finish: finish,
            opacity: opacity,
          ),
        ),
      ),
    );
  }
}

class _LiveThumbNailPainter extends CustomPainter {
  _LiveThumbNailPainter({
    required this.hand,
    required this.polishColor,
    required this.finish,
    required this.opacity,
  });

  final TrackedHandFrame hand;
  final Color polishColor;
  final NailPolishFinish finish;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = computeThumbNailBedGeometry(
          hand: hand,
          scale: 1.0,
          metrics: ThumbNailProfile.metrics,
        ) ??
        hand.nailGeometry[NailFinger.thumb];
    if (geometry == null) {
      return;
    }

    paintNailColorShader(
      canvas,
      geometry,
      color: polishColor,
      opacity: opacity,
      finish: finish,
    );
  }

  @override
  bool shouldRepaint(covariant _LiveThumbNailPainter oldDelegate) {
    return oldDelegate.hand != hand ||
        oldDelegate.polishColor != polishColor ||
        oldDelegate.finish != finish ||
        oldDelegate.opacity != opacity;
  }
}
