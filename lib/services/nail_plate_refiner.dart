import 'dart:math' as math;
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:hand_detection/hand_detection.dart';

import '../models/nail_bed_geometry.dart';
import '../core/camera/camera_luma_sampler.dart';
import '../core/camera/nail_bed_geometry.dart';
import '../models/nail_finger.dart';
import 'hand_tracking_service.dart';

/// Finds each nail plate on the live camera feed using finger landmarks plus
/// on-device brightness analysis along the distal phalanx (cuticle + edges).
class NailPlateRefiner {
  int _frame = 0;
  final _previous = <NailFinger, NailBedGeometry>{};
  static const _smoothAlpha = 0.34;

  Map<NailFinger, NailBedGeometry> refine({
    required TrackedHandFrame hand,
    required Map<HandLandmarkType, Offset> sourceLandmarks,
    required Size sourceImageSize,
    required CameraPreviewMapper mapper,
    required CameraImage image,
    required CameraFrameRotation? rotation,
    required int maxDim,
    required double overlayScale,
    required Map<NailFinger, CameraNailMetrics?> metricsByFinger,
    bool thumbOnly = false,
  }) {
    _frame++;
    final useLuma = thumbOnly || _frame.isEven;
    final smoothAlpha = thumbOnly ? 0.58 : _smoothAlpha;
    final lumaBlend = thumbOnly ? 0.74 : 0.62;

    CameraLumaSampler? sampler;
    if (useLuma) {
      sampler = CameraLumaSampler(
        image: image,
        rotation: rotation,
        detectionSize: math.Rectangle<int>(
          0,
          0,
          sourceImageSize.width.round(),
          sourceImageSize.height.round(),
        ),
        maxDim: maxDim,
      );
    }

    final refined = <NailFinger, NailBedGeometry>{};
    final placements = thumbOnly
        ? const [NailFingerPlacement(
            finger: NailFinger.thumb,
            tip: HandLandmarkType.thumbTip,
            joint: HandLandmarkType.thumbIP,
            pip: HandLandmarkType.thumbMCP,
            mcp: HandLandmarkType.thumbCMC,
            minExtensionRatio: 1.02,
          )]
        : NailFingerPlacement.all;

    for (final placement in placements) {
      final active = thumbOnly
          ? isThumbVisibleForAr(hand)
          : isFingerActiveForPaint(hand, placement);
      if (!active) {
        continue;
      }

      final fingerMetrics = metricsByFinger[placement.finger];
      final landmarkGeom = _geometryFromLandmarks(
        hand: hand,
        placement: placement,
        metrics: fingerMetrics,
        overlayScale: overlayScale,
      );
      if (landmarkGeom == null) {
        continue;
      }

      NailBedGeometry geometry = landmarkGeom;
      if (sampler != null) {
        try {
          final lumaGeom = _geometryFromLuma(
            placement: placement,
            sourceLandmarks: sourceLandmarks,
            mapper: mapper,
            sampler: sampler,
            metrics: fingerMetrics,
            overlayScale: overlayScale,
            fallback: landmarkGeom,
          );
          if (lumaGeom != null) {
            geometry = _blendGeometry(landmarkGeom, lumaGeom, lumaBlend);
          }
        } catch (_) {
          // Luma refinement is best-effort; keep landmark geometry.
        }
      }

      final tip = hand.landmarks[placement.tip]!;
      final dip = hand.landmarks[placement.joint]!;
      final bedAxis = tip - dip;
      final bedLength = bedAxis.distance;
      if (bedLength >= 1) {
        geometry = nudgeCameraNailTowardTip(
          geometry,
          along: bedAxis / bedLength,
          bedLength: bedLength,
        );
      }

      geometry = attachPerspectiveQuad(
        geometry: geometry,
        hand: hand,
        placement: placement,
      );

      refined[placement.finger] = _smoothFinger(
        placement.finger,
        geometry,
        alpha: smoothAlpha,
      );
    }

    return refined;
  }

  NailBedGeometry _smoothFinger(
    NailFinger finger,
    NailBedGeometry next, {
    double alpha = _smoothAlpha,
  }) {
    final prior = _previous[finger];
    if (prior == null) {
      _previous[finger] = next;
      return next;
    }

    List<Offset>? smoothedQuad;
    final priorQuad = prior.quad;
    final nextQuad = next.quad;
    if (priorQuad != null &&
        nextQuad != null &&
        priorQuad.length == 4 &&
        nextQuad.length == 4) {
      smoothedQuad = List<Offset>.generate(
        4,
        (i) => Offset.lerp(priorQuad[i], nextQuad[i], alpha)!,
      );
    } else {
      smoothedQuad = nextQuad;
    }

    _previous[finger] = NailBedGeometry(
      center: Offset.lerp(prior.center, next.center, alpha)!,
      width: prior.width + (next.width - prior.width) * alpha,
      height: prior.height + (next.height - prior.height) * alpha,
      angle: _lerpAngle(prior.angle, next.angle, alpha),
      quad: smoothedQuad,
    );
    return _previous[finger]!;
  }

  void reset() {
    _previous.clear();
    _frame = 0;
  }

  NailBedGeometry? _geometryFromLandmarks({
    required TrackedHandFrame hand,
    required NailFingerPlacement placement,
    required CameraNailMetrics? metrics,
    required double overlayScale,
  }) {
    if (placement.finger == NailFinger.thumb) {
      return computeThumbNailBedGeometry(
        hand: hand,
        scale: overlayScale,
        metrics: metrics,
      );
    }

    final tip = hand.landmarks[placement.tip];
    final dip = hand.landmarks[placement.joint];
    final pip = hand.landmarks[placement.pip];
    final mcp = hand.landmarks[placement.mcp];
    if (tip == null || dip == null || pip == null || mcp == null) {
      return null;
    }

    final axis = tip - dip;
    final bedLength = axis.distance;
    if (bedLength < 8) {
      return null;
    }

    var along = axis / bedLength;
    var perp = Offset(-along.dy, along.dx);

    final knuckle = pip - mcp;
    if (knuckle.distance > 6) {
      final knucklePerp = Offset(-knuckle.dy, knuckle.dx) / knuckle.distance;
      perp = Offset.lerp(perp, knucklePerp, 0.22)!;
      perp = perp / perp.distance;
    }

    if (placement.finger == NailFinger.thumb) {
      final thumbRoll = _thumbRollCorrection(hand);
      if (thumbRoll != null) {
        along = Offset.lerp(along, thumbRoll, 0.35)!;
        along = along / along.distance;
        perp = Offset(-along.dy, along.dx);
      }
    }

    final widthOverBed = metrics?.widthOverBed ??
        switch (placement.finger) {
          NailFinger.thumb => 1.08,
          NailFinger.pinky => 0.90,
          NailFinger.middle => 0.84,
          _ => 0.88,
        };
    final heightOverBed = metrics?.heightOverBed ?? 1.06;
    final cuticleT = switch (placement.finger) {
      NailFinger.thumb => 0.14,
      NailFinger.pinky => 0.20,
      _ => 0.17,
    };
    final tipT = 0.96;

    final cuticle = dip + along * (bedLength * cuticleT);
    final nailTip = dip + along * (bedLength * tipT);
    final nailAxis = nailTip - cuticle;
    final nailLen = nailAxis.distance.clamp(6.0, 999.0);

    final width = (bedLength * widthOverBed * overlayScale).clamp(10.0, 120.0);
    final height = (nailLen * heightOverBed * overlayScale).clamp(12.0, 130.0);

    var center = cuticle + nailAxis * 0.5;
    final across = metrics?.acrossOffsetBed ?? 0;
    final alongOff = metrics?.alongOffsetBed ?? 0;
    center += along * (bedLength * alongOff);
    center += perp * (bedLength * across);

    var angle =
        math.atan2(nailAxis.dy, nailAxis.dx) + math.pi / 2 + (metrics?.angleOffset ?? 0);

    if (placement.finger == NailFinger.thumb) {
      angle += _thumbAngleBoost(hand);
    }

    return NailBedGeometry(
      center: center,
      width: width,
      height: height,
      angle: angle,
    );
  }

  NailBedGeometry? _geometryFromLuma({
    required NailFingerPlacement placement,
    required Map<HandLandmarkType, Offset> sourceLandmarks,
    required CameraPreviewMapper mapper,
    required CameraLumaSampler sampler,
    required CameraNailMetrics? metrics,
    required double overlayScale,
    required NailBedGeometry fallback,
  }) {
    final tip = sourceLandmarks[placement.tip];
    final dip = sourceLandmarks[placement.joint];
    if (tip == null || dip == null) {
      return null;
    }

    final axis = tip - dip;
    final bedLen = axis.distance;
    if (bedLen < 6) {
      return null;
    }
    final along = axis / bedLen;
    final perp = Offset(-along.dy, along.dx);

    final profile = sampler.sampleLine(dip, tip, steps: 22);
    if (profile.length < 6) {
      return null;
    }

    final cuticleIndex = _findCuticleIndex(profile);
    final tipIndex = _findTipIndex(profile, cuticleIndex);
    if (tipIndex <= cuticleIndex + 2) {
      return null;
    }

    final cuticleT = cuticleIndex / (profile.length - 1);
    final tipT = tipIndex / (profile.length - 1);
    final cuticle = dip + along * (bedLen * cuticleT);
    final nailTip = dip + along * (bedLen * tipT);
    final mid = cuticle + (nailTip - cuticle) * 0.55;

    final halfWidth = _findHalfWidth(sampler, mid, perp, bedLen * 0.42);
    if (halfWidth < 3) {
      return null;
    }

    final widthOverBed = metrics?.widthOverBed ??
        switch (placement.finger) {
          NailFinger.thumb => 1.08,
          _ => 0.88,
        };
    final width = (halfWidth * 2 * overlayScale * mapper.scale)
        .clamp(fallback.width * 0.75, fallback.width * 1.25);

  final nailAxis = nailTip - cuticle;
    final height = (nailAxis.distance *
            (metrics?.heightOverBed ?? 1.0) *
            overlayScale *
            mapper.scale)
        .clamp(fallback.height * 0.8, fallback.height * 1.2);

    final centerDet = cuticle + nailAxis * 0.5;
    final center = mapper.mapPoint(centerDet.dx, centerDet.dy);

    final angle = math.atan2(nailAxis.dy, nailAxis.dx) +
        math.pi / 2 +
        (metrics?.angleOffset ?? 0);

    // Blend width toward catalog ratio when luma width is noisy.
    final catalogWidth =
        (bedLen * widthOverBed * overlayScale * mapper.scale).clamp(10.0, 120.0);
    final blendedWidth = width * 0.7 + catalogWidth * 0.3;

    return NailBedGeometry(
      center: center,
      width: blendedWidth,
      height: height,
      angle: angle,
    );
  }

  int _findCuticleIndex(List<double> profile) {
    var maxGrad = 0.0;
    var index = 2;
    for (var i = 2; i < profile.length - 4; i++) {
      final grad = (profile[i + 2] - profile[i - 1]).abs();
      if (grad > maxGrad) {
        maxGrad = grad;
        index = i;
      }
    }
    return index.clamp(1, profile.length ~/ 3);
  }

  int _findTipIndex(List<double> profile, int cuticleIndex) {
    var peak = cuticleIndex;
    var peakVal = profile[cuticleIndex];
    for (var i = cuticleIndex + 1; i < profile.length; i++) {
      if (profile[i] >= peakVal - 6) {
        peakVal = math.max(peakVal, profile[i]);
        peak = i;
      }
    }
    return peak.clamp(cuticleIndex + 2, profile.length - 1);
  }

  double _findHalfWidth(
    CameraLumaSampler sampler,
    Offset center,
    Offset perp,
    double maxHalfWidth,
  ) {
    final centerLuma = sampler.sample(center.dx, center.dy);
    if (centerLuma == null) {
      return maxHalfWidth * 0.45;
    }

  var left = 0.0;
    for (var step = 2.0; step <= maxHalfWidth; step += 2) {
      final sample = sampler.sample(
        center.dx - perp.dx * step,
        center.dy - perp.dy * step,
      );
      if (sample == null || (centerLuma - sample).abs() > 18) {
        left = step;
        break;
      }
    }

    var right = 0.0;
    for (var step = 2.0; step <= maxHalfWidth; step += 2) {
      final sample = sampler.sample(
        center.dx + perp.dx * step,
        center.dy + perp.dy * step,
      );
      if (sample == null || (centerLuma - sample).abs() > 18) {
        right = step;
        break;
      }
    }

    final raw = (left + right) / 2;
    if (left == 0 && right == 0) {
      return maxHalfWidth * 0.45;
    }
    if (maxHalfWidth <= 4.0) {
      return raw.clamp(1.0, maxHalfWidth);
    }
    return raw.clamp(4.0, maxHalfWidth);
  }


  Offset? _thumbRollCorrection(TrackedHandFrame hand) {
    final ip = hand.landmarks[HandLandmarkType.thumbIP];
    final tip = hand.landmarks[HandLandmarkType.thumbTip];
    final indexMcp = hand.landmarks[HandLandmarkType.indexFingerMCP];
    if (ip == null || tip == null || indexMcp == null) {
      return null;
    }
    final nailAxis = (tip - ip).normalize();
    final spread = (indexMcp - ip).normalize();
    return Offset.lerp(nailAxis, spread, 0.4);
  }

  double _thumbAngleBoost(TrackedHandFrame hand) {
    final mcp = hand.landmarks[HandLandmarkType.thumbMCP];
    final ip = hand.landmarks[HandLandmarkType.thumbIP];
    final tip = hand.landmarks[HandLandmarkType.thumbTip];
    if (mcp == null || ip == null || tip == null) {
      return -0.28;
    }
    final proximal = (ip - mcp);
    final distal = (tip - ip);
    if (proximal.distance < 4 || distal.distance < 4) {
      return -0.28;
    }
    final a1 = math.atan2(proximal.dy, proximal.dx);
    final a2 = math.atan2(distal.dy, distal.dx);
    return (a2 - a1).clamp(-0.55, 0.15);
  }

  NailBedGeometry _blendGeometry(
    NailBedGeometry a,
    NailBedGeometry b,
    double t,
  ) {
    List<Offset>? blendedQuad;
    final aQuad = a.quad;
    final bQuad = b.quad;
    if (aQuad != null && bQuad != null && aQuad.length == 4 && bQuad.length == 4) {
      blendedQuad = List<Offset>.generate(
        4,
        (i) => Offset.lerp(aQuad[i], bQuad[i], t)!,
      );
    }

    return NailBedGeometry(
      center: Offset.lerp(a.center, b.center, t)!,
      width: a.width + (b.width - a.width) * t,
      height: a.height + (b.height - a.height) * t,
      angle: _lerpAngle(a.angle, b.angle, t),
      quad: blendedQuad ?? b.quad ?? a.quad,
    );
  }
}

double _lerpAngle(double from, double to, double t) {
  var delta = to - from;
  while (delta > math.pi) {
    delta -= math.pi * 2;
  }
  while (delta < -math.pi) {
    delta += math.pi * 2;
  }
  return from + delta * t;
}

extension on Offset {
  Offset normalize() {
    final len = distance;
    if (len < 1e-6) {
      return this;
    }
    return this / len;
  }
}
