import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../models/nail_bed_geometry.dart';
import 'nail_bed_geometry.dart' show buildNailClipPath, flatGeometryFromPerspective, isValidNailQuad, nailQuadPath;

/// Warps nail texture to the 4-corner quad (perspective — shape follows hand rotation).
void paintNailOnQuad(
  Canvas canvas,
  ui.Image image,
  List<Offset> quad,
) {
  if (quad.length != 4 || !isValidNailQuad(quad)) {
    return;
  }

  final iw = image.width.toDouble();
  final ih = image.height.toDouble();

  canvas.drawVertices(
    ui.Vertices(
      ui.VertexMode.triangles,
      [
        quad[0],
        quad[1],
        quad[2],
        quad[0],
        quad[2],
        quad[3],
      ],
      textureCoordinates: [
        const Offset(0, 0),
        Offset(iw, 0),
        Offset(iw, ih),
        const Offset(0, 0),
        Offset(iw, ih),
        Offset(0, ih),
      ],
    ),
    BlendMode.srcOver,
    Paint()
      ..shader = ui.ImageShader(
        image,
        TileMode.clamp,
        TileMode.clamp,
        Matrix4.diagonal3Values(1 / iw, 1 / ih, 1).storage,
      )
      ..filterQuality = FilterQuality.medium
      ..isAntiAlias = true,
  );
}

/// Subdivided quad warp — smoother perspective on devices where a single quad is weak.
void paintNailOnQuadMesh(
  Canvas canvas,
  ui.Image image,
  List<Offset> quad, {
  int subdivisions = 3,
  Rect? textureRect,
}) {
  if (quad.length != 4 || !isValidNailQuad(quad)) {
    return;
  }

  final iw = image.width.toDouble();
  final ih = image.height.toDouble();
  final src = textureRect ?? Rect.fromLTWH(0, 0, iw, ih);
  final shader = ui.ImageShader(
    image,
    TileMode.clamp,
    TileMode.clamp,
    Matrix4.diagonal3Values(1 / iw, 1 / ih, 1).storage,
  );
  final paint = Paint()
    ..shader = shader
    ..filterQuality = FilterQuality.high
    ..isAntiAlias = true;

  Offset texCoord(double u, double v) {
    return Offset(src.left + u * src.width, src.top + v * src.height);
  }

  Offset bilinear(double u, double v) {
    final top = Offset.lerp(quad[0], quad[1], u)!;
    final bottom = Offset.lerp(quad[3], quad[2], u)!;
    return Offset.lerp(top, bottom, v)!;
  }

  final n = subdivisions;
  for (var row = 0; row < n; row++) {
    final v0 = row / n;
    final v1 = (row + 1) / n;
    for (var col = 0; col < n; col++) {
      final u0 = col / n;
      final u1 = (col + 1) / n;

      final p00 = bilinear(u0, v0);
      final p10 = bilinear(u1, v0);
      final p11 = bilinear(u1, v1);
      final p01 = bilinear(u0, v1);

      final t00 = texCoord(u0, v0);
      final t10 = texCoord(u1, v0);
      final t11 = texCoord(u1, v1);
      final t01 = texCoord(u0, v1);

      canvas.drawVertices(
        ui.Vertices(
          ui.VertexMode.triangles,
          [p00, p10, p11, p00, p11, p01],
          textureCoordinates: [t00, t10, t11, t00, t11, t01],
        ),
        BlendMode.srcOver,
        paint,
      );
    }
  }
}

/// Paints using a flat rotated rect (fallback when no quad).
void paintNailFlat(
  Canvas canvas,
  ui.Image image,
  NailBedGeometry geometry, {
  Rect? textureRect,
}) {
  canvas.save();
  canvas.translate(geometry.center.dx, geometry.center.dy);
  canvas.rotate(geometry.angle);

  final dstRect = Rect.fromCenter(
    center: Offset.zero,
    width: geometry.width,
    height: geometry.height,
  );
  final srcRect = textureRect ??
      Rect.fromLTWH(
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

/// Perspective mesh warp; flat clip underneath so the nail stays visible on all devices.
void paintNailReliable(
  Canvas canvas,
  ui.Image image,
  NailBedGeometry geometry,
) {
  final flat = flatGeometryFromPerspective(geometry);
  final quad = geometry.quad;
  if (quad != null && isValidNailQuad(quad)) {
    canvas.save();
    canvas.clipPath(nailQuadPath(quad));
    paintNailFlat(canvas, image, flat);
    canvas.restore();
    paintNailOnQuadMesh(canvas, image, quad);
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

/// YouCam-style live polish — tints the detected nail bed (no PNG texture).
enum NailPolishFinish { cream, metallic, matte, jelly, sheer }

void paintNailColorShader(
  Canvas canvas,
  NailBedGeometry geometry, {
  required Color color,
  double opacity = 0.74,
  NailPolishFinish finish = NailPolishFinish.cream,
}) {
  final quad = geometry.quad;
  if (quad != null && quad.length == 4 && isValidNailQuad(quad)) {
    paintNailColorShaderOnQuad(
      canvas,
      quad,
      color: color,
      opacity: opacity,
      finish: finish,
    );
    return;
  }
  paintNailColorShaderFlat(
    canvas,
    geometry,
    color: color,
    opacity: opacity,
    finish: finish,
  );
}

void paintNailColorShaderOnQuad(
  Canvas canvas,
  List<Offset> quad, {
  required Color color,
  double opacity = 0.74,
  NailPolishFinish finish = NailPolishFinish.cream,
}) {
  if (quad.length != 4 || !isValidNailQuad(quad)) {
    return;
  }

  final path = nailQuadPath(quad);
  final (blend, alpha, gloss) = _finishStyle(finish, opacity);

  canvas.drawPath(
    path,
    Paint()
      ..color = color.withValues(alpha: alpha)
      ..blendMode = blend
      ..isAntiAlias = true,
  );

  if (gloss > 0) {
    final glossPath = Path()
      ..moveTo(quad[0].dx, quad[0].dy)
      ..lineTo(quad[1].dx, quad[1].dy)
      ..lineTo(
        quad[1].dx + (quad[2].dx - quad[1].dx) * 0.38,
        quad[1].dy + (quad[2].dy - quad[1].dy) * 0.38,
      )
      ..lineTo(
        quad[0].dx + (quad[3].dx - quad[0].dx) * 0.38,
        quad[0].dy + (quad[3].dy - quad[0].dy) * 0.38,
      )
      ..close();
    canvas.drawPath(
      glossPath,
      Paint()
        ..color = Colors.white.withValues(alpha: gloss)
        ..blendMode = BlendMode.softLight
        ..isAntiAlias = true,
    );
  }
}

void paintNailColorShaderFlat(
  Canvas canvas,
  NailBedGeometry geometry, {
  required Color color,
  double opacity = 0.74,
  NailPolishFinish finish = NailPolishFinish.cream,
}) {
  canvas.save();
  canvas.translate(geometry.center.dx, geometry.center.dy);
  canvas.rotate(geometry.angle);

  final clipPath = buildNailClipPath(geometry.width, geometry.height);
  final (blend, alpha, gloss) = _finishStyle(finish, opacity);

  canvas.drawPath(
    clipPath,
    Paint()
      ..color = color.withValues(alpha: alpha)
      ..blendMode = blend
      ..isAntiAlias = true,
  );

  if (gloss > 0) {
    canvas.clipPath(clipPath);
    canvas.drawPath(
      Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(0, -geometry.height * 0.14),
            width: geometry.width * 0.34,
            height: geometry.height * 0.42,
          ),
        ),
      Paint()
        ..color = Colors.white.withValues(alpha: gloss)
        ..blendMode = BlendMode.softLight
        ..isAntiAlias = true,
    );
  }
  canvas.restore();
}

(BlendMode blend, double alpha, double gloss) _finishStyle(
  NailPolishFinish finish,
  double opacity,
) {
  return switch (finish) {
    NailPolishFinish.cream => (BlendMode.hardLight, opacity, 0.20),
    NailPolishFinish.metallic => (BlendMode.overlay, opacity * 0.92, 0.32),
    NailPolishFinish.matte => (BlendMode.color, opacity * 0.78, 0.0),
    NailPolishFinish.jelly => (BlendMode.softLight, opacity * 0.62, 0.14),
    NailPolishFinish.sheer => (BlendMode.color, opacity * 0.42, 0.08),
  };
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
