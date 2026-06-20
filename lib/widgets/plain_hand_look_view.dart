import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/camera/plain_hand_layout.dart';
import '../core/camera/nail_bed_geometry.dart';
import '../models/nail_finger.dart';
import '../models/nail_look.dart';
import '../services/nail_look_image_cache.dart';

/// Static hand photo for plain mode — baked look hand or base hand + patches.
class PlainHandLookView extends StatefulWidget {
  const PlainHandLookView({
    super.key,
    required this.look,
    required this.brownHand,
    this.scale = 1.0,
  });

  final NailLook? look;
  final bool brownHand;
  final double scale;

  @override
  State<PlainHandLookView> createState() => _PlainHandLookViewState();
}

class _PlainHandLookViewState extends State<PlainHandLookView> {
  Map<NailFinger, ui.Image>? _fingerNails;

  @override
  void initState() {
    super.initState();
    _loadNails();
  }

  @override
  void didUpdateWidget(PlainHandLookView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.look?.overlayAsset != widget.look?.overlayAsset ||
        oldWidget.brownHand != widget.brownHand) {
      _loadNails();
    }
  }

  bool get _usePatchOverlay {
    final look = widget.look;
    if (look == null) {
      return false;
    }
    return look.plainHandAsset(brownHand: widget.brownHand) == null;
  }

  Future<void> _loadNails() async {
    final look = widget.look;
    if (look == null || !_usePatchOverlay) {
      if (mounted) {
        setState(() => _fingerNails = null);
      }
      return;
    }
    final nails = await NailLookImageCache.instance.loadFingerNails(look);
    if (mounted) {
      setState(() => _fingerNails = nails);
    }
  }

  String _handAsset() {
    final look = widget.look;
    final baked = look?.plainHandAsset(brownHand: widget.brownHand);
    if (baked != null) {
      return baked;
    }
    return widget.brownHand ? PlainHandLayout.brownAsset : PlainHandLayout.lightAsset;
  }

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

                    return Stack(
                      clipBehavior: Clip.none,
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          _handAsset(),
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.high,
                        ),
                        if (_usePatchOverlay && _fingerNails != null)
                          ...PlainHandLayout.slots.map(
                            (slot) => _PlainNailLayer(
                              slot: slot,
                              nailImage: _fingerNails![slot.finger],
                              handSize: handSize,
                              scale: widget.scale,
                            ),
                          ),
                      ],
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
    required this.handSize,
    required this.scale,
  });

  final PlainHandNailSlot slot;
  final ui.Image? nailImage;
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

    return Positioned(
      left: left,
      top: top,
      width: geometry.width,
      height: geometry.height,
      child: Transform.rotate(
        angle: geometry.angle,
        child: ClipPath(
          clipper: _NailShapeClipper(),
          child: RawImage(
            image: image,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
          ),
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
