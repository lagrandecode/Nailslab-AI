import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../core/camera/plain_hand_layout.dart';
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

  Future<Map<NailFinger, ui.Image>> loadFingerNails(
    NailLook look, {
    bool brownHand = false,
  }) async {
    final cacheKey = '${look.id}_${brownHand ? 'brown' : 'light'}';
    final cached = _fingerCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final bakedAsset = look.plainHandAsset(brownHand: brownHand) ??
        look.plainHandLightAsset;
    if (bakedAsset != null && look.cameraNailCrops.isNotEmpty) {
      final baseAsset =
          brownHand ? PlainHandLayout.brownAsset : PlainHandLayout.lightAsset;
      final result = await _loadFingerNailsFromBakedHand(
        bakedAsset: bakedAsset,
        baseAsset: baseAsset,
        crops: look.cameraNailCrops,
      );
      if (result.isNotEmpty) {
        _fingerCache[cacheKey] = result;
        return result;
      }
    }

    return _loadFingerNailsFromOverlay(look, cacheKey: cacheKey);
  }

  Future<Map<NailFinger, ui.Image>> _loadFingerNailsFromOverlay(
    NailLook look, {
    required String cacheKey,
  }) async {
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
      result[entry.key] = await _imageFromRaster(crop);
    }

    _fingerCache[cacheKey] = result;
    return result;
  }

  Future<Map<NailFinger, ui.Image>> _loadFingerNailsFromBakedHand({
    required String bakedAsset,
    required String baseAsset,
    required Map<NailFinger, NailFingerCrop> crops,
  }) async {
    final baked = await _decodeAsset(bakedAsset);
    final base = await _decodeAsset(baseAsset);
    if (baked == null || base == null) {
      return const {};
    }

    final sourceSize = ui.Size(baked.width.toDouble(), baked.height.toDouble());
    final result = <NailFinger, ui.Image>{};

    for (final entry in crops.entries) {
      final rect = entry.value.rectForSize(sourceSize);
      final x = rect.left.round().clamp(0, baked.width - 1);
      final y = rect.top.round().clamp(0, baked.height - 1);
      final width = rect.width.round().clamp(1, baked.width - x);
      final height = rect.height.round().clamp(1, baked.height - y);

      final nailOnly = img.Image(width: width, height: height, numChannels: 4);
      for (var py = 0; py < height; py++) {
        for (var px = 0; px < width; px++) {
          final gx = x + px;
          final gy = y + py;
          final geo = baked.getPixel(gx, gy);
          final basePixel = gx < base.width && gy < base.height
              ? base.getPixel(gx, gy)
              : null;
          if (!_isBakedHandNailPixel(geo, basePixel)) {
            nailOnly.setPixelRgba(px, py, 0, 0, 0, 0);
            continue;
          }
          nailOnly.setPixelRgba(px, py, geo.r, geo.g, geo.b, 255);
        }
      }

      result[entry.key] = await _imageFromRaster(nailOnly);
    }

    return result;
  }

  bool _isBakedHandNailPixel(img.Pixel geo, img.Pixel? basePixel) {
    if (geo.a < 40) {
      return false;
    }

    final r = geo.r.toInt();
    final g = geo.g.toInt();
    final b = geo.b.toInt();
    final maxC = [r, g, b].reduce(math.max);
    final minC = [r, g, b].reduce(math.min);
    final chroma = maxC - minC;

    if (chroma > 28) {
      return true;
    }
    if (maxC > 210 && minC > 170) {
      return true;
    }
    if (maxC < 70) {
      return true;
    }
    if (r > 175 && g > 125 && b > 125 && r > g && r > b) {
      return false;
    }
    if (basePixel != null) {
      final dr = (geo.r - basePixel.r).abs() +
          (geo.g - basePixel.g).abs() +
          (geo.b - basePixel.b).abs();
      if (dr > 45) {
        return true;
      }
    }
    return false;
  }

  Future<img.Image?> _decodeAsset(String assetPath) async {
    final bytes = await rootBundle.load(assetPath);
    return img.decodeImage(bytes.buffer.asUint8List());
  }

  Future<ui.Image> _imageFromRaster(img.Image raster) async {
    final pngBytes = Uint8List.fromList(img.encodePng(raster));
    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();
    return frame.image;
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
