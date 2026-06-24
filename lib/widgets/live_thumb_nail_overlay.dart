import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/camera/nail_bed_geometry.dart';
import '../core/camera/nail_warp_painter.dart';
import '../core/camera/thumb_nail_profile.dart';
import '../core/theme/app_colors.dart';
import '../models/nail_finger.dart';
import '../services/thumb_nail_asset_cache.dart';

/// Thumb-only live AR — warps [assets/real.png] onto the detected nail bed.
class LiveThumbNailOverlay extends StatefulWidget {
  const LiveThumbNailOverlay({
    super.key,
    required this.hand,
  });

  final TrackedHandFrame hand;

  @override
  State<LiveThumbNailOverlay> createState() => _LiveThumbNailOverlayState();
}

class _LiveThumbNailOverlayState extends State<LiveThumbNailOverlay> {
  @override
  void initState() {
    super.initState();
    _ensureAssets();
  }

  Future<void> _ensureAssets() async {
    await ThumbNailAssetCache.instance.preload();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isThumbVisibleForAr(widget.hand)) {
      return const SizedBox.shrink();
    }

    final cache = ThumbNailAssetCache.instance;
    final texture = cache.texture;
    final mask = cache.mask;

    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _LiveThumbNailPainter(
            hand: widget.hand,
            texture: texture,
            mask: mask,
          ),
        ),
      ),
    );
  }
}

class _LiveThumbNailPainter extends CustomPainter {
  _LiveThumbNailPainter({
    required this.hand,
    required this.texture,
    required this.mask,
  });

  final TrackedHandFrame hand;
  final ui.Image? texture;
  final ui.Image? mask;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = hand.nailGeometry[NailFinger.thumb] ??
        computeThumbNailBedGeometry(
          hand: hand,
          scale: 1.0,
          metrics: ThumbNailProfile.metrics,
        );
    if (geometry == null) {
      return;
    }

    if (texture != null) {
      paintThumbNailTexture(canvas, texture!, geometry);
      return;
    }

    if (mask != null) {
      paintThumbPolish(
        canvas,
        geometry,
        maskImage: mask,
        color: AppColors.primary,
        opacity: 0.82,
      );
      return;
    }

    paintNailMask(
      canvas,
      flatGeometryFromPerspective(geometry),
      color: AppColors.primary,
      opacity: 0.65,
    );
  }

  @override
  bool shouldRepaint(covariant _LiveThumbNailPainter oldDelegate) {
    return oldDelegate.hand != hand ||
        oldDelegate.texture != texture ||
        oldDelegate.mask != mask;
  }
}
