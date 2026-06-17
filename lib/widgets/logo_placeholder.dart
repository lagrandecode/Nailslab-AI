import 'package:flutter/material.dart';

import 'app_logo.dart';

/// Full-screen branded placeholder while content loads (matches native splash).
class LogoPlaceholder extends StatelessWidget {
  const LogoPlaceholder({super.key, this.height = 160});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: AppLogo(height: height),
    );
  }
}
