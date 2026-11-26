import 'package:coui_core/src/quality/frame_budget.dart';
import 'package:coui_core/src/quality/quality_tier.dart';
import 'package:coui_core/src/quality/quality_tuning.dart';
import 'package:meta/meta.dart';

/// Which part of a governor's life it is in.
enum CoreQualityPhase {
  /// Collecting the first frames to settle the starting tier — in one step,
  /// to any rung. A device that cannot hold the display's rate at all should
  /// not spend half a minute getting down to the tier it belongs on.
  warmup,

  /// Watching windows of frames and moving one rung at a time.
  runtime,
}

/// Why the tier changed.
enum CoreQualityReason {
  /// The warm-up settled the starting tier.
  warmup,

  /// Enough windows in a row were over the budget.
  overrun,

  /// Enough windows in a row had room to spare.
  headroom,
}

/// One decision of the governor, with the number it was made on — what an
/// app logs to see why the tier moved, and what a calibration run reads.
@immutable
class CoreQualityChange {
  /// Creates a change report.
  const CoreQualityChange({
    required this.from,
    required this.to,
    required this.reason,
    required this.metric,
    required this.percentileMillis,
    required this.framesMeasured,
    required this.budgetMillis,
  });

  /// The tier before.
  final CoreQualityTier from;

  /// The tier after.
  final CoreQualityTier to;

  /// What moved it.
  final CoreQualityReason reason;

  /// What was measured.
  final CoreFrameMetric metric;

  /// The percentile (the warm-up's or the window's) the decision was made
  /// on, in milliseconds.
  final double percentileMillis;

  /// How many frames that percentile was taken over.
  final int framesMeasured;

  /// The frame budget it was judged against, in milliseconds.
  final double budgetMillis;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreQualityChange &&
          from == other.from &&
          to == other.to &&
          reason == other.reason &&
          metric == other.metric &&
          percentileMillis == other.percentileMillis &&
          framesMeasured == other.framesMeasured &&
          budgetMillis == other.budgetMillis;

  @override
  int get hashCode => Object.hash(
    from,
    to,
    reason,
    metric,
    percentileMillis,
    framesMeasured,
    budgetMillis,
  );

  @override
  String toString() =>
      'CoreQualityChange(${from.name} → ${to.name}, ${reason.name}, '
      '${metric.name} p=${percentileMillis.toStringAsFixed(1)}ms of '
      '${budgetMillis.toStringAsFixed(1)}ms over $framesMeasured frames)';
}

/// An open request to stop measuring, from [CoreQualityGovernor.hold].
///
/// Heavy work of the app's own — a model loading, a large import — competes
/// with the glass for the device, and frames measured under it would read as
/// a device that cannot draw the glass. Holds nest; the governor measures
/// again once the last one is released and a few frames have passed.
final class CoreQualityHold {
  CoreQualityHold._(CoreQualityGovernor governor) : _governor = governor;

  /// A hold that holds nothing, for the app that asks for one where no
  /// governor is running: the code that wraps its heavy work in a hold does
  /// not have to know whether anything is measuring.
  CoreQualityHold.none() : _governor = null;

  CoreQualityGovernor? _governor;

  /// Whether this hold has been released.
  bool get released => _governor == null;

  /// Releases the hold. Releasing twice does nothing.
  void release() {
    final governor = _governor;
    if (governor == null) return;
    _governor = null;
    governor._release();
  }
}

/// Decides the quality tier from the frames a seat reports — a pure state
/// machine: samples and their timestamps go in, tier changes come out, and it
/// reads no clock, no binding and no display.
///
/// ```text
/// start ─ skip ─▶ warm-up ──(one decision, any rung)──▶ runtime
///                    ▲                                     │ one rung
///                    └─────────────── reset ───────────────┘ at a time
/// ```
///
/// **Skip.** The first frames after a start or a reset are dropped.
///
/// **Warm-up.** The warm-up percentile of the next frames, as a multiple of
/// the budget, picks the starting tier: below the metric's `warmupStart` the
/// top, and one rung further for each `warmupStride` beyond.
///
/// **Runtime.** Non-overlapping windows of frames. A window whose percentile
/// is over the metric's `over` is an over window; under `under`, a
/// comfortable one; between, neither — and a neither window clears the over
/// run but only *decays* the comfortable one, so a tail statistic that drifts
/// into the middle band every so often cannot hold recovery off forever.
/// Enough over windows in a row give up a rung; enough comfortable ones take
/// one back (when [allowStepUp]). A change waits for the cooldown since the
/// last one, measured on the frames' own timestamps.
///
/// **Backing off.** A rung taken back and given up again within the probation
/// is a failed step up, and each one doubles the wait for the next. Without
/// it, a scene that fits only without the bend would flicker between the two
/// looks for as long as it runs: the comfortable windows were measured at the
/// rung below, and nothing in them says whether the rung above fits.
///
/// Every count is derived from the budget and the tuning's seconds, so the
/// same tuning is the same *time* at any refresh rate.
final class CoreQualityGovernor {
  /// Creates a governor stepping along [rungs] (top first), judging [metric]
  /// samples against [budgetMicros].
  ///
  /// With [initial], the warm-up is skipped and the governor starts at the
  /// rung for it — the greatest rung that is not above it, so a tier this
  /// engine has no rung for starts at the one that looks the same. [onChange]
  /// is called for every change of tier.
  CoreQualityGovernor({
    required List<CoreQualityTier> rungs,
    required this.metric,
    required int budgetMicros,
    CoreQualityTier? initial,
    this.allowStepUp = true,
    this.tuning = const CoreQualityTuning(),
    this.ladder = CoreQualityLadder.standard,
    this.onChange,
  }) : assert(rungs.isNotEmpty, 'a governor needs at least one rung'),
       assert(budgetMicros > 0, 'a frame has a budget'),
       _rungs = List.unmodifiable(rungs),
       _budgetMicros = budgetMicros,
       thresholds = CoreQualityThresholds.of(metric) {
    _index = initial == null ? 0 : _rungFor(initial);
    _phase = initial == null
        ? CoreQualityPhase.warmup
        : CoreQualityPhase.runtime;
    _configure();
    _skipLeft = _skipFrames;
  }

  /// What the samples are.
  final CoreFrameMetric metric;

  /// Whether the governor may take a rung back. When false the tier only
  /// ever falls, for the life of the governor.
  final bool allowStepUp;

  /// The numbers it decides by.
  final CoreQualityTuning tuning;

  /// The ladder the rungs are taken from — consulted for nothing but the
  /// order, which the rungs already carry; kept so a diagnostic can name
  /// what each rung withholds.
  final CoreQualityLadder ladder;

  /// Called with every change of tier.
  final void Function(CoreQualityChange change)? onChange;

  /// The multiples of the budget [metric] is judged by.
  final CoreQualityThresholds thresholds;

  final List<CoreQualityTier> _rungs;
  int _budgetMicros;

  late int _index;
  late CoreQualityPhase _phase;

  // Derived from the budget and the tuning.
  late int _skipFrames;
  late int _warmupFrames;
  late int _windowFrames;
  late int _settleFrames;
  late int _cooldownMicros;
  late List<int> _samples;

  int _skipLeft = 0;
  int _count = 0;
  int _holds = 0;
  int _settleLeft = 0;
  int? _lastChangeAt;
  int _overStreak = 0;
  int _underStreak = 0;
  int _probation = 0;
  int _backoff = 0;

  /// The tier the surfaces are drawn at now.
  CoreQualityTier get tier => _rungs[_index];

  /// The tiers the governor steps between, top first.
  List<CoreQualityTier> get rungs => _rungs;

  /// Where in its life the governor is.
  CoreQualityPhase get phase => _phase;

  /// The frame budget the samples are judged against, in microseconds.
  int get budgetMicros => _budgetMicros;

  /// Whether a hold is open, or the frames after the last one are still being
  /// dropped.
  bool get measurementHeld => _holds > 0 || _settleLeft > 0;

  /// How many frames the skip, the warm-up and a window are, at this budget.
  ({int skip, int warmup, int window, int settle}) get frameCounts => (
    skip: _skipFrames,
    warmup: _warmupFrames,
    window: _windowFrames,
    settle: _settleFrames,
  );

  /// How many over windows in a row a step down still needs — exposed for a
  /// diagnostic overlay and for the tests that pin the streaks.
  int get overStreak => _overStreak;

  /// How many comfortable windows in a row a step up still has banked.
  int get underStreak => _underStreak;

  /// The number of comfortable windows a step up needs now, which a failed
  /// step up has doubled.
  int get recoverWindowsNeeded => tuning.recoverWindows << _backoff;

  /// Reports one frame: what it [costMicros] (by [metric]) and when it ended,
  /// [atMicros], on any clock that does not go backwards.
  void add(int costMicros, int atMicros) {
    if (_holds > 0) return;
    if (_settleLeft > 0) {
      _settleLeft--;

      return;
    }
    if (_skipLeft > 0) {
      _skipLeft--;

      return;
    }
    if (costMicros < 0) return;

    _samples[_count++] = costMicros;
    switch (_phase) {
      case CoreQualityPhase.warmup:
        if (_count >= _warmupFrames) _settleWarmup(atMicros);
      case CoreQualityPhase.runtime:
        if (_count >= _windowFrames) _judgeWindow(atMicros);
    }
  }

  /// Stops measuring until the returned hold (and every other open one) is
  /// released, then for [CoreQualityTuning.settleSeconds] more.
  CoreQualityHold hold() {
    _holds++;
    _count = 0;

    return CoreQualityHold._(this);
  }

  void _release() {
    if (_holds == 0) return;
    _holds--;
    if (_holds == 0) {
      _settleLeft = _settleFrames;
      _count = 0;
    }
  }

  /// Starts over from the warm-up, keeping the tier until it decides — for a
  /// device that has been asleep: its clocks, its temperature and its thermal
  /// headroom are not the ones the old frames were measured on.
  void reset() {
    _phase = CoreQualityPhase.warmup;
    _count = 0;
    _skipLeft = _skipFrames;
    _overStreak = 0;
    _underStreak = 0;
    _probation = 0;
    _backoff = 0;
    _lastChangeAt = null;
  }

  /// Judges later frames against another budget — the display changed its
  /// rate. The window being collected is dropped, since its frames and its
  /// length were counted for the old one.
  ///
  /// The skip and the settle that are still to run are carried over as the
  /// stretch of time they are: a page that learns its display is 120 Hz after
  /// the governor was made for 60 Hz has not spent the half second it still
  /// owes, and counting it in the old frames would let the warm-up start
  /// measuring while the clocks are still coming up.
  void setBudget(int budgetMicros) {
    assert(budgetMicros > 0, 'a frame has a budget');
    if (budgetMicros == _budgetMicros) return;
    final previous = _budgetMicros;
    _budgetMicros = budgetMicros;
    _configure();
    _skipLeft = _carried(_skipLeft, previous);
    _settleLeft = _carried(_settleLeft, previous);
    _count = 0;
  }

  /// [left] frames of [previous] microseconds, as frames of the budget now:
  /// the same time, and at least a frame while any of it is left.
  int _carried(int left, int previous) {
    if (left == 0) return 0;
    final frames = (left * previous / _budgetMicros).round();

    return frames < 1 ? 1 : frames;
  }

  void _configure() {
    int frames(double seconds) {
      final count = (seconds * Duration.microsecondsPerSecond / _budgetMicros)
          .round();

      return count < 1 ? 1 : count;
    }

    _skipFrames = frames(tuning.skipSeconds);
    _warmupFrames = frames(tuning.warmupSeconds);
    _windowFrames = frames(tuning.windowSeconds);
    _settleFrames = frames(tuning.settleSeconds);
    _cooldownMicros = (tuning.cooldownSeconds * Duration.microsecondsPerSecond)
        .round();
    final capacity = _warmupFrames > _windowFrames
        ? _warmupFrames
        : _windowFrames;
    _samples = List<int>.filled(capacity, 0);
  }

  int _rungFor(CoreQualityTier requested) {
    final wanted = ladder.indexOf(requested);
    var found = 0;
    for (var i = 0; i < _rungs.length; i++) {
      if (ladder.indexOf(_rungs[i]) <= wanted) found = i;
    }

    return found;
  }

  int _percentile(int percentile) =>
      CoreFrameStats.percentile(_samples.sublist(0, _count), percentile);

  void _settleWarmup(int at) {
    final measured = _percentile(tuning.warmupPercentile);
    final frames = _count;
    _count = 0;
    final ratio = measured / _budgetMicros;

    var target = 0;
    if (ratio >= thresholds.warmupStart) {
      target =
          1 +
          ((ratio - thresholds.warmupStart) / thresholds.warmupStride).floor();
      if (target > _rungs.length - 1) target = _rungs.length - 1;
    }
    // Without step up the tier only falls — and a warm-up that finds room
    // does not give back what an earlier start or an earlier decision took.
    if (!allowStepUp && target < _index) target = _index;

    _phase = CoreQualityPhase.runtime;
    _overStreak = 0;
    _underStreak = 0;
    _move(target, CoreQualityReason.warmup, measured, frames, at);
  }

  void _judgeWindow(int at) {
    final measured = _percentile(tuning.windowPercentile);
    final frames = _count;
    _count = 0;
    final ratio = measured / _budgetMicros;

    if (ratio > thresholds.over) {
      _overStreak++;
      _underStreak = 0;
    } else if (ratio < thresholds.under) {
      _underStreak++;
      _overStreak = 0;
    } else {
      _overStreak = 0;
      if (_underStreak > 0) _underStreak--;
    }

    final cooled =
        _lastChangeAt == null || at - _lastChangeAt! >= _cooldownMicros;
    if (_overStreak >= tuning.degradeWindows &&
        _index < _rungs.length - 1 &&
        cooled) {
      // A rung that was taken back and is lost again inside its probation was
      // not room after all.
      if (_probation > 0) {
        _backoff = _backoff + 1 > tuning.maxBackoffDoublings
            ? tuning.maxBackoffDoublings
            : _backoff + 1;
        _probation = 0;
      }
      _overStreak = 0;
      _underStreak = 0;
      _move(_index + 1, CoreQualityReason.overrun, measured, frames, at);

      return;
    }
    if (allowStepUp &&
        _index > 0 &&
        _underStreak >= recoverWindowsNeeded &&
        cooled) {
      _overStreak = 0;
      _underStreak = 0;
      _probation = tuning.probationWindows;
      _move(_index - 1, CoreQualityReason.headroom, measured, frames, at);

      return;
    }

    if (_probation > 0 && --_probation == 0) _backoff = 0;
  }

  void _move(
    int target,
    CoreQualityReason reason,
    int measuredMicros,
    int frames,
    int at,
  ) {
    if (target == _index) return;
    final from = _rungs[_index];
    _index = target;
    _lastChangeAt = at;
    onChange?.call(
      CoreQualityChange(
        from: from,
        to: _rungs[_index],
        reason: reason,
        metric: metric,
        percentileMillis: measuredMicros / Duration.microsecondsPerMillisecond,
        framesMeasured: frames,
        budgetMillis: _budgetMicros / Duration.microsecondsPerMillisecond,
      ),
    );
  }
}
