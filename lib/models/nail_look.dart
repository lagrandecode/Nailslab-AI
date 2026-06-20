import 'nail_finger.dart';

class NailLook {
  const NailLook({
    required this.id,
    required this.name,
    required this.overlayAsset,
    required this.thumbnailAsset,
    required this.sortOrder,
    this.cropBottomFraction = 0.0,
    this.offsetY = 0.0,
    this.nailCrops = const {},
    this.plainHandLightAsset,
    this.plainHandBrownAsset,
    this.cameraNailMetrics = const {},
    this.cameraNailCrops = const {},
  });

  final String id;
  final String name;
  final String overlayAsset;
  final String thumbnailAsset;
  final int sortOrder;
  final double cropBottomFraction;
  final double offsetY;
  final Map<NailFinger, NailFingerCrop> nailCrops;
  final String? plainHandLightAsset;
  final String? plainHandBrownAsset;
  final Map<NailFinger, CameraNailMetrics> cameraNailMetrics;
  final Map<NailFinger, NailFingerCrop> cameraNailCrops;

  /// Crops for live camera, preferring baked-hand nail regions when present.
  Map<NailFinger, NailFingerCrop> get fingerCropsForCamera =>
      cameraNailCrops.isNotEmpty ? cameraNailCrops : nailCrops;

  /// Pre-rendered hand photo for plain mode (perfect nail alignment).
  String? plainHandAsset({required bool brownHand}) =>
      brownHand ? plainHandBrownAsset : plainHandLightAsset;

  /// True when plain mode can swap to a baked hand image instead of overlays.
  bool get hasPlainHandAssets =>
      plainHandLightAsset != null || plainHandBrownAsset != null;

  factory NailLook.fromJson(Map<String, dynamic> json) {
    final cropsJson = json['nail_crops'] as Map<String, dynamic>? ?? {};
    final crops = <NailFinger, NailFingerCrop>{};
    for (final entry in cropsJson.entries) {
      final finger = _fingerFromJsonKey(entry.key);
      final cropJson = entry.value;
      if (finger != null && cropJson is Map<String, dynamic>) {
        crops[finger] = NailFingerCrop.fromJson(cropJson);
      }
    }

    final cameraJson = json['camera_nail_size'] as Map<String, dynamic>? ?? {};
    final cameraMetrics = <NailFinger, CameraNailMetrics>{};
    for (final entry in cameraJson.entries) {
      final finger = _fingerFromJsonKey(entry.key);
      final metricsJson = entry.value;
      if (finger != null && metricsJson is Map<String, dynamic>) {
        cameraMetrics[finger] = CameraNailMetrics.fromJson(metricsJson);
      }
    }

    final cameraCropsJson = json['camera_nail_crops'] as Map<String, dynamic>? ?? {};
    final cameraCrops = <NailFinger, NailFingerCrop>{};
    for (final entry in cameraCropsJson.entries) {
      final finger = _fingerFromJsonKey(entry.key);
      final cropJson = entry.value;
      if (finger != null && cropJson is Map<String, dynamic>) {
        cameraCrops[finger] = NailFingerCrop.fromJson(cropJson);
      }
    }

    return NailLook(
      id: json['id'] as String,
      name: json['name'] as String,
      overlayAsset: json['overlay'] as String,
      thumbnailAsset: json['thumbnail'] as String? ?? json['overlay'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
      cropBottomFraction: (json['crop_bottom'] as num?)?.toDouble() ?? 0.0,
      offsetY: (json['offset_y'] as num?)?.toDouble() ?? 0.0,
      nailCrops: crops,
      plainHandLightAsset: json['plain_hand_light'] as String?,
      plainHandBrownAsset: json['plain_hand_brown'] as String?,
      cameraNailMetrics: cameraMetrics,
      cameraNailCrops: cameraCrops,
    );
  }

  static NailFinger? _fingerFromJsonKey(String key) {
    switch (key) {
      case 'thumb':
        return NailFinger.thumb;
      case 'index':
        return NailFinger.indexFinger;
      case 'middle':
        return NailFinger.middle;
      case 'ring':
        return NailFinger.ring;
      case 'pinky':
        return NailFinger.pinky;
      default:
        return null;
    }
  }
}
