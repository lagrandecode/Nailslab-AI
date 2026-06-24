import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../models/nail_bed_geometry.dart';
import 'nail_bed_geometry.dart' show buildNailClipPath, flatGeometryFromPerspective, isValidNailQuad, nailQuadPath;

/// Paints a nail image warped to a 4-corner quad (3D perspective on the finger).
void paintNailOnQuad(
  Canvas canvas,
  ui.Image image,
  List<Offset> quad,
) {
  if (quad.length != 4 || !isValidNailQuad(quad)) {
    return;
  }

  final vertices = ui.Vertices(
    ui.VertexMode.triangles,
    [
      quad[0],
      quad[1],
      quad[2],
      quad[0],
      quad[2],
      quad[3],
    ],
    textureCoordinates: const [
      Offset(0, 0),
      Offset(1, 0),
      Offset(1, 1),
      Offset(0, 0),
      Offset(1, 1),
      Offset(0, 1),
    ],
  );

  // Normalized UVs (0–1); identity matrix maps to full image per Flutter docs.
  canvas.drawVertices(
    vertices,
    BlendMode.srcOver,
    Paint()
      ..shader = ui.ImageShader(
        image,
        TileMode.clamp,
        TileMode.clamp,
        Matrix4.identity().storage,
      )
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true,
  );
}

/// Paints using a flat rotated rect (fallback when no quad).
void paintNailFlat(
  Canvas canvas,
  ui.Image image,
  NailBedGeometry geometry,
) {
  canvas.save();
  canvas.translate(geometry.center.dx, geometry.center.dy);
  canvas.rotate(geometry.angle);

  final dstRect = Rect.fromCenter(
    center: Offset.zero,
    width: geometry.width,
    height: geometry.height,
  );
  final srcRect = Rect.fromLTWH(
    0,
    0,
    image.width.toDouble(),
    image.height.toDouble(),
  );

  canvas.drawImageRect(
    image,
    srcRect,
    dstRect,
    Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true,
  );
  canvas.restore();
}

void paintNail(
  Canvas canvas,
  ui.Image image,
  NailBedGeometry geometry,
) {
  paintNailReliable(canvas, image, geometry);
}

/// Clips to the perspective quad when available, then paints with drawImageRect.
void paintNailReliable(
  Canvas canvas,
  ui.Image image,
  NailBedGeometry geometry,
) {
  final flat = flatGeometryFromPerspective(geometry);
  final quad = flat.quad;
  if (quad != null && isValidNailQuad(quad)) {
    canvas.save();
    canvas.clipPath(nailQuadPath(quad));
    paintNailFlat(canvas, image, flat);
    canvas.restore();
    return;
  }
  paintNailFlat(canvas, image, flat);
}

/// Warps the reference nail photo to the detected bed.
void paintThumbNailTexture(
  Canvas canvas,
  ui.Image texture,
  NailBedGeometry geometry,
) {
  paintNailReliable(canvas, texture, geometry);
}

/// Warps an optional reference nail mask to the detected bed, then tints with polish.
/// When [maskImage] is null, falls back to a geometric nail-bed mask.
void paintThumbPolish(
  Canvas canvas,
  NailBedGeometry geometry, {
  ui.Image? maskImage,
  required Color color,
  double opacity = 0.72,
}) {
  if (maskImage == null) {
    paintNailMask(
      canvas,
      geometry,
      color: color,
      opacity: opacity,
    );
    return;
  }

  final quad = geometry.quad;
  if (quad != null && quad.length == 4 && isValidNailQuad(quad)) {
    paintThumbPolishReliable(
      canvas,
      maskImage,
      geometry,
      color: color,
      opacity: opacity,
    );
    return;
  }

  paintThumbPolishFlat(
    canvas,
    maskImage,
    geometry,
    color: color,
    opacity: opacity,
  );
}

void paintThumbPolishReliable(
  Canvas canvas,
  ui.Image maskImage,
  NailBedGeometry geometry, {
  required Color color,
  double opacity = 0.72,
}) {
  final flat = flatGeometryFromPerspective(geometry);
  final quad = flat.quad;
  if (quad != null && isValidNailQuad(quad)) {
    canvas.save();
    canvas.clipPath(nailQuadPath(quad));
    paintThumbPolishFlat(
      canvas,
      maskImage,
      flat,
      color: color,
      opacity: opacity,
    );
    canvas.restore();
    return;
  }
  paintThumbPolishFlat(
    canvas,
    maskImage,
    flat,
    color: color,
    opacity: opacity,
  );
}

void paintThumbPolishOnQuad(
  Canvas canvas,
  ui.Image maskImage,
  List<Offset> quad, {
  required Color color,
  double opacity = 0.72,
}) {
  if (quad.length != 4 || !isValidNailQuad(quad)) {
    return;
  }

  canvas.saveLayer(null, Paint());
  paintNailOnQuad(canvas, maskImage, quad);
  canvas.drawPaint(
    Paint()
      ..color = color.withValues(alpha: opacity)
      ..blendMode = BlendMode.srcIn,
  );

  final glossPath = Path()
    ..moveTo(quad[0].dx, quad[0].dy)
    ..lineTo(quad[1].dx, quad[1].dy)
    ..lineTo(quad[1].dx + (quad[2].dx - quad[1].dx) * 0.35, quad[1].dy + (quad[2].dy - quad[1].dy) * 0.35)
    ..lineTo(quad[0].dx + (quad[3].dx - quad[0].dx) * 0.35, quad[0].dy + (quad[3].dy - quad[0].dy) * 0.35)
    ..close();
  canvas.drawPath(
    glossPath,
    Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..blendMode = BlendMode.softLight,
  );
  canvas.restore();
}

void paintThumbPolishFlat(
  Canvas canvas,
  ui.Image maskImage,
  NailBedGeometry geometry, {
  required Color color,
  double opacity = 0.72,
}) {
  canvas.save();
  canvas.translate(geometry.center.dx, geometry.center.dy);
  canvas.rotate(geometry.angle);

  final dstRect = Rect.fromCenter(
    center: Offset.zero,
    width: geometry.width,
    height: geometry.height,
  );
  final srcRect = Rect.fromLTWH(
    0,
    0,
    maskImage.width.toDouble(),
    maskImage.height.toDouble(),
  );

  canvas.saveLayer(dstRect.inflate(2), Paint());
  canvas.drawImageRect(
    maskImage,
    srcRect,
    dstRect,
    Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true,
  );
  canvas.drawRect(
    dstRect,
    Paint()
      ..color = color.withValues(alpha: opacity)
      ..blendMode = BlendMode.srcIn,
  );
  canvas.restore();
  canvas.restore();
}

/// Semi-transparent polish overlay on the detected nail bed (live AR mask).
void paintNailMask(
  Canvas canvas,
  NailBedGeometry geometry, {
  required Color color,
  double opacity = 0.58,
}) {
  final quad = geometry.quad;
  if (quad != null && quad.length == 4 && isValidNailQuad(quad)) {
    paintNailMaskOnQuad(canvas, quad, color: color, opacity: opacity);
  } else {
    paintNailMaskFlat(canvas, geometry, color: color, opacity: opacity);
  }
}

void paintNailMaskOnQuad(
  Canvas canvas,
  List<Offset> quad, {
  required Color color,
  double opacity = 0.58,
}) {
  if (quad.length != 4 || !isValidNailQuad(quad)) {
    return;
  }

  final path = Path()
    ..moveTo(quad[0].dx, quad[0].dy)
    ..lineTo(quad[1].dx, quad[1].dy)
    ..lineTo(quad[2].dx, quad[2].dy)
    ..lineTo(quad[3].dx, quad[3].dy)
    ..close();

  canvas.drawPath(
    path,
    Paint()
      ..color = color.withValues(alpha: opacity)
      ..blendMode = BlendMode.hardLight
      ..isAntiAlias = true,
  );

  canvas.drawPath(
    path,
    Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..blendMode = BlendMode.softLight
      ..isAntiAlias = true,
  );

  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.35)
      ..isAntiAlias = true,
  );
}

void paintNailMaskFlat(
  Canvas canvas,
  NailBedGeometry geometry, {
  required Color color,
  double opacity = 0.58,
}) {
  canvas.save();
  canvas.translate(geometry.center.dx, geometry.center.dy);
  canvas.rotate(geometry.angle);

  final clipPath = buildNailClipPath(geometry.width, geometry.height);

  canvas.drawPath(
    clipPath,
    Paint()
      ..color = color.withValues(alpha: opacity)
      ..blendMode = BlendMode.hardLight
      ..isAntiAlias = true,
  );

  final gloss = Path()
    ..addOval(
      Rect.fromCenter(
        center: Offset(0, -geometry.height * 0.14),
        width: geometry.width * 0.34,
        height: geometry.height * 0.42,
      ),
    );
  canvas.clipPath(clipPath);
  canvas.drawPath(
    gloss,
    Paint()
      ..color = Colors.white.withValues(alpha: 0.24)
      ..blendMode = BlendMode.softLight
      ..isAntiAlias = true,
  );

  canvas.restore();

  canvas.save();
  canvas.translate(geometry.center.dx, geometry.center.dy);
  canvas.rotate(geometry.angle);
  canvas.drawPath(
    clipPath,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.35)
      ..isAntiAlias = true,
  );
  canvas.restore();
}
