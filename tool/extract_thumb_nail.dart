import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Builds thumb nail mask assets from a source image.
///
/// Supports:
/// - [assets/thumb3.png] — clean nail silhouette on black (preferred)
/// - [assets/thumb.png] — full thumb photo (legacy extraction)
///
/// Run:
///   dart run tool/extract_thumb_nail.dart
///   dart run tool/extract_thumb_nail.dart assets/thumb3.png
void main(List<String> args) {
  final inputPath = args.isNotEmpty ? args.first : 'assets/thumb3.png';
  const outputPath = 'assets/looks/reference/thumb_nail_extracted.png';
  const maskPath = 'assets/looks/reference/thumb_nail_mask.png';

  final source = img.decodeImage(File(inputPath).readAsBytesSync())!;
  final w = source.width;
  final h = source.height;

  final isNail = List<bool>.filled(w * h, false);
  var minX = w, maxX = 0, minY = h, maxY = 0;

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = source.getPixel(x, y);
      if (p.r + p.g + p.b < 40) {
        continue;
      }
      isNail[y * w + x] = true;
      minX = math.min(minX, x);
      maxX = math.max(maxX, x);
      minY = math.min(minY, y);
      maxY = math.max(maxY, y);
    }
  }

  if (maxX <= minX || maxY <= minY) {
    stderr.writeln('No nail pixels found in $inputPath');
    exit(1);
  }

  final pad = 4;
  final cropX = (minX - pad).clamp(0, w - 1);
  final cropY = (minY - pad).clamp(0, h - 1);
  final cropW = (maxX - minX + 1 + pad * 2).clamp(1, w - cropX);
  final cropH = (maxY - minY + 1 + pad * 2).clamp(1, h - cropY);

  final extracted = img.Image(width: cropW, height: cropH, numChannels: 4);
  final mask = img.Image(width: cropW, height: cropH, numChannels: 4);

  for (var y = 0; y < cropH; y++) {
    for (var x = 0; x < cropW; x++) {
      final sx = cropX + x;
      final sy = cropY + y;
      if (!isNail[sy * w + sx]) {
        continue;
      }
      final p = source.getPixel(sx, sy);
      final alpha = p.r + p.g + p.b < 50 ? 0 : 255;
      extracted.setPixelRgba(x, y, p.r, p.g, p.b, alpha);
      if (alpha > 0) {
        mask.setPixelRgba(x, y, 255, 255, 255, 255);
      }
    }
  }

  Directory(File(outputPath).parent.path).createSync(recursive: true);
  File(outputPath).writeAsBytesSync(img.encodePng(extracted));
  File(maskPath).writeAsBytesSync(img.encodePng(mask));

  final aspect = cropW / cropH;
  print('Source: $inputPath');
  print('Nail crop ${cropW}x$cropH (aspect ${aspect.toStringAsFixed(3)})');
  print('Suggested metrics: widthOverBed=1.08 heightOverBed=${(1.08 / aspect).toStringAsFixed(3)}');
  print('Wrote $outputPath');
  print('Wrote $maskPath');
}
