import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';

/// Rasterizes an SVG asset to a [ui.Image] for nail texture warping.
Future<ui.Image> rasterizeSvgAsset(
  String assetPath, {
  double pixelScale = 2.0,
}) async {
  final loader = SvgAssetLoader(assetPath);
  final pictureInfo = await vg.loadPicture(loader, null);

  final width = (pictureInfo.size.width * pixelScale).ceil().clamp(1, 4096);
  final height = (pictureInfo.size.height * pixelScale).ceil().clamp(1, 4096);
  final image = await pictureInfo.picture.toImage(width, height);
  pictureInfo.picture.dispose();
  return image;
}
