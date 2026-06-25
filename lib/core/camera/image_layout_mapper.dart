import 'dart:math' as math;
import 'dart:ui';

/// Maps image pixel coordinates to on-screen layout (BoxFit.contain).
class ImageLayoutMapper {
  ImageLayoutMapper({
    required this.imageSize,
    required this.viewSize,
  }) {
    final scale = math.min(
      viewSize.width / imageSize.width,
      viewSize.height / imageSize.height,
    );
    _scale = scale;
    _dx = (viewSize.width - imageSize.width * scale) / 2;
    _dy = (viewSize.height - imageSize.height * scale) / 2;
  }

  final Size imageSize;
  final Size viewSize;

  late final double _scale;
  late final double _dx;
  late final double _dy;

  Rect get displayedRect => Rect.fromLTWH(
        _dx,
        _dy,
        imageSize.width * _scale,
        imageSize.height * _scale,
      );

  Offset mapPoint(Offset imagePoint) {
    return Offset(
      imagePoint.dx * _scale + _dx,
      imagePoint.dy * _scale + _dy,
    );
  }

  List<Offset> mapPolygon(List<Offset> polygon) {
    return polygon.map(mapPoint).toList();
  }
}
