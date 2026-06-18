import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/nail_style.dart';

/// Loads nail styles from bundled JSON today; swap for Firestore/SQLite later.
class NailStyleRepository {
  NailStyleRepository._();

  static final NailStyleRepository instance = NailStyleRepository._();

  static const _assetPath = 'assets/data/nail_styles.json';

  List<NailCategory>? _categories;
  List<NailStyle>? _styles;

  Future<void> ensureLoaded() async {
    if (_styles != null) {
      return;
    }

    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    _categories = (decoded['categories'] as List<dynamic>)
        .map((item) => NailCategory.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    _styles = (decoded['styles'] as List<dynamic>)
        .map((item) => NailStyle.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  List<NailCategory> get categories => List.unmodifiable(_categories ?? const []);

  List<NailStyle> get allStyles => List.unmodifiable(_styles ?? const []);

  List<NailStyle> stylesForCategory(String categoryId) {
    return allStyles.where((style) => style.categoryId == categoryId).toList();
  }

  NailCategory? categoryById(String categoryId) {
    for (final category in categories) {
      if (category.id == categoryId) {
        return category;
      }
    }
    return null;
  }
}
