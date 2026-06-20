import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Thumb nail art bbox on baked geo hand (diff vs base hand).
void main() {
  final base = img.decodeImage(File('assets/hand3.png').readAsBytesSync())!;
  final geo = img.decodeImage(
    File('assets/handwhitegeo-removebg-preview.png').readAsBytesSync(),
  )!;
  final w = geo.width;
  final h = geo.height;

  final x0 = (0.72 * w).round();
  final x1 = (0.98 * w).round();
  final y0 = (0.34 * h).round();
  final y1 = (0.52 * h).round();

  var minX = w, maxX = 0, minY = h, maxY = 0, count = 0;
  for (var y = y0; y <= y1; y++) {
    for (var x = x0; x <= x1; x++) {
      final g = geo.getPixel(x, y);
      if (g.a < 40) continue;
      final bp = base.getPixel(x, y);
      final dr = (g.r - bp.r).abs() + (g.g - bp.g).abs() + (g.b - bp.b).abs();
      if (dr < 50) continue;
      count++;
      minX = math.min(minX, x);
      maxX = math.max(maxX, x);
      minY = math.min(minY, y);
      maxY = math.max(maxY, y);
    }
  }

  if (count < 10) {
    print('thumb: not found');
    return;
  }

  final nailW = maxX - minX + 1;
  final nailH = maxY - minY + 1;
  print(
    'thumb: crop={ "x": ${(minX / w).toStringAsFixed(3)}, "y": ${(minY / h).toStringAsFixed(3)}, '
    '"w": ${(nailW / w).toStringAsFixed(3)}, "h": ${(nailH / h).toStringAsFixed(3)} } '
    'width_over_bed=${(nailW / nailH).toStringAsFixed(3)}',
  );
}
