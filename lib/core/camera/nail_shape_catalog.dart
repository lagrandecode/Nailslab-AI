import 'package:flutter/services.dart';

import '../../models/nail_beauty_shape.dart';
import 'nail_shape_svg_loader.dart';

/// Loads nail shape polygons from assets/nail_shapes/*.svg templates.
class NailShapeCatalog {
  NailShapeCatalog._();

  static final NailShapeCatalog instance = NailShapeCatalog._();

  final _cache = <String, List<Offset>>{};

  Future<List<Offset>> templatePoints({
    required NailBeautyShape shape,
    required NailPlateRole role,
  }) async {
    if (shape == NailBeautyShape.natural) {
      return const [];
    }

    final key = '${shape.name}_${role.assetStem}';
    final cached = _cache[key];
    if (cached != null) {
      return cached;
    }

    final path = 'assets/nail_shapes/${shape.name}_${role.assetStem}.svg';
    final raw = await rootBundle.loadString(path);
    final out = NailShapeSvgLoader.fromSvgText(raw);
    _cache[key] = out;
    return out;
  }

  Future<void> warmUp() async {
    for (final shape in NailBeautyShape.values) {
      if (shape == NailBeautyShape.natural) {
        continue;
      }
      for (final role in NailPlateRole.values) {
        await templatePoints(shape: shape, role: role);
      }
    }
  }
}
