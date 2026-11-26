import 'package:coui_core/src/motion/duration_token.dart';

/// What "reduce motion" means for a duration, defined once for both
/// platforms.
///
/// Users with vestibular disorders or migraine can ask the OS to reduce
/// motion; WCAG 2.2 `2.3.3 Animation from Interactions` expects an interface
/// to honour that. The decision this class encodes is not *whether* to honour
/// it but **which motion the request is about**, because suppressing all of it
/// is its own accessibility failure: a spinner that stops spinning no longer
/// says "still working", and a progress bar that freezes reads as a hang.
///
/// The line is the tier boundary that already exists in [CoreDuration]:
///
/// * **Transition tier** (`0`–[CoreDuration.ms500], where the semantic aliases
///   live) is motion that moves a thing from one place or state to another.
///   It is decoration on a change the user already knows about, so removing it
///   costs nothing but the polish. Suppressed.
/// * **Display tier** ([CoreDuration.ms1000] and above, plus
///   [CoreDuration.indeterminate]) answers "how long does this stay / cycle",
///   not "how fast does it move". Suppressing it would delete information
///   rather than decoration. Preserved.
///
/// Because the policy reads the duration's own tier, callers do not classify
/// anything: a resolver can route every duration through [resolve] and the
/// spinner keeps spinning while the slide-in stops. That is deliberate — a
/// per-component judgement is a per-component chance to get it wrong.
///
/// The loading placeholder's pulse is a display-tier loop that does stop, and
/// that is stated here rather than in the component for the same reason
/// ([runsPlaceholderPulse]).
abstract final class CoreReducedMotion {
  const CoreReducedMotion._();

  /// Upper bound of the transition tier, in milliseconds.
  ///
  /// Durations at or below this are suppressed under reduced motion; longer
  /// ones are treated as display timing and left alone.
  static const int transitionCeilingMs = CoreDuration.ms500;

  /// [duration] as it should be used when [reduce] is set.
  ///
  /// Returns [Duration.zero] for transition-tier motion and leaves everything
  /// else untouched. Already-zero durations pass through unchanged so the
  /// result never depends on whether a caller had opted out already.
  static Duration resolve(Duration duration, {required bool reduce}) {
    if (!reduce) return duration;
    final milliseconds = duration.inMilliseconds;
    if (milliseconds <= 0) return duration;
    if (milliseconds > transitionCeilingMs) return duration;
    return .zero;
  }

  /// Whether a loading placeholder pulses when [reduce] is set — it does not.
  ///
  /// The pulse is display timing like a spinner, but the reason a spinner
  /// keeps turning does not carry over to it. A stopped spinner reads as
  /// hung; a stopped placeholder still reads as a placeholder — its shape says
  /// "content goes here" without moving. And a placeholder can sit on a page
  /// the user is otherwise using, where WCAG 2.2 `2.2.2 Pause, Stop, Hide`
  /// asks that motion running past five seconds can be stopped: the OS
  /// setting is that stop, honoured for the users most sensitive to motion.
  ///
  /// Stopped, the placeholder holds its resting end (`fromOpacity`), the fill
  /// it would start from. Its period is untouched — the pulse is held, not
  /// collapsed to a zero-length cycle.
  static bool runsPlaceholderPulse({required bool reduce}) => !reduce;

  /// Whether [duration] is transition motion — i.e. whether [resolve] would
  /// suppress it under reduced motion.
  ///
  /// Exposed so tests and docs can state the boundary without restating the
  /// comparison.
  static bool isTransitionMotion(Duration duration) {
    final milliseconds = duration.inMilliseconds;
    return milliseconds > 0 && milliseconds <= transitionCeilingMs;
  }
}
