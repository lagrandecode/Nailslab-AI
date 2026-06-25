import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:hand_detection/hand_detection.dart';

import '../models/detected_nail.dart';
import '../models/nail_finger.dart';

/// Labels each detected nail with a [NailFinger] using MediaPipe fingertip landmarks.
class NailFingerMatcherService {
  HandDetector? _detector;

  Future<void> ensureInitialized() async {
    _detector ??= await HandDetector.create(
      mode: HandMode.boxesAndLandmarks,
      detectorConf: 0.35,
      maxDetections: 1,
    );
  }

  Future<List<DetectedNail>> labelNails({
    required Uint8List photoBytes,
    required List<DetectedNail> nails,
  }) async {
    if (nails.isEmpty) {
      return nails;
    }

    await ensureInitialized();
    final detector = _detector;
    if (detector == null) {
      return nails;
    }

    try {
      final hands = await detector.detect(photoBytes);
      if (hands.isEmpty || !hands.first.hasLandmarks) {
        if (kDebugMode) {
          debugPrint('NailFingerMatcher: no hand landmarks — keeping unlabeled nails');
        }
        return nails;
      }

      final tips = _fingertips(hands.first);
      if (tips.isEmpty) {
        return nails;
      }

      return _assignByNearestTip(nails, tips, hands.first);
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('NailFingerMatcher error: $e\n$stack');
      }
      return nails;
    }
  }

  Map<NailFinger, Offset> _fingertips(Hand hand) {
    final tips = <NailFinger, Offset>{};
    for (final placement in NailFingerPlacement.all) {
      for (final landmark in hand.landmarks) {
        if (landmark.type != placement.tip || landmark.visibility < 0.2) {
          continue;
        }
        tips[placement.finger] = Offset(landmark.x, landmark.y);
        break;
      }
    }
    return tips;
  }

  List<DetectedNail> _assignByNearestTip(
    List<DetectedNail> nails,
    Map<NailFinger, Offset> tips,
    Hand hand,
  ) {
    final imageDiag = math.sqrt(
      hand.imageWidth * hand.imageWidth + hand.imageHeight * hand.imageHeight,
    );
    final maxDist = imageDiag * 0.12;

    final pairs = <_NailFingerPair>[];
    for (final nail in nails) {
      final center = _centroid(nail.detectionPolygon);
      for (final entry in tips.entries) {
        pairs.add(
          _NailFingerPair(
            nailId: nail.id,
            finger: entry.key,
            distance: (center - entry.value).distance,
          ),
        );
      }
    }
    pairs.sort((a, b) => a.distance.compareTo(b.distance));

    final assignedNails = <String>{};
    final assignedFingers = <NailFinger>{};
    final fingerByNailId = <String, NailFinger>{};

    for (final pair in pairs) {
      if (pair.distance > maxDist) {
        continue;
      }
      if (assignedNails.contains(pair.nailId) ||
          assignedFingers.contains(pair.finger)) {
        continue;
      }
      assignedNails.add(pair.nailId);
      assignedFingers.add(pair.finger);
      fingerByNailId[pair.nailId] = pair.finger;
    }

    if (kDebugMode) {
      debugPrint(
        'NailFingerMatcher: labeled ${fingerByNailId.length}/${nails.length} nails',
      );
    }

    return nails
        .map((n) => n.copyWith(finger: fingerByNailId[n.id]))
        .toList(growable: false);
  }

  Future<void> dispose() async {
    await _detector?.dispose();
    _detector = null;
  }
}

class _NailFingerPair {
  const _NailFingerPair({
    required this.nailId,
    required this.finger,
    required this.distance,
  });

  final String nailId;
  final NailFinger finger;
  final double distance;
}

Offset _centroid(List<Offset> polygon) {
  var x = 0.0;
  var y = 0.0;
  for (final p in polygon) {
    x += p.dx;
    y += p.dy;
  }
  return Offset(x / polygon.length, y / polygon.length);
}
