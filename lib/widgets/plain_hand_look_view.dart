import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/camera/plain_hand_layout.dart';
import '../core/camera/nail_bed_geometry.dart';
import '../core/theme/app_colors.dart';
import '../models/nail_finger.dart';
import '../models/plain_nail_paint.dart';

/// Static base hand with paintable per-finger nail layers only.
class PlainHandLookView extends StatelessWidget {
  const PlainHandLookView({
    super.key,
    required this.brownHand,
    required this.paintState,
    required this.fingerNailImages,
    this.lookSheetAsset,
    this.onFingerTap,
    this.scale = 1.0,
  });

  final bool brownHand;
  final PlainNailPaintState paintState;
  final Map<NailFinger, ui.Image> fingerNailImages;
  final String? lookSheetAsset;
  final ValueChanged<NailFinger>? onFingerTap;
  final double scale;

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
                          scale: scale,
                        );
                        if (finger != null) {
                          onFingerTap?.call(finger);
                        }
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            brownHand
                                ? PlainHandLayout.brownAsset
                                : PlainHandLayout.lightAsset,
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.high,
                          ),
                          if (lookSheetAsset == null)
                            Image.asset(
                              PlainHandLayout.defaultNailSheetAsset,
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.high,
                            )
                          else
                            Image.asset(
                              lookSheetAsset!,
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.high,
                            ),
                          if (lookSheetAsset == null)
                            ...PlainHandLayout.slots.map(
                            (slot) => _PlainNailLayer(
                              slot: slot,
                              nailImage: fingerNailImages[slot.finger],
                              fingerPaint: paintState.paintFor(slot.finger),
                              selected: paintState.selectedFinger == slot.finger,
                              handSize: handSize,
                              scale: scale,
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
    required this.scale,
  });

  final PlainHandNailSlot slot;
  final ui.Image? nailImage;
  final PlainFingerNailPaint fingerPaint;
  final bool selected;
  final Size handSize;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final image = nailImage;
    if (image == null) {
      return const SizedBox.shrink();
    }

    final geometry = slot.toGeometry(handSize, scale);
    final left = geometry.center.dx - geometry.width / 2;
    final top = geometry.center.dy - geometry.height / 2;

    Widget nail = RawImage(
      image: image,
      fit: BoxFit.contain,
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
            ClipPath(
              clipper: _NailShapeClipper(),
              child: nail,
            ),
            if (selected)
              IgnorePointer(
                child: CustomPaint(
                  painter: _NailSelectionPainter(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NailShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return buildNailClipPath(size.width, size.height);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _NailSelectionPainter extends CustomPainter {
  const _NailSelectionPainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildNailClipPath(size.width, size.height);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _NailSelectionPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
