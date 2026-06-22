import 'package:flutter/material.dart';

import '../core/camera/plain_hand_layout.dart';
import '../models/nail_finger.dart';

/// Base hand photo with a full-size nail sheet overlay (same 434×576 canvas).
class PlainHandLookView extends StatelessWidget {
  const PlainHandLookView({
    super.key,
    required this.brownHand,
    required this.nailSheetAsset,
    this.selectedFinger,
    this.onFingerTap,
  });

  final bool brownHand;
  final String nailSheetAsset;
  final NailFinger? selectedFinger;
  final ValueChanged<NailFinger>? onFingerTap;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = Size(constraints.maxWidth, constraints.maxHeight);
          final handRect = PlainHandLayout.fitHandRect(viewport);

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fromRect(
                rect: handRect,
                child: LayoutBuilder(
                  builder: (context, handConstraints) {
                    final handSize = Size(
                      handConstraints.maxWidth,
                      handConstraints.maxHeight,
                    );

                    return GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTapUp: (details) {
                        final finger = PlainHandNailSlot.fingerAtHandPoint(
                          details.localPosition,
                          handSize,
                        );
                        if (finger != null) {
                          onFingerTap?.call(finger);
                        }
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            brownHand
                                ? PlainHandLayout.brownAsset
                                : PlainHandLayout.lightAsset,
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.high,
                          ),
                          Image.asset(
                            nailSheetAsset,
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.high,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
