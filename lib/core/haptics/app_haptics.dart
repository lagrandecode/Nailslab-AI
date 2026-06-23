import 'package:flutter/services.dart';

abstract final class AppHaptics {
  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  static void light() {
    HapticFeedback.selectionClick();
  }
}
