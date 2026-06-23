import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/camera/plain_hand_layout.dart';
import '../core/theme/app_colors.dart';
import '../models/nail_finger.dart';
import '../models/nail_look.dart';
import '../models/plain_nail_paint.dart';

/// Base hand with per-finger nail art painted at cherry2-measured positions.
class PlainHandLookView extends StatelessWidget {
  const PlainHandLookView({
    super.key,
    required this.brownHand,
    required this.look,
    required this.fingerNailImages,
    required this.paintState,
    this.onFingerTap,
  });

  final bool brownHand;
  final NailLook? look;
  final Map<NailFinger, ui.Image> fingerNailImages;
  final PlainNailPaintState paintState;
  final ValueChanged<NailFinger>? onFingerTap;

  @override
  Widget build(BuildContext context) {
    final slots = PlainHandLayout.slotsForLook(look);

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
                        NailFinger? hit;
                        for (final slot in slots.reversed) {
                          if (slot.containsHandPoint(details.localPosition, handSize)) {
                            hit = slot.finger;
                            break;
                          }
                        }
                        if (hit != null) {
                          onFingerTap?.call(hit);
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
                          ...slots.map(
                            (slot) => _PlainNailLayer(
                              slot: slot,
                              nailImage: fingerNailImages[slot.finger],
                              fingerPaint: paintState.paintFor(slot.finger),
                              selected: paintState.selectedFinger == slot.finger,
                              handSize: handSize,
                            ),
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

class _PlainNailLayer extends StatelessWidget {
  const _PlainNailLayer({
    required this.slot,
    required this.nailImage,
    required this.fingerPaint,
    required this.selected,
    required this.handSize,
  });

  final PlainHandNailSlot slot;
  final ui.Image? nailImage;
  final PlainFingerNailPaint fingerPaint;
  final bool selected;
  final Size handSize;

  @override
  Widget build(BuildContext context) {
    final image = nailImage;
    if (image == null) {
      return const SizedBox.shrink();
    }

    final geometry = slot.toGeometry(handSize, 1.0);
    final left = geometry.center.dx - geometry.width / 2;
    final top = geometry.center.dy - geometry.height / 2;

    Widget nail = RawImage(
      image: image,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.high,
    );

    final tint = fingerPaint.tint;
    if (tint != null) {
      nail = ColorFiltered(
        colorFilter: ColorFilter.mode(tint, BlendMode.modulate),
        child: nail,
      );
    }

    return Positioned(
      left: left,
      top: top,
      width: geometry.width,
      height: geometry.height,
      child: Transform.rotate(
        angle: geometry.angle,
        child: Stack(
          fit: StackFit.expand,
          children: [
            nail,
            if (selected)
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 2),
                    borderRadius: BorderRadius.circular(geometry.width * 0.2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
