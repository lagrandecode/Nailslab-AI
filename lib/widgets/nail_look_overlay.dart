import 'package:flutter/material.dart';

import '../core/camera/hand_guide_layout.dart';
import '../models/nail_look.dart';

/// Live nail art overlay aligned to the hand guide (black PNG bg keyed via screen blend).
class NailLookOverlay extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final width = height * HandGuideLayout.aspectRatio;
    final visibleHeight = height * (1 - look.cropBottomFraction);
    final offsetY = look.offsetY * height;

    return Transform.scale(
      scale: scale,
      child: Transform.translate(
        offset: Offset(0, offsetY),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(isLeftHand ? 1.0 : -1.0, 1.0, 1.0),
          child: SizedBox(
            width: width,
            height: visibleHeight,
            child: ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                child: Image.asset(
                  look.overlayAsset,
                  width: width,
                  height: height,
                  fit: BoxFit.contain,
                  alignment: Alignment.topCenter,
                  color: Colors.white,
                  colorBlendMode: BlendMode.screen,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
