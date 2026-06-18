class NailLook {
  const NailLook({
    required this.id,
    required this.name,
    required this.overlayAsset,
    required this.thumbnailAsset,
    required this.sortOrder,
    this.cropBottomFraction = 0.0,
    this.offsetY = 0.0,
  });

  final String id;
  final String name;
  final String overlayAsset;
  final String thumbnailAsset;
  final int sortOrder;
  final double cropBottomFraction;
  final double offsetY;

  factory NailLook.fromJson(Map<String, dynamic> json) {
    return NailLook(
      id: json['id'] as String,
      name: json['name'] as String,
      overlayAsset: json['overlay'] as String,
      thumbnailAsset: json['thumbnail'] as String? ?? json['overlay'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
      cropBottomFraction: (json['crop_bottom'] as num?)?.toDouble() ?? 0.0,
      offsetY: (json['offset_y'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
