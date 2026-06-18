class NailCategory {
  const NailCategory({
    required this.id,
    required this.name,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final int sortOrder;

  factory NailCategory.fromJson(Map<String, dynamic> json) {
    return NailCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}

class NailStyle {
  const NailStyle({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.shape,
    required this.thumbnailUrl,
    required this.prompt,
    required this.isPremium,
    required this.sortOrder,
  });

  final int id;
  final String name;
  final String categoryId;
  final String shape;
  final String? thumbnailUrl;
  final String prompt;
  final bool isPremium;
  final int sortOrder;

  bool get hasThumbnail =>
      thumbnailUrl != null && thumbnailUrl!.trim().isNotEmpty;

  factory NailStyle.fromJson(Map<String, dynamic> json) {
    final thumbnail = json['thumbnail_url'] as String?;
    return NailStyle(
      id: json['id'] as int,
      name: json['name'] as String,
      categoryId: json['category'] as String,
      shape: json['shape'] as String,
      thumbnailUrl: thumbnail != null && thumbnail.isNotEmpty ? thumbnail : null,
      prompt: json['prompt'] as String,
      isPremium: json['is_premium'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}
