import 'package:flutter/material.dart';

import '../core/camera/nail_bed_geometry.dart';
import '../core/camera/nail_warp_painter.dart';
import '../core/theme/app_colors.dart';
import '../models/nail_finger.dart';

/// Live AR polish mask on detected nail beds (no cherry / design PNG).
class LiveNailMaskOverlay extends StatelessWidget {
  const LiveNailMaskOverlay({
    super.key,
    required this.hand,
    this.maskColor = AppColors.primary,
    this.opacity = 0.58,
  });

  final TrackedHandFrame hand;
  final Color maskColor;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _LiveNailMaskPainter(
            hand: hand,
            maskColor: maskColor,
            opacity: opacity,
          ),
        ),
      ),
    );
  }
}

class _LiveNailMaskPainter extends CustomPainter {
  _LiveNailMaskPainter({
    required this.hand,
    required this.maskColor,
    required this.opacity,
  });

  final TrackedHandFrame hand;
  final Color maskColor;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    for (final placement in NailFingerPlacement.all) {
      if (!isFingerActiveForPaint(hand, placement)) {
        continue;
      }

      final geometry = hand.nailGeometry[placement.finger] ??
          computeNailBedGeometry(
            hand: hand,
            placement: placement,
            scale: 1.0,
          );
      if (geometry == null) {
        continue;
      }

      paintNailMask(
        canvas,
        geometry,
        color: maskColor,
        opacity: opacity,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LiveNailMaskPainter oldDelegate) {
    return oldDelegate.hand != hand ||
        oldDelegate.maskColor != maskColor ||
        oldDelegate.opacity != opacity;
  }
}
