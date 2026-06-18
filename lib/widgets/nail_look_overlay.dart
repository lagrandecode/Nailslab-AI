import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/camera/hand_guide_layout.dart';
import '../models/nail_look.dart';
import '../services/nail_look_image_cache.dart';

/// Static nail look overlay (fallback when hand is not detected yet).
class NailLookOverlay extends StatefulWidget {
  const NailLookOverlay({
    super.key,
    required this.look,
    required this.isLeftHand,
    required this.height,
    this.scale = 1.0,
  });

  final NailLook look;
  final bool isLeftHand;
  final double height;
  final double scale;

  @override
  State<NailLookOverlay> createState() => _NailLookOverlayState();
}

class _NailLookOverlayState extends State<NailLookOverlay> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _loadOverlay();
  }

  @override
  void didUpdateWidget(NailLookOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.look.overlayAsset != widget.look.overlayAsset) {
      _loadOverlay();
    }
  }

  Future<void> _loadOverlay() async {
    final image = await NailLookImageCache.instance.load(widget.look);
    if (mounted) {
      setState(() => _image = image);
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) {
      return const SizedBox.shrink();
    }

    final width = widget.height * HandGuideLayout.aspectRatio;
    final offsetY = widget.look.offsetY * widget.height;

    return Transform.scale(
      scale: widget.scale,
      child: Transform.translate(
        offset: Offset(0, offsetY),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(widget.isLeftHand ? 1.0 : -1.0, 1.0, 1.0),
          child: SizedBox(
            width: width,
            height: widget.height,
            child: RawImage(
              image: image,
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}
