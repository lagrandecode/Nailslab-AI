import 'package:flutter/material.dart';

import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData light() {
    const fontFamily = AppTypography.fontFamily;

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE91E8C)),
      scaffoldBackgroundColor: Colors.white,
      fontFamily: fontFamily,
      useMaterial3: true,
      textTheme: const TextTheme().apply(fontFamily: fontFamily),
      primaryTextTheme: const TextTheme().apply(fontFamily: fontFamily),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
