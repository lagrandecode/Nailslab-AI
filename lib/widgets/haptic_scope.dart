import 'package:flutter/material.dart';

import '../core/haptics/app_haptics.dart';

/// Triggers heavy haptics for taps across the whole app.
class HapticScope extends StatefulWidget {
  const HapticScope({super.key, required this.child});

  final Widget child;

  @override
  State<HapticScope> createState() => _HapticScopeState();
}

class _HapticScopeState extends State<HapticScope> {
  static const double _tapSlop = 18;

  Offset? _pointerDownPosition;

  void _onPointerDown(PointerDownEvent event) {
    _pointerDownPosition = event.position;
  }

  void _onPointerUp(PointerUpEvent event) {
    final origin = _pointerDownPosition;
    _pointerDownPosition = null;

    if (origin == null) {
      return;
    }

    if ((event.position - origin).distance <= _tapSlop) {
      AppHaptics.heavy();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointerDownPosition = null;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: widget.child,
    );
  }
}

/// Wraps [onPressed] with heavy haptics for buttons and custom actions.
extension HapticCallback on VoidCallback {
  VoidCallback withHeavyHaptic() {
    return () {
      AppHaptics.heavy();
      this();
    };
  }
}

/// Filled button that always fires heavy haptics before [onPressed].
class HapticFilledButton extends StatelessWidget {
  const HapticFilledButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed == null
          ? null
          : () {
              AppHaptics.heavy();
              onPressed!();
            },
      style: style,
      child: child,
    );
  }
}
