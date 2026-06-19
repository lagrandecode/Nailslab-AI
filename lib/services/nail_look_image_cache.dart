import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../models/nail_finger.dart';
import '../models/nail_look.dart';

/// Loads and caches processed nail look overlay images (transparent PNG).
class NailLookImageCache {
  NailLookImageCache._();

  static final NailLookImageCache instance = NailLookImageCache._();

  final Map<String, ui.Image> _cache = {};
  final Map<String, Map<NailFinger, ui.Image>> _fingerCache = {};

  Future<ui.Image?> load(NailLook look) async {
    final cached = _cache[look.overlayAsset];
    if (cached != null) {
      return cached;
    }

    final processed = await _loadProcessedImage(look);
    if (processed == null) {
      return null;
    }

    final pngBytes = Uint8List.fromList(img.encodePng(processed));
    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();
    _cache[look.overlayAsset] = frame.image;
    return frame.image;
  }

  Future<Map<NailFinger, ui.Image>> loadFingerNails(NailLook look) async {
    final cached = _fingerCache[look.overlayAsset];
    if (cached != null) {
      return cached;
    }

    final processed = await _loadProcessedImage(look);
    if (processed == null || look.nailCrops.isEmpty) {
      return const {};
    }

    final sourceSize = ui.Size(processed.width.toDouble(), processed.height.toDouble());
    final result = <NailFinger, ui.Image>{};

    for (final entry in look.nailCrops.entries) {
      final rect = entry.value.rectForSize(sourceSize);
      final crop = img.copyCrop(
        processed,
        x: rect.left.round().clamp(0, processed.width - 1),
        y: rect.top.round().clamp(0, processed.height - 1),
        width: rect.width.round().clamp(1, processed.width),
        height: rect.height.round().clamp(1, processed.height),
      );
      final pngBytes = Uint8List.fromList(img.encodePng(crop));
      final codec = await ui.instantiateImageCodec(pngBytes);
      final frame = await codec.getNextFrame();
      result[entry.key] = frame.image;
    }

    _fingerCache[look.overlayAsset] = result;
    return result;
  }

  Future<img.Image?> _loadProcessedImage(NailLook look) async {
    final bytes = await rootBundle.load(look.overlayAsset);
    final decoded = img.decodeImage(bytes.buffer.asUint8List());
    if (decoded == null) {
      return null;
    }

    final processed = _prepareOverlayImage(decoded);
    return _cropBottom(processed, look.cropBottomFraction);
  }

  img.Image _prepareOverlayImage(img.Image source) {
    var transparentPixels = 0;
    var totalPixels = source.width * source.height;
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        if (source.getPixel(x, y).a < 20) {
          transparentPixels++;
        }
      }
    }

    // Transparent PNGs keep their alpha as-is so dark nail art is preserved.
    if (transparentPixels > totalPixels * 0.05) {
      return source;
    }

    return _keyOutDarkBackground(source);
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
    for (final nails in _fingerCache.values) {
      for (final image in nails.values) {
        image.dispose();
      }
    }
    _cache.clear();
    _fingerCache.clear();
  }
}
