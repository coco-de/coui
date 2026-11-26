/// EPIC-004 (#3597) child #3611 — `tester.pump(Δt)` frame sampling for
/// Flutter animations.
///
/// `.bmad/architecture-*.md` Component ⑧ (`FlutterMotionProbe`) needs to
/// answer three questions about a running animation without a browser:
/// does a value actually change over time (not jump straight to its final
/// state), does it change **monotonically** toward that final state, and
/// does the total duration land in the `CoreDuration` transition tier the
/// design system expects. This file provides exactly those three pieces —
/// sampling and the two assertions — as reusable, `WidgetTester`-only
/// primitives. `*_motion_probe_test.dart` proves them against the two
/// production interactions the child issue names (Dialog enter/exit,
/// `CoUIAnimatedTheme` preset/theme transition); #3614's
/// `ReducedMotionProbe` reuses these same primitives for its
/// suppressed-vs-preserved tier check rather than duplicating the sampling
/// loop.
library;

import 'package:coui_core/coui_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// One sampled point in a running animation's time series.
///
/// [tMs] is milliseconds elapsed since the caller's trigger action (tap,
/// `pumpWidget` rebuild, …) — not wall-clock time, and not necessarily frame
/// index, since [sampleAnimationValues] steps by fixed fractions of the
/// animation's own duration.
class MotionSample {
  const MotionSample({required this.tMs, required this.value});

  final int tMs;
  final double value;

  @override
  String toString() => '${tMs}ms=$value';
}

/// Default [sampleAnimationValues] `steps` — four evenly-spaced interior
/// points is enough to distinguish "animated smoothly" from "jumped once"
/// without over-sampling every call site.
const int kDefaultMotionProbeSteps = 4;

/// Samples a scalar animated value at `steps + 1` evenly-spaced points
/// across [totalDuration] (t=0 plus one sample per step boundary).
///
/// The caller is responsible for having already performed whatever pump
/// makes the animated widget observable at t≈0 (a `tester.tap` that starts
/// a route transition needs one bare `tester.pump()` first so the new
/// route's transition widgets exist in the tree; a `tester.pumpWidget`
/// rebuild that itself starts an implicit animation does not). This
/// function takes its first reading with [read] synchronously — no pump —
/// so it never advances time it wasn't told to.
///
/// Uses running elapsed-time accounting (`targetMs - elapsedMs` per step,
/// not a fixed `totalMs ~/ steps` added `steps` times) so integer-division
/// remainders land in the last step instead of silently shortening the
/// sampled window versus [totalDuration].
Future<List<MotionSample>> sampleAnimationValues(
  WidgetTester tester, {
  required double Function() read,
  required Duration totalDuration,
  int steps = kDefaultMotionProbeSteps,
}) async {
  assert(steps >= 2, 'Need at least one interior sample — pass steps >= 2.');
  final totalMs = totalDuration.inMilliseconds;
  final samples = [MotionSample(tMs: 0, value: read())];
  var elapsedMs = 0;
  for (var i = 1; i <= steps; i++) {
    final targetMs = (totalMs * i) ~/ steps;
    final stepMs = targetMs - elapsedMs;
    if (stepMs > 0) {
      await tester.pump(Duration(milliseconds: stepMs));
    }
    elapsedMs = targetMs;
    samples.add(MotionSample(tMs: elapsedMs, value: read()));
  }
  return samples;
}

/// Numerical tolerance for the floating-point comparisons below — animated
/// values pass through curves and lerp math, so exact equality is not the
/// right bar for "did this change".
const double _kMotionProbeTolerance = 1e-6;

/// Asserts [samples] moved **monotonically** from the first sample toward
/// the last — non-decreasing throughout if the value rose, non-increasing
/// throughout if it fell.
///
/// This does not require every consecutive pair to differ (a coarse
/// [sampleAnimationValues] `steps` can straddle a frame where the curve
/// moved very little) — it requires that the direction never reverses.
/// Reversal is the signature of an overshooting curve (elastic/bounce) or a
/// broken interpolation, neither of which the animations this probe targets
/// (Dialog's `decelerate`/`accelerate`, `CoUIAnimatedTheme`'s linear
/// crossfade) should ever produce.
void expectMonotonicProgression(List<MotionSample> samples, {String? reason}) {
  assert(
    samples.length >= 2,
    'Need at least two samples to check progression.',
  );
  final label = reason ?? 'Animation';
  final start = samples.first.value;
  final end = samples.last.value;
  if ((end - start).abs() < _kMotionProbeTolerance) {
    fail(
      '$label: start and end sample are equal ($start) — nothing to check '
      'monotonicity against. Sample a longer window or a property that '
      'actually changes for this trigger. Samples: $samples',
    );
  }
  final increasing = end > start;
  var previous = start;
  for (final sample in samples.skip(1)) {
    final v = sample.value;
    final regressed = increasing
        ? v < previous - _kMotionProbeTolerance
        : v > previous + _kMotionProbeTolerance;
    if (regressed) {
      fail(
        '$label regressed at t=${sample.tMs}ms: $v ${increasing ? '<' : '>'} '
        'previous $previous (expected ${increasing ? 'non-decreasing' : 'non-increasing'} '
        'toward $end). Samples: $samples',
      );
    }
    previous = v;
  }
}

/// Asserts the animation did **not** settle to its final value on the very
/// first sampled frame after the trigger — the signature of "the framework
/// applied the end state immediately instead of animating toward it" (e.g.
/// a duration that resolved to zero when it should not have, or a widget
/// that never wired the animation in the first place).
///
/// Requires at least one *interior* sample (excluding the first and last)
/// that differs from **both** the start and end values — that is the direct
/// evidence that the tree was mid-transition at that point in time, as
/// opposed to a step function that flips once somewhere in the sampled
/// window.
void expectNoImmediateFinalValueJump(
  List<MotionSample> samples, {
  String? reason,
}) {
  assert(
    samples.length > 2,
    'Need at least one interior sample besides start/end — pass steps >= 2.',
  );
  final label = reason ?? 'Animation';
  final start = samples.first.value;
  final end = samples.last.value;
  final interior = samples.sublist(1, samples.length - 1);
  final sawInBetweenFrame = interior.any(
    (s) =>
        (s.value - start).abs() > _kMotionProbeTolerance &&
        (s.value - end).abs() > _kMotionProbeTolerance,
  );
  if (!sawInBetweenFrame) {
    fail(
      '$label jumped straight from $start to $end with no intermediate '
      'frame in between — looks like it settled instantly instead of '
      'animating. Samples: $samples',
    );
  }
}

/// Asserts [duration] is exactly one of the `CoreDuration` transition-tier
/// primitives (`ms0`–`ms500`) — i.e. that a component's resolved animation
/// timing traces back to a design token rather than an arbitrary literal.
///
/// Scoped to the transition tier deliberately: this probe samples motion
/// that moves something from one state to another (dialog open/close,
/// theme crossfade), which is exactly the tier `CoreReducedMotion` also
/// scopes its suppression to (`core/design-tokens.md`) — display-tier
/// values (spinners, toast dwell time) are a different vocabulary and a
/// different probe's concern.
void expectDurationWithinTransitionTierTokens(
  Duration duration, {
  String? reason,
}) {
  const knownTransitionTierMs = {
    CoreDuration.ms0,
    CoreDuration.ms50,
    CoreDuration.ms100,
    CoreDuration.ms150,
    CoreDuration.ms200,
    CoreDuration.ms250,
    CoreDuration.ms300,
    CoreDuration.ms350,
    CoreDuration.ms400,
    CoreDuration.ms450,
    CoreDuration.ms500,
  };
  final ms = duration.inMilliseconds;
  if (!knownTransitionTierMs.contains(ms)) {
    fail(
      '${reason ?? 'Duration'}: ${ms}ms is not one of the CoreDuration '
      'transition-tier primitives ($knownTransitionTierMs) — looks like a '
      'raw literal rather than a token reference.',
    );
  }
}
