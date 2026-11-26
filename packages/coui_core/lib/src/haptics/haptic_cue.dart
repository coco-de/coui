/// The haptic cue a component can ask its seat to play.
///
/// This is a seam, not a haptics layer. The kit has no intensity scale, no
/// pattern language, no global on/off switch and no queue; a component that
/// wants a cue has its own opt-in flag and calls the one function its seat
/// provides. A second cue is added when a second component needs a second
/// feeling, not before.
///
/// Each seat plays a cue in the only terms its platform has:
///
/// * Flutter hands it to the system (`HapticFeedback.selectionClick`), which
///   decides the strength — the system's selection feel is the point.
/// * The Web has `navigator.vibrate`, which can only say how long, so the
///   cue carries that length (`pulseMilliseconds`). A browser without
///   `vibrate` (Safari) plays nothing.
library;

/// A haptic feeling a component asks for.
enum CoreHapticCue {
  /// A light tick: a selection moved to another item, or landed on one.
  ///
  /// The context menu plays it when a glide's highlight enters a row and when
  /// a release activates one.
  selectionTick(pulseMilliseconds: 10);

  const CoreHapticCue({required this.pulseMilliseconds});

  /// How long the cue pulses where the platform can only be told a duration
  /// (the Web's `navigator.vibrate`) — in milliseconds.
  ///
  /// A designer-judgement value: short enough to read as a tick and not as a
  /// buzz. It has not been measured on a device — vibration motors differ in
  /// how short a pulse they render at all.
  final int pulseMilliseconds;
}
