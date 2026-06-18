import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/asset_paths.dart';

/// Hand camera guide from bundled SVG asset.
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

  static const double _aspectRatio = 1024 / 1536;

  @override
  Widget build(BuildContext context) {
    final width = height * _aspectRatio;

    return Transform.scale(
      scale: scale,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(isLeftHand ? 1.0 : -1.0, 1.0, 1.0),
        child: SvgPicture.asset(
          AssetPaths.handTrace,
          width: width,
          height: height,
          fit: BoxFit.contain,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
    );
  }
}
