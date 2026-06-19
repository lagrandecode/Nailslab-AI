import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final bytes = File('assets/looks/geometric.png').readAsBytesSync();
  final image = img.decodeImage(bytes)!;
  final w = image.width;
  final h = image.height;
  print('size $w x $h');

  bool isNail(int x, int y) {
    final p = image.getPixel(x, y);
    if (p.a < 40) return false;
    if (p.r < 30 && p.g < 30 && p.b < 30 && p.a < 200) return false;
    return true;
  }

  // Label each nail pixel with a component id via flood fill from seed columns.
  final labels = List<int>.filled(w * h, 0);
  var nextLabel = 1;
  final bounds = <int, List<int>>{};

  int idx(int x, int y) => y * w + x;

  void flood(int sx, int sy, int label) {
    final stack = <List<int>>[[sx, sy]];
    var minX = sx, maxX = sx, minY = sy, maxY = sy;
    var count = 0;

    while (stack.isNotEmpty) {
      final point = stack.removeLast();
      final x = point[0], y = point[1];
      if (x < 0 || y < 0 || x >= w || y >= h) continue;
      final i = idx(x, y);
      if (labels[i] != 0 || !isNail(x, y)) continue;
      labels[i] = label;
      count++;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
      stack.add([x + 1, y]);
      stack.add([x - 1, y]);
      stack.add([x, y + 1]);
      stack.add([x, y - 1]);
    }

    if (count > 200) {
      bounds[label] = [minX, minY, maxX, maxY, count];
    }
  }

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (labels[idx(x, y)] == 0 && isNail(x, y)) {
        flood(x, y, nextLabel);
        nextLabel++;
      }
    }
  }

  final components = bounds.entries.toList()
    ..sort((a, b) => a.value[0].compareTo(b.value[0]));

  print('components ${components.length}');
  const fingers = ['pinky', 'ring', 'middle', 'index', 'thumb'];
  for (var i = 0; i < components.length && i < fingers.length; i++) {
    final b = components[i].value;
    final x0 = b[0], y0 = b[1], x1 = b[2], y1 = b[3], count = b[4];
    print(
      '${fingers[i]}: x=${(x0 / w).toStringAsFixed(3)}, y=${(y0 / h).toStringAsFixed(3)}, w=${((x1 - x0 + 1) / w).toStringAsFixed(3)}, h=${((y1 - y0 + 1) / h).toStringAsFixed(3)} (px=${count})',
    );
  }
}
