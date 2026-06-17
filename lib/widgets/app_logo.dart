import 'package:flutter/material.dart';

import '../constants/asset_paths.dart';

/// Brand logo used across the app (onboarding, loading, headers, etc.).
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height = 120,
    this.width,
    this.fit = BoxFit.contain,
    this.borderRadius,
  });

  final double height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      AssetPaths.logo,
      height: height,
      width: width,
      fit: fit,
    );

    if (borderRadius == null) {
      return image;
    }

    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}
