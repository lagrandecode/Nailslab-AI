import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../models/nail_look.dart';

/// Loads and caches processed nail look overlay images (transparent PNG).
class NailLookImageCache {
  NailLookImageCache._();

  static final NailLookImageCache instance = NailLookImageCache._();

  final Map<String, ui.Image> _cache = {};

  Future<ui.Image?> load(NailLook look) async {
    final cached = _cache[look.overlayAsset];
    if (cached != null) {
      return cached;
    }

    final bytes = await rootBundle.load(look.overlayAsset);
    final decoded = img.decodeImage(bytes.buffer.asUint8List());
    if (decoded == null) {
      return null;
    }

    final processed = _keyOutDarkBackground(decoded);
    final cropped = _cropBottom(processed, look.cropBottomFraction);
    final pngBytes = Uint8List.fromList(img.encodePng(cropped));
    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();
    _cache[look.overlayAsset] = frame.image;
    return frame.image;
  }

  img.Image _keyOutDarkBackground(img.Image source) {
    final output = img.Image.from(source);
    for (var y = 0; y < output.height; y++) {
      for (var x = 0; x < output.width; x++) {
        final pixel = output.getPixel(x, y);
        if (pixel.r < 48 && pixel.g < 48 && pixel.b < 48) {
          output.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
    }
    return output;
  }

  img.Image _cropBottom(img.Image source, double fraction) {
    if (fraction <= 0) {
      return source;
    }
    final cropHeight = (source.height * (1 - fraction)).round().clamp(1, source.height);
    return img.copyCrop(source, x: 0, y: 0, width: source.width, height: cropHeight);
  }

  void dispose() {
    for (final image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
  }
}
