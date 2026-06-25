import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'nail_plate_balancer.dart';

/// Default nail plate PNG warped onto each detected nail bed.
class NailTextureCatalog {
  NailTextureCatalog._();

  static final NailTextureCatalog instance = NailTextureCatalog._();

  static const nailPlateAsset =
      'assets/nail_shapes/ChatGPT_Image_Jun_25__2026__12_23_51_AM-removebg-preview.png';

  /// Visible nail art bounds inside the full PNG (trim transparent margins).
  static const nailContentRect = kNailPlateContentRect;

  ui.Image? _nailPlate;

  ui.Image? get cachedNailPlate => _nailPlate;

  Future<ui.Image?> nailPlateImage() async {
    final cached = _nailPlate;
    if (cached != null) {
      return cached;
    }

    try {
      final data = await rootBundle.load(nailPlateAsset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _nailPlate = frame.image;
      return _nailPlate;
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('Failed to load $nailPlateAsset: $error\n$stack');
      }
      return null;
    }
  }

  Future<void> warmUp() async {
    await nailPlateImage();
  }

  void dispose() {
    _nailPlate?.dispose();
    _nailPlate = null;
  }
}
