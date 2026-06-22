import 'package:flutter/material.dart';

import 'nail_finger.dart';
import 'nail_look.dart';

/// Per-finger nail design + optional color tint for plain-mode painting.
class PlainFingerNailPaint {
  const PlainFingerNailPaint({
    this.look,
    this.tint,
  });

  final NailLook? look;
  final Color? tint;

  PlainFingerNailPaint copyWith({
    NailLook? look,
    bool clearLook = false,
    Color? tint,
    bool clearTint = false,
  }) {
    return PlainFingerNailPaint(
      look: clearLook ? null : (look ?? this.look),
      tint: clearTint ? null : (tint ?? this.tint),
    );
  }
}

/// All five nail beds on the static hand photo.
class PlainNailPaintState {
  const PlainNailPaintState({
    this.fingers = const {},
    this.selectedFinger,
  });

  final Map<NailFinger, PlainFingerNailPaint> fingers;
  final NailFinger? selectedFinger;

  PlainFingerNailPaint paintFor(NailFinger finger) =>
      fingers[finger] ?? const PlainFingerNailPaint();

  bool get hasAnyLook => fingers.values.any((paint) => paint.look != null);

  PlainNailPaintState copyWith({
    Map<NailFinger, PlainFingerNailPaint>? fingers,
    NailFinger? selectedFinger,
    bool clearSelection = false,
  }) {
    return PlainNailPaintState(
      fingers: fingers ?? this.fingers,
      selectedFinger: clearSelection ? null : (selectedFinger ?? this.selectedFinger),
    );
  }

  PlainNailPaintState applyLookToAll(NailLook look) {
    final updated = <NailFinger, PlainFingerNailPaint>{};
    for (final finger in NailFinger.values) {
      updated[finger] = paintFor(finger).copyWith(look: look);
    }
    return copyWith(fingers: updated);
  }

  PlainNailPaintState applyLookToFinger(NailLook look, NailFinger finger) {
    final updated = Map<NailFinger, PlainFingerNailPaint>.from(fingers);
    updated[finger] = paintFor(finger).copyWith(look: look);
    return copyWith(fingers: updated);
  }

  PlainNailPaintState applyTint(Color? tint, {NailFinger? finger}) {
    final updated = Map<NailFinger, PlainFingerNailPaint>.from(fingers);
    final targets = finger != null ? [finger] : NailFinger.values;
    for (final f in targets) {
      if (tint == null) {
        updated[f] = paintFor(f).copyWith(clearTint: true);
      } else {
        updated[f] = paintFor(f).copyWith(tint: tint);
      }
    }
    return copyWith(fingers: updated);
  }
}
