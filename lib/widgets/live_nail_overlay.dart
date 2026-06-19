import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/camera/nail_bed_geometry.dart';
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
    for (final placement in NailFingerPlacement.all) {
      if (!isFingerActiveForPaint(hand, placement)) {
        continue;
      }

      final nailImage = fingerNails[placement.finger];
      if (nailImage == null) {
        continue;
      }

      final geometry = computeNailBedGeometry(
        hand: hand,
        placement: placement,
        scale: scale,
      );
      if (geometry == null) {
        continue;
      }

      canvas.save();
      canvas.translate(geometry.center.dx, geometry.center.dy);
      canvas.rotate(geometry.angle);

      final dstRect = Rect.fromCenter(
        center: Offset.zero,
        width: geometry.width,
        height: geometry.height,
      );
      canvas.clipPath(buildNailClipPath(geometry.width, geometry.height));

      final srcRect = Rect.fromLTWH(
        0,
        0,
        nailImage.width.toDouble(),
        nailImage.height.toDouble(),
      );

      final paint = Paint()
        ..filterQuality = FilterQuality.high
        ..isAntiAlias = true;
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
