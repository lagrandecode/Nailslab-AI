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
  });

  final NailLook look;
  final Matrix4 transform;

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

    final layoutHeight = MediaQuery.sizeOf(context).height * HandGuideLayout.heightScreenFactor;
    final layoutWidth = layoutHeight * HandGuideLayout.aspectRatio;

    return Transform(
      transform: widget.transform,
      child: SizedBox(
        width: layoutWidth,
        height: layoutHeight,
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
