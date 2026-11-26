/// The one function that plays a [CoreHapticCue] on Flutter.
///
/// This is a seam, not a haptics layer: no intensity, no pattern, no global
/// switch. A component that wants a cue has its own opt-in flag and calls
/// this; the system decides how a selection tick feels, which is the point of
/// asking it.
library;

import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:flutter/services.dart';

/// Plays [cue] through the platform's haptic engine. Devices without one
/// ignore it.
void playHapticCue(CoreHapticCue cue) {
  switch (cue) {
    case .selectionTick:
      unawaited(HapticFeedback.selectionClick());
  }
}
