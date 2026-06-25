import 'dart:ui';

import '../models/nail_beauty_shape.dart';
import '../models/nail_finger.dart';

/// One nail instance from segmentation (raw + display polygon).
class DetectedNail {
  DetectedNail({
    required this.id,
    required this.polygon,
    required this.confidence,
    this.className = 'Nail',
    this.boundingBox,
    List<Offset>? sourcePolygon,
    this.shape,
    this.finger,
  }) : sourcePolygon = sourcePolygon ?? polygon;

  final String id;
  final List<Offset> polygon;
  final List<Offset> sourcePolygon;
  final double confidence;
  final String className;
  final Rect? boundingBox;
  final NailBeautyShape? shape;
  final NailFinger? finger;

  List<Offset> get detectionPolygon => sourcePolygon;

  DetectedNail copyWith({
    List<Offset>? polygon,
    List<Offset>? sourcePolygon,
    double? confidence,
    NailBeautyShape? shape,
    NailFinger? finger,
  }) {
    return DetectedNail(
      id: id,
      polygon: polygon ?? this.polygon,
      sourcePolygon: sourcePolygon ?? this.sourcePolygon,
      confidence: confidence ?? this.confidence,
      className: className,
      boundingBox: boundingBox,
      shape: shape ?? this.shape,
      finger: finger ?? this.finger,
    );
  }
}
