import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/camera/hand_guide_layout.dart';
import '../models/nail_look.dart';
import '../services/nail_look_image_cache.dart';

/// Nail look overlay positioned with a hand-tracking transform matrix.
class TrackedNailLookOverlay extends StatefulWidget {
  const TrackedNailLookOverlay({
    super.key,
    required this.look,
    required this.transform,
    this.scale = 1.0,
  });

  final NailLook look;
  final Matrix4 transform;
  final double scale;

  @override
  State<TrackedNailLookOverlay> createState() => _TrackedNailLookOverlayState();
}

class _TrackedNailLookOverlayState extends State<TrackedNailLookOverlay> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(TrackedNailLookOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.look.overlayAsset != widget.look.overlayAsset) {
      _load();
    }
  }

  Future<void> _load() async {
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

    final height = MediaQuery.sizeOf(context).height * HandGuideLayout.heightScreenFactor;
    final width = height * HandGuideLayout.aspectRatio;
    final overlaySize = Size(width * widget.scale, height * widget.scale);

    final matrix = Matrix4.copy(widget.transform)
      ..scaleByDouble(widget.scale, widget.scale, 1, 1);

    return Transform(
      transform: matrix,
      child: SizedBox(
        width: overlaySize.width,
        height: overlaySize.height,
        child: RawImage(
          image: image,
          fit: BoxFit.contain,
          alignment: Alignment.topCenter,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
