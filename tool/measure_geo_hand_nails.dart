import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Measure geometric nail art on baked hand using slot-centered flood fill.
void main() {
  final base = img.decodeImage(File('assets/hand3.png').readAsBytesSync())!;
  final geo = img.decodeImage(
    File('assets/handwhitegeo-removebg-preview.png').readAsBytesSync(),
  )!;

  final w = geo.width;
  final h = geo.height;
  print('hand ${w}x$h');

  bool isNailArt(int x, int y) {
    final g = geo.getPixel(x, y);
    if (g.a < 40) return false;
    final r = g.r.toInt();
    final gr = g.g.toInt();
    final b = g.b.toInt();
    final maxC = [r, gr, b].reduce(math.max);
    final minC = [r, gr, b].reduce(math.min);
    final chroma = maxC - minC;
    if (chroma > 28) return true;
    if (maxC > 210 && minC > 170) return true;
    if (maxC < 70) return true;
    if (r > 175 && gr > 125 && b > 125 && r > gr && r > b) return false;
    if (x < base.width && y < base.height) {
      final bp = base.getPixel(x, y);
      final dr = (g.r - bp.r).abs() + (g.g - bp.g).abs() + (g.b - bp.b).abs();
      if (dr > 45) return true;
    }
    return false;
  }

  const slots = [
    ('pinky', 0.088, 0.402, 0.072, 0.052),
    ('ring', 0.278, 0.358, 0.074, 0.054),
    ('middle', 0.478, 0.330, 0.078, 0.056),
    ('index', 0.665, 0.348, 0.074, 0.054),
    ('thumb', 0.848, 0.438, 0.082, 0.050),
  ];

  for (final slot in slots) {
    final name = slot.$1;
    final cx = (slot.$2 * w).round();
    final cy = (slot.$3 * h).round();
    final boxW = (slot.$4 * w * (name == 'thumb' ? 2.5 : 1.6)).round();
    final boxH = (slot.$5 * h * (name == 'thumb' ? 3.0 : 2.2)).round();
    final x0 = (cx - boxW ~/ 2).clamp(0, w - 1);
    final x1 = (cx + boxW ~/ 2).clamp(0, w - 1);
    final y0 = (cy - boxH ~/ 2).clamp(0, h - 1);
    final y1 = (cy + boxH ~/ 2).clamp(0, h - 1);

    var minX = w, maxX = 0, minY = h, maxY = 0;
    var count = 0;
    var sumX = 0.0, sumY = 0.0;
    for (var y = y0; y <= y1; y++) {
      for (var x = x0; x <= x1; x++) {
        if (!isNailArt(x, y)) continue;
        count++;
        sumX += x;
        sumY += y;
        minX = math.min(minX, x);
        maxX = math.max(maxX, x);
        minY = math.min(minY, y);
        maxY = math.max(maxY, y);
      }
    }
    if (count < 20 && name == 'thumb') {
      // Thumb art is subtler — accept pixels that differ from base hand.
      for (var y = y0; y <= y1; y++) {
        for (var x = x0; x <= x1; x++) {
          final g = geo.getPixel(x, y);
          if (g.a < 40) continue;
          final bp = base.getPixel(x, y);
          final dr = (g.r - bp.r).abs() + (g.g - bp.g).abs() + (g.b - bp.b).abs();
          if (dr < 35) continue;
          count++;
          sumX += x;
          sumY += y;
          minX = math.min(minX, x);
          maxX = math.max(maxX, x);
          minY = math.min(minY, y);
          maxY = math.max(maxY, y);
        }
      }
    }
    if (count < 20) {
      print('$name: no art found');
      continue;
    }

    final nailW = maxX - minX + 1;
    final nailH = maxY - minY + 1;
    final rowY = (sumY / count).round();

    var skinMinX = w;
    var skinMaxX = 0;
    final band = (nailW * 0.22).round().clamp(4, 14);
    for (var x = (minX - band).clamp(0, w - 1); x <= (maxX + band).clamp(0, w - 1); x++) {
      final p = base.getPixel(x, rowY);
      if (p.a > 40 && p.r > 40) {
        skinMinX = math.min(skinMinX, x);
        skinMaxX = math.max(skinMaxX, x);
      }
    }
    final fingerW = (skinMaxX - skinMinX + 1).clamp(nailW, w);

    // Nail art height matches the visible nail bed on the reference photo.
    final widthOverBed = nailW / nailH;
    print(
      '$name: crop={ "x": ${(minX / w).toStringAsFixed(3)}, "y": ${(minY / h).toStringAsFixed(3)}, '
      '"w": ${(nailW / w).toStringAsFixed(3)}, "h": ${(nailH / h).toStringAsFixed(3)} } '
      'width_over_bed=${widthOverBed.toStringAsFixed(3)} height_over_bed=1.000',
    );
  }
}
