import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config/nail_detect_config.dart';
import '../models/detected_nail.dart';
import 'nail_detection_exception.dart';

/// Calls your nail detect endpoint (local dev server or Firebase Cloud Function).
class HttpNailDetectionService {
  const HttpNailDetectionService();

  Future<List<DetectedNail>> detectNails({
    required Uint8List imageBytes,
  }) async {
    final url = NailDetectConfig.detectUrl;
    if (url == null) {
      throw NailDetectionException(
        'Add NAIL_DETECT_URL to .env (local server or Cloud Function).',
      );
    }

    final response = await _postDetect(url, imageBytes);

    Map<String, dynamic>? decoded;
    try {
      final raw = jsonDecode(response.body);
      if (raw is Map<String, dynamic>) {
        decoded = raw;
      }
    } catch (_) {}

    if (response.statusCode != 200) {
      final message = decoded?['error'] as String? ??
          'Nail detection failed (HTTP ${response.statusCode}).';
      throw NailDetectionException(message);
    }

    final nails = _parseNails(decoded);
    if (nails.isEmpty) {
      throw NailDetectionException(
        decoded?['error'] as String? ??
            'No nails detected. Try a clearer photo with fingers spread.',
      );
    }

    if (kDebugMode) {
      debugPrint('Nail detect: ${nails.length} nail(s) from $url');
    }
    return nails;
  }

  List<DetectedNail> _parseNails(Map<String, dynamic>? body) {
    if (body == null) {
      return const [];
    }

    final items = body['nails'];
    if (items is! List) {
      return const [];
    }

    final out = <DetectedNail>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is! Map) {
        continue;
      }

      final polygon = _readPolygon(item);
      if (polygon == null || polygon.length < 3) {
        continue;
      }

      final id = _readString(item['id']) ?? 'nail_$i';
      final className =
          _readString(item['class_name']) ?? _readString(item['class']) ?? 'Nail';
      final confidence = _readDouble(item['confidence']) ?? 0.0;
      final bboxMap = item['bounding_box'];
      Rect? bbox;
      if (bboxMap is Map) {
        final x = _readDouble(bboxMap['x']);
        final y = _readDouble(bboxMap['y']);
        final w = _readDouble(bboxMap['width']);
        final h = _readDouble(bboxMap['height']);
        if (x != null && y != null && w != null && h != null) {
          bbox = Rect.fromCenter(center: Offset(x, y), width: w, height: h);
        }
      }

      out.add(
        DetectedNail(
          id: id,
          polygon: polygon,
          confidence: confidence,
          className: className,
          boundingBox: bbox,
        ),
      );
    }
    return out;
  }

  List<Offset>? _readPolygon(Map<dynamic, dynamic> map) {
    final polygon = map['polygon'];
    if (polygon is List && polygon.isNotEmpty) {
      return _pointsFromList(polygon);
    }

    final points = map['points'];
    if (points is List && points.isNotEmpty) {
      return _pointsFromList(points);
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

  Future<http.Response> _postDetect(String url, Uint8List imageBytes) async {
    try {
      return await http
          .post(
            Uri.parse(url),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'image_base64': base64Encode(imageBytes)}),
          )
          .timeout(const Duration(seconds: 60));
    } on SocketException {
      throw NailDetectionException(_connectionHelp(url));
    } on HttpException {
      throw NailDetectionException(_connectionHelp(url));
    } on TimeoutException {
      throw NailDetectionException(
        'Detection timed out. Check that the server is running on your Mac.',
      );
    }
  }

  String _connectionHelp(String url) {
    final host = Uri.tryParse(url)?.host ?? '';
    if (host == '127.0.0.1' || host == 'localhost') {
      return 'Cannot reach the detect server at $host.\n'
          'On a physical phone, use your Mac Wi‑Fi IP in .env instead of 127.0.0.1, '
          'then run flutter run again.\n'
          'Also keep python tool/local_nail_detect_server.py running on your Mac.';
    }
    return 'Cannot reach nail detect server at $url.\n'
        'Check that the server is running and your phone is on the same Wi‑Fi.';
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
}
