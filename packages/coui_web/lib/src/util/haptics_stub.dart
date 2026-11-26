/// SSR-safe stub for `playHapticCue`.
///
/// There is no navigator on the server and nothing to feel, so a cue asked
/// for there is dropped. The browser implementation lives in
/// `haptics_web.dart`.
library;

import 'package:coui_core/coui_core.dart';

/// Stub — no vibration hardware during server rendering.
void playHapticCue(CoreHapticCue cue) {}
