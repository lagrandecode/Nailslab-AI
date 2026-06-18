import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/nail_look.dart';

class NailLookRepository {
  NailLookRepository._();

  static final NailLookRepository instance = NailLookRepository._();

  static const _assetPath = 'assets/data/nail_looks.json';

  List<NailLook>? _looks;

  Future<void> ensureLoaded() async {
    if (_looks != null) {
      return;
    }

    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _looks = (decoded['looks'] as List<dynamic>)
        .map((item) => NailLook.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  List<NailLook> get all => List.unmodifiable(_looks ?? const []);

  NailLook? byId(String id) {
    for (final look in all) {
      if (look.id == id) {
        return look;
      }
    }
    return null;
  }
}
