import 'failure_category.dart';

/// Maps one motion-probe test failure's error text to
/// [FailureCategory.motionMissing] or [FailureCategory.motionTiming].
///
/// The patterns matched here are the exact `fail(...)` message vocabulary
/// `motion_probe.dart` (#3611) and `transition_contract_probe.dart` (#3612)
/// use — not a guess:
///
///  - `expectDurationWithinTransitionTierTokens`: "... is not one of the
///    CoreDuration transition-tier primitives ..." → timing
///  - `expectTransitionDurationMatchesToken`: "transition duration for ...
///    is Xms, expected Yms ..." → timing
///  - `expectNoImmediateFinalValueJump`: "... jumped straight from ... —
///    looks like it settled instantly instead of animating." → missing
///  - `expectMonotonicProgression`: "start and end sample are equal ...",
///    "... regressed at t=...ms ..." → missing
///  - `expectTransitionDeclaredForProperty`: "no transition declared for
///    ..." → missing
///
/// A message that matches none of the above still needs a verdict —
/// Reporter's completion definition names exactly six categories, no
/// seventh "unclassified motion" bucket — so it defaults to
/// [FailureCategory.motionMissing]: "we could not confirm the animation
/// exists" is the safer of the two readings when the cause is unclear,
/// because reporting a *timing* mismatch implies the animation's presence
/// was already confirmed.
FailureCategory classifyMotionFailure(String errorMessage) {
  final message = errorMessage.toLowerCase();

  final looksLikeTimingMismatch =
      message.contains(
        'is not one of the coreduration transition-tier primitives',
      ) ||
      (message.contains('transition duration for') &&
          message.contains('expected'));

  return looksLikeTimingMismatch
      ? FailureCategory.motionTiming
      : FailureCategory.motionMissing;
}
