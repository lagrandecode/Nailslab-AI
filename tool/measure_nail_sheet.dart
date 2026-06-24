import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Measure each nail bbox on a full-canvas nail sheet (e.g. cherry2.png).
void main() {
  final path = Platform.environment['SHEET'] ?? 'assets/cherry2.png';
  final image = img.decodeImage(File(path).readAsBytesSync())!;
  final w = image.width;
  final h = image.height;
  print('sheet ${w}x$h');

  final colMinX = List<int>.filled(w, w);
  final colMaxX = List<int>.filled(w, -1);
  final colHits = List<int>.filled(w, 0);

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = image.getPixel(x, y);
      if (p.a < 40) continue;
      colHits[x]++;
      colMinX[x] = math.min(colMinX[x], x);
      colMaxX[x] = math.max(colMaxX[x], x);
    }
  }

  final threshold = colHits.reduce(math.max) * 0.15;
  final segments = <List<int>>[];
  var inSeg = false;
  var start = 0;
  for (var x = 0; x < w; x++) {
    if (colHits[x] > threshold && !inSeg) {
      start = x;
      inSeg = true;
    } else if (colHits[x] <= threshold && inSeg) {
      segments.add([start, x - 1]);
      inSeg = false;
    }
  }
  if (inSeg) segments.add([start, w - 1]);

  const fingers = [
    'pinky',
    'ring',
    'middle',
    'index',
    'thumb',
  ];

  for (var i = 0; i < segments.length && i < fingers.length; i++) {
    final x0 = segments[i][0];
    final x1 = segments[i][1];
    var minY = h;
    var maxY = 0;
    for (var y = 0; y < h; y++) {
      for (var x = x0; x <= x1; x++) {
        if (image.getPixel(x, y).a < 40) continue;
        minY = math.min(minY, y);
        maxY = math.max(maxY, y);
      }
    }
    if (minY > maxY) continue;
    final nailW = x1 - x0 + 1;
    final nailH = maxY - minY + 1;
    print(
      '${fingers[i]}: { "x": ${(x0 / w).toStringAsFixed(3)}, "y": ${(minY / h).toStringAsFixed(3)}, '
      '"w": ${(nailW / w).toStringAsFixed(3)}, "h": ${(nailH / h).toStringAsFixed(3)} } '
      'center=(${(x0 + nailW / 2) / w}, ${(minY + nailH / 2) / h})',
    );
  }
}
