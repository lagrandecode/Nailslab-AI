import 'package:flutter/material.dart';

import '../constants/asset_paths.dart';

/// Reference hand trace extracted from the NailLab camera guide.
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

  static const double _aspectRatio = 441 / 734;

  @override
  Widget build(BuildContext context) {
    final width = height * _aspectRatio;

    return Transform.scale(
      scale: scale,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(isLeftHand ? 1.0 : -1.0, 1.0, 1.0),
        child: Image.asset(
          AssetPaths.handTraceLeft,
          width: width,
          height: height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
