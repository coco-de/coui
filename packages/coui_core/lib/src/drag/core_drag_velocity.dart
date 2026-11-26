/// How fast a pointer is moving along one axis when it lets go — decided once
/// for the platforms that have to measure it themselves.
///
/// Flutter hands its gesture recognisers a finished velocity. The browser
/// hands out positions and times, so the Web seat measures: it feeds the
/// pointer's samples here and reads the speed back. Kept in Core so the
/// estimate is one definition with one unit table
/// (`test/fixtures/drag_release_vectors.json`) rather than a formula inlined
/// in a pointer handler, where a unit slip (a browser reports milliseconds, a
/// release rule reads seconds) is invisible until a flick behaves oddly.
library;

import 'package:meta/meta.dart';

// The two windows below measure a pointer; they time no motion and animate
// nothing, so there is no `CoreDuration` token for them. They are Flutter's
// own gesture-velocity figures (`VelocityTracker`: a 100 ms horizon, a 40 ms
// "the pointer stopped" gap), kept equal so a stroke is read alike on both
// platforms.
const Duration _kHorizon = Duration(milliseconds: 100);
const Duration _kStoppedGap = Duration(milliseconds: 40);

/// Estimates a pointer's release velocity from its recent samples.
///
/// Positions are in logical pixels along the one axis being tracked. Times
/// are [Duration]s from any origin shared by all samples — `Duration` rather
/// than a bare number because the unit is the thing that goes wrong: a
/// browser event stamps milliseconds, and the answer here is in pixels per
/// **second**.
///
/// The estimate is the slope of a least-squares line through the samples of
/// the last [horizon], so one jittery sample does not decide a flick. A
/// pointer that stopped is not flinging however fast it was moving a moment
/// ago, so a silence of more than [stoppedGap] between two samples ends the
/// window: only the samples after the silence count.
///
/// A pointer that stops reports nothing until it lifts, so the newest sample
/// can be old by the time the question is asked. [velocityAt] takes the time
/// of the question — for a release, the lift — and answers zero when more
/// than [stoppedGap] has passed since the newest sample: a flick followed by
/// a hold is not a flick. Flutter's own velocity tracker answers the same
/// way when its recogniser asks (it reads the wall clock where this reads
/// the events' own), so a stroke is judged alike on both platforms. The lift
/// itself is not a sample — like Flutter's, the tracker is fed the press and
/// the moves.
class CoreDragVelocityTracker {
  /// Creates a tracker.
  ///
  /// [horizon] and [stoppedGap] default to the figures Flutter's own gesture
  /// velocity tracker uses, so a flick measured here and one measured by the
  /// framework agree about when a pointer has stopped.
  CoreDragVelocityTracker({
    this.horizon = defaultHorizon,
    this.stoppedGap = defaultStoppedGap,
  }) : assert(horizon > Duration.zero, 'The horizon must be positive.'),
       assert(stoppedGap > Duration.zero, 'The stopped gap must be positive.');

  /// How far back from the newest sample the estimate reaches.
  static const Duration defaultHorizon = _kHorizon;

  /// The longest silence between two samples that still counts as one motion.
  static const Duration defaultStoppedGap = _kStoppedGap;

  /// How far back from the newest sample the estimate reaches.
  final Duration horizon;

  /// The longest silence between two samples that still counts as one motion.
  final Duration stoppedGap;

  final List<_Sample> _samples = [];

  /// Records that the pointer was at [position] (logical px along the axis)
  /// at [time].
  ///
  /// Samples must arrive in time order. One that is earlier than the newest
  /// is dropped rather than reordered: a browser delivers events in order,
  /// and a late one is a clock fault the estimate should not be bent by.
  void addSample(Duration time, double position) {
    if (_samples.isNotEmpty && time < _samples.last.time) return;

    _samples.add(_Sample(time, position));
    // Nothing older than the horizon is ever read again, so it is not kept.
    final cutoff = time - horizon;
    while (_samples.length > 2 && _samples.first.time < cutoff) {
      _samples.removeAt(0);
    }
  }

  /// Forgets every sample, ready for the next gesture.
  void reset() => _samples.clear();

  /// How many samples are held — for tests and diagnostics.
  @visibleForTesting
  int get sampleCount => _samples.length;

  /// The pointer's velocity along the axis as of [time] — the moment the
  /// caller asks, which for a release is the moment the pointer lifted — in
  /// logical **pixels per second**; positive means the position was growing.
  ///
  /// Zero when more than [stoppedGap] has passed since the newest sample (the
  /// pointer stopped and said nothing), and otherwise [velocity].
  double velocityAt(Duration time) {
    if (_samples.isEmpty) return 0;
    if (time - _samples.last.time > stoppedGap) return 0;

    return velocity;
  }

  /// The pointer's velocity along the axis at the newest sample, in logical
  /// **pixels per second**; positive means the position was growing.
  ///
  /// Zero when fewer than two samples are inside the window, or when the
  /// pointer had stopped before the newest sample. It cannot see a stop after
  /// the newest sample — that is [velocityAt]'s question.
  double get velocity {
    if (_samples.length < 2) return 0;

    final newest = _samples.last;
    var oldest = _samples.length - 1;
    for (var i = _samples.length - 1; i > 0; i--) {
      final previous = _samples[i - 1];
      final withinHorizon = newest.time - previous.time <= horizon;
      final continuous = _samples[i].time - previous.time <= stoppedGap;
      if (!withinHorizon || !continuous) break;
      oldest = i - 1;
    }
    final count = _samples.length - oldest;
    if (count < 2) return 0;

    // Least-squares slope of position over time. Time is measured in
    // **seconds back from the newest sample** (microseconds / 1e6), so the
    // slope comes out in px/s with no later conversion, and the sums stay
    // small enough that a long-lived page clock does not cost precision.
    var sumT = 0.0;
    var sumP = 0.0;
    var sumTT = 0.0;
    var sumTP = 0.0;
    for (var i = oldest; i < _samples.length; i++) {
      final t =
          (_samples[i].time - newest.time).inMicroseconds /
          Duration.microsecondsPerSecond;
      final p = _samples[i].position;
      sumT += t;
      sumP += p;
      sumTT += t * t;
      sumTP += t * p;
    }
    final denominator = count * sumTT - sumT * sumT;
    // Every sample at one instant has no direction in time.
    if (denominator == 0) return 0;

    return (count * sumTP - sumT * sumP) / denominator;
  }
}

class _Sample {
  const _Sample(this.time, this.position);

  final Duration time;
  final double position;
}
