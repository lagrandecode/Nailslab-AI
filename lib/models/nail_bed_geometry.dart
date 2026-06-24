import 'dart:ui';

/// On-screen size, rotation, and center for painting one nail.
/// When [quad] is set, the nail is perspective-warped to those 4 corners
/// (top-left, top-right, bottom-right, bottom-left) for 3D finger rotation.
class NailBedGeometry {
  const NailBedGeometry({
    required this.center,
    required this.width,
    required this.height,
    required this.angle,
    this.quad,
  });

  final Offset center;
  final double width;
  final double height;
  final double angle;
  final List<Offset>? quad;
}
