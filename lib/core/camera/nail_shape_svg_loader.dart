import 'dart:math' as math;
import 'dart:ui';

/// Samples the first `<path d="...">` in a nail shape SVG into normalized points.
class NailShapeSvgLoader {
  NailShapeSvgLoader._();

  static final _pathD = RegExp(
    r'<path[^>]*\sd="([^"]+)"',
    dotAll: true,
  );

  static List<Offset> fromSvgText(String svgText) {
    final match = _pathD.firstMatch(svgText);
    if (match == null) {
      throw StateError('No <path d="..."> found in SVG');
    }
    final d = match.group(1)!.replaceAll(RegExp(r'\s+'), ' ').trim();
    return _normalize(_samplePath(d));
  }

  static List<Offset> _samplePath(String d, {int curveSteps = 12}) {
    final tokenRe = RegExp(r'[a-zA-Z]|-?\d*\.?\d+(?:e[-+]?\d+)?');
    final tokens = tokenRe.allMatches(d).map((m) => m.group(0)!).toList();

    final points = <Offset>[];
    var i = 0;
    var cmd = '';
    var cx = 0.0;
    var cy = 0.0;
    var sx = 0.0;
    var sy = 0.0;

    double readFloat() {
      final val = double.parse(tokens[i]);
      i += 1;
      return val;
    }

    while (i < tokens.length) {
      if (RegExp(r'[a-zA-Z]').hasMatch(tokens[i])) {
        cmd = tokens[i];
        i += 1;
      }

      switch (cmd) {
        case 'M':
        case 'm':
          var x = readFloat();
          var y = readFloat();
          if (cmd == 'm') {
            x += cx;
            y += cy;
          }
          cx = x;
          cy = y;
          sx = cx;
          sy = cy;
          points.add(Offset(cx, cy));
        case 'L':
        case 'l':
          var x = readFloat();
          var y = readFloat();
          if (cmd == 'l') {
            x += cx;
            y += cy;
          }
          cx = x;
          cy = y;
          points.add(Offset(cx, cy));
        case 'C':
        case 'c':
          var x1 = readFloat();
          var y1 = readFloat();
          var x2 = readFloat();
          var y2 = readFloat();
          var x = readFloat();
          var y = readFloat();
          if (cmd == 'c') {
            x1 += cx;
            y1 += cy;
            x2 += cx;
            y2 += cy;
            x += cx;
            y += cy;
          }
          final x0 = cx;
          final y0 = cy;
          for (var step = 1; step <= curveSteps; step++) {
            final t = step / curveSteps;
            final u = 1 - t;
            final px = u * u * u * x0 +
                3 * u * u * t * x1 +
                3 * u * t * t * x2 +
                t * t * t * x;
            final py = u * u * u * y0 +
                3 * u * u * t * y1 +
                3 * u * t * t * y2 +
                t * t * t * y;
            points.add(Offset(px, py));
          }
          cx = x;
          cy = y;
        case 'Z':
        case 'z':
          cx = sx;
          cy = sy;
          if (points.isNotEmpty && points.first != Offset(cx, cy)) {
            points.add(Offset(cx, cy));
          }
        default:
          throw StateError('Unsupported path command: $cmd');
      }
    }

    return points;
  }

  static List<Offset> _normalize(List<Offset> points) {
    if (points.isEmpty) {
      return points;
    }

    var minX = points.first.dx;
    var maxX = points.first.dx;
    var minY = points.first.dy;
    var maxY = points.first.dy;

    for (final p in points) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }

    final height = math.max(maxY - minY, 1e-6);
    final cx = (minX + maxX) / 2;
    final halfW = math.max((maxX - minX) / 2, 1e-6);

    final out = <Offset>[];
    for (final p in points) {
      out.add(
        Offset(
          ((p.dx - cx) / halfW * 10000).round() / 10000,
          ((maxY - p.dy) / height * 10000).round() / 10000,
        ),
      );
    }

    return _dedupe(out);
  }

  static List<Offset> _dedupe(List<Offset> points) {
    if (points.isEmpty) {
      return points;
    }
    final out = <Offset>[points.first];
    for (var i = 1; i < points.length; i++) {
      final p = points[i];
      final last = out.last;
      if ((p - last).distance > 0.01) {
        out.add(p);
      }
    }
    return out;
  }
}
