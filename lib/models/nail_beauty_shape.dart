/// Which nail plate template variant to use.
enum NailPlateRole {
  finger,
  thumbSpread,
  thumbFront,
}

/// Built-in beauty shape (more added as SVG assets arrive).
enum NailBeautyShape {
  natural,
  square;

  static const pickerOrder = <NailBeautyShape>[natural, square];
}

extension NailBeautyShapeX on NailBeautyShape {
  String get label => switch (this) {
        NailBeautyShape.natural => 'Natural',
        NailBeautyShape.square => 'Square',
      };
}

extension NailPlateRoleX on NailPlateRole {
  String get assetStem => switch (this) {
        NailPlateRole.finger => 'finger',
        NailPlateRole.thumbSpread => 'thumb_spread',
        NailPlateRole.thumbFront => 'thumb_front',
      };
}
