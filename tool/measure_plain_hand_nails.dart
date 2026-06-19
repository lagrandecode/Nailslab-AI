import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  for (final path in ['assets/hand3.png', 'assets/handbrown.png']) {
    final image = img.decodeImage(File(path).readAsBytesSync())!;
    final w = image.width;
    final h = image.height;
    print('=== $path ${w}x$h ===');

    bool isNail(int x, int y) {
      final p = image.getPixel(x, y);
      if (p.a < 40) return false;
      final r = p.r.toInt();
      final g = p.g.toInt();
      final b = p.b.toInt();
      // Existing nude polish: pinkish, not skin, not ring
      if (r > 180 && g > 130 && b > 130 && r > g && r > b) return true;
      return false;
    }

    final colCounts = List<int>.filled(w, 0);
    for (var x = 0; x < w; x++) {
      for (var y = 0; y < (h * 0.45).round(); y++) {
        if (isNail(x, y)) colCounts[x]++;
      }
    }
    final threshold = colCounts.reduce((a, b) => a > b ? a : b) * 0.2;
    final segments = <List<int>>[];
    var inSeg = false;
    var start = 0;
    for (var x = 0; x < w; x++) {
      if (colCounts[x] > threshold && !inSeg) {
        start = x;
        inSeg = true;
      } else if (colCounts[x] <= threshold && inSeg) {
        segments.add([start, x - 1]);
        inSeg = false;
      }
    }
    if (inSeg) segments.add([start, w - 1]);

    const fingers = ['pinky', 'ring', 'middle', 'index', 'thumb'];
    for (var i = 0; i < segments.length && i < fingers.length; i++) {
      final x0 = segments[i][0];
      final x1 = segments[i][1];
      var minY = h;
      var maxY = 0;
      var sumX = 0.0;
      var sumY = 0.0;
      var count = 0;
      for (var y = 0; y < (h * 0.45).round(); y++) {
        for (var x = x0; x <= x1; x++) {
          if (isNail(x, y)) {
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
            sumX += x;
            sumY += y;
            count++;
          }
        }
      }
      if (count == 0) continue;
      final cx = sumX / count;
      final cy = sumY / count;
      print(
        '${fingers[i]}: cx=${(cx / w).toStringAsFixed(3)}, cy=${(cy / h).toStringAsFixed(3)}, w=${((x1 - x0 + 1) / w).toStringAsFixed(3)}, h=${((maxY - minY + 1) / h).toStringAsFixed(3)}',
      );
    }
  }
}
