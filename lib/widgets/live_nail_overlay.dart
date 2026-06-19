import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hand_detection/hand_detection.dart';

import '../models/nail_finger.dart';
import '../models/nail_look.dart';
import '../services/nail_look_image_cache.dart';

/// Paints each nail design onto matching extended fingertips in real time.
class LiveNailOverlay extends StatefulWidget {
  const LiveNailOverlay({
    super.key,
    required this.look,
    required this.hand,
    this.scale = 1.0,
  });

  final NailLook look;
  final TrackedHandFrame hand;
  final double scale;

  @override
  State<LiveNailOverlay> createState() => _LiveNailOverlayState();
}

class _LiveNailOverlayState extends State<LiveNailOverlay> {
  Map<NailFinger, ui.Image>? _fingerNails;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(LiveNailOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.look.overlayAsset != widget.look.overlayAsset) {
      _load();
    }
  }

  Future<void> _load() async {
    final nails = await NailLookImageCache.instance.loadFingerNails(widget.look);
    if (mounted) {
      setState(() => _fingerNails = nails);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fingerNails = _fingerNails;
    if (fingerNails == null || fingerNails.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _LiveNailPainter(
            hand: widget.hand,
            fingerNails: fingerNails,
            scale: widget.scale,
          ),
        ),
      ),
    );
  }
}

class _LiveNailPainter extends CustomPainter {
  _LiveNailPainter({
    required this.hand,
    required this.fingerNails,
    required this.scale,
  });

  final TrackedHandFrame hand;
  final Map<NailFinger, ui.Image> fingerNails;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    Offset? point(HandLandmarkType type) => hand.landmarks[type];

    for (final placement in NailFingerPlacement.all) {
      if (!isFingerActiveForPaint(hand, placement)) {
        continue;
      }

      final nailImage = fingerNails[placement.finger];
      final tip = point(placement.tip);
      final joint = point(placement.joint);
      if (nailImage == null || tip == null || joint == null) {
        continue;
      }

      final segment = tip - joint;
      final segmentLength = segment.distance;
      if (segmentLength < 8) {
        continue;
      }

      final direction = segment / segmentLength;
      // Flip nail art 180° so the design faces the correct way on the finger.
      final angle = math.atan2(direction.dy, direction.dx) - math.pi / 2 + math.pi;

      final nailWidth = segmentLength * 0.92 * scale;
      final nailHeight = segmentLength * 1.35 * scale;
      final anchor = tip - direction * (nailHeight * 0.28);

      canvas.save();
      canvas.translate(anchor.dx, anchor.dy);
      canvas.rotate(angle);

      final dstRect = Rect.fromCenter(
        center: Offset.zero,
        width: nailWidth,
        height: nailHeight,
      );
      final clipPath = Path()..addOval(dstRect.inflate(nailWidth * 0.04));
      canvas.clipPath(clipPath);

      final srcRect = Rect.fromLTWH(
        0,
        0,
        nailImage.width.toDouble(),
        nailImage.height.toDouble(),
      );

      final paint = Paint()..filterQuality = FilterQuality.high;
      canvas.drawImageRect(nailImage, srcRect, dstRect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LiveNailPainter oldDelegate) {
    return oldDelegate.hand != hand ||
        oldDelegate.fingerNails != fingerNails ||
        oldDelegate.scale != scale;
  }
}
