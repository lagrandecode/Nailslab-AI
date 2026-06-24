import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/camera/thumb_nail_profile.dart';

/// Loads the thumb nail texture + mask for live AR warping.
class ThumbNailAssetCache {
  ThumbNailAssetCache._();
  static final instance = ThumbNailAssetCache._();

  ui.Image? _texture;
  ui.Image? _mask;
  Future<void>? _preloadFuture;

  ui.Image? get texture => _texture;
  ui.Image? get mask => _mask;

  Future<void> preload() {
    return _preloadFuture ??= _loadAll();
  }

  Future<void> _loadAll() async {
    _texture = await _decodeAsset(ThumbNailProfile.textureAsset) ??
        await _decodeAsset(ThumbNailProfile.sourceAsset);
    _mask = await _decodeAsset(ThumbNailProfile.maskAsset);
    if (kDebugMode) {
      debugPrint(
        'ThumbNailAssetCache: texture=${_texture != null} '
        'mask=${_mask != null}',
      );
    }
  }

  Future<ui.Image?> loadTexture() async {
    await preload();
    return _texture;
  }

  Future<ui.Image?> loadMask() async {
    await preload();
    return _mask;
  }

  Future<ui.Image?> _decodeAsset(String path) async {
    try {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('Thumb nail asset load failed ($path): $error');
        debugPrint('$stack');
      }
      return null;
    }
  }

  void dispose() {
    _texture?.dispose();
    _mask?.dispose();
    _texture = null;
    _mask = null;
    _preloadFuture = null;
  }
}
