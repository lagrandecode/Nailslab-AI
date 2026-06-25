import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config/roboflow_config.dart';
import '../models/detected_nail.dart';
import 'nail_detection_exception.dart';

/// Calls the Roboflow workflow and parses nail segmentation polygons.
class RoboflowNailDetectionService {
  const RoboflowNailDetectionService();

  Future<List<DetectedNail>> detectNails({
    required Uint8List imageBytes,
    String targetClass = 'Nail',
  }) async {
    final apiKey = RoboflowConfig.apiKey;
    if (apiKey == null) {
      throw NailDetectionException(
        'Add ROBOFLOW_API_KEY to .env to detect nails.',
      );
    }

    final response = await http.post(
      RoboflowConfig.workflowInferUri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'api_key': apiKey,
        'inputs': {
          'image': {
            'type': 'base64',
            'value': base64Encode(imageBytes),
          },
        },
        'parameters': {
          'classes': targetClass,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw NailDetectionException(
        _messageFromErrorBody(response.statusCode, response.body),
      );
    }

    final decoded = jsonDecode(response.body);
    final nails = _parseNails(decoded, targetClass: targetClass);
    if (nails.isEmpty) {
      throw NailDetectionException(
        'No nails detected. Try a clearer photo with fingers spread.',
      );
    }

    if (kDebugMode) {
      debugPrint('Roboflow: detected ${nails.length} nail(s)');
    }
    return nails;
  }

  String _messageFromErrorBody(int status, String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map && json['message'] is String) {
        return json['message'] as String;
      }
    } catch (_) {}
    return 'Nail detection failed (HTTP $status).';
  }

  List<DetectedNail> _parseNails(
    dynamic node, {
    required String targetClass,
    List<DetectedNail> acc = const [],
    int depth = 0,
  }) {
    if (depth > 24) {
      return acc;
    }

    var results = List<DetectedNail>.from(acc);

    if (node is Map) {
      final nail = _predictionFromMap(node, targetClass: targetClass);
      if (nail != null) {
        results.add(nail);
      }

      for (final value in node.values) {
        results = _parseNails(
          value,
          targetClass: targetClass,
          acc: results,
          depth: depth + 1,
        );
      }
    } else if (node is List) {
      for (final item in node) {
        results = _parseNails(
          item,
          targetClass: targetClass,
          acc: results,
          depth: depth + 1,
        );
      }
    }

    return _dedupeNails(results);
  }

  DetectedNail? _predictionFromMap(
    Map<dynamic, dynamic> map, {
    required String targetClass,
  }) {
    final className = _readString(map['class']) ??
        _readString(map['class_name']) ??
        _readString(map['label']);
    if (className != null &&
        className.toLowerCase() != targetClass.toLowerCase()) {
      return null;
    }

    final polygon = _readPolygon(map);
    if (polygon == null || polygon.length < 3) {
      return null;
    }

    final confidence = _readDouble(map['confidence']) ??
        _readDouble(map['score']) ??
        0.0;

    final bbox = _readBoundingBox(map);
    final id = _readString(map['detection_id']) ??
        _readString(map['id']) ??
        'nail_${polygon.length}_${polygon.first.dx.round()}_${polygon.first.dy.round()}_${confidence.toStringAsFixed(2)}';

    return DetectedNail(
      id: id,
      polygon: polygon,
      confidence: confidence,
      className: className ?? targetClass,
      boundingBox: bbox,
    );
  }

  List<Offset>? _readPolygon(Map<dynamic, dynamic> map) {
    final points = map['points'];
    if (points is List && points.isNotEmpty) {
      return _pointsFromList(points);
    }

    final segmentation = map['segmentation'];
    if (segmentation is List && segmentation.isNotEmpty) {
      final first = segmentation.first;
      if (first is List) {
        return _flatPolygon(first);
      }
      if (first is num) {
        return _flatPolygon(segmentation);
      }
    }

    final x = _readDouble(map['x']);
    final y = _readDouble(map['y']);
    final w = _readDouble(map['width']);
    final h = _readDouble(map['height']);
    if (x != null && y != null && w != null && h != null && w > 0 && h > 0) {
      return _boxPolygon(x, y, w, h);
    }

    return null;
  }

  List<Offset> _pointsFromList(List<dynamic> points) {
    final out = <Offset>[];
    for (final point in points) {
      if (point is Map) {
        final x = _readDouble(point['x']);
        final y = _readDouble(point['y']);
        if (x != null && y != null) {
          out.add(Offset(x, y));
        }
      } else if (point is List && point.length >= 2) {
        final x = _readDouble(point[0]);
        final y = _readDouble(point[1]);
        if (x != null && y != null) {
          out.add(Offset(x, y));
        }
      }
    }
    return out;
  }

  List<Offset> _flatPolygon(List<dynamic> values) {
    final out = <Offset>[];
    for (var i = 0; i + 1 < values.length; i += 2) {
      final x = _readDouble(values[i]);
      final y = _readDouble(values[i + 1]);
      if (x != null && y != null) {
        out.add(Offset(x, y));
      }
    }
    return out;
  }

  List<Offset> _boxPolygon(double x, double y, double w, double h) {
    final left = x - w / 2;
    final top = y - h / 2;
    final right = x + w / 2;
    final bottom = y + h / 2;
    return [
      Offset(left, top),
      Offset(right, top),
      Offset(right, bottom),
      Offset(left, bottom),
    ];
  }

  Rect? _readBoundingBox(Map<dynamic, dynamic> map) {
    final x = _readDouble(map['x']);
    final y = _readDouble(map['y']);
    final w = _readDouble(map['width']);
    final h = _readDouble(map['height']);
    if (x == null || y == null || w == null || h == null) {
      return null;
    }
    return Rect.fromCenter(center: Offset(x, y), width: w, height: h);
  }

  double? _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  String? _readString(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  List<DetectedNail> _dedupeNails(List<DetectedNail> nails) {
    final seen = <String>{};
    final out = <DetectedNail>[];
    for (final nail in nails) {
      if (seen.add(nail.id)) {
        out.add(nail);
      }
    }
    return out;
  }
}
