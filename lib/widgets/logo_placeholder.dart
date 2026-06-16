import 'package:flutter/material.dart';

import '../constants/asset_paths.dart';

class LogoPlaceholder extends StatelessWidget {
  const LogoPlaceholder({super.key, this.height = 120});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Image.asset(
        AssetPaths.splashLogo,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }
}
