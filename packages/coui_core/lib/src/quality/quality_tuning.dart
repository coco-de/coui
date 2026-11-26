import 'package:meta/meta.dart';

/// What one frame is measured as — the two platforms can observe different
/// things, and the thresholds below differ with it.
///
/// ## Why Flutter measures cost and the Web measures the interval
///
/// What the tiers change is the work of drawing: Flutter's refraction program
/// and backdrop pass run on the raster thread, so **raster time** is the one
/// stage a tier can lower. Build time is the app's own work (a tier change
/// even adds one rebuild to it), and the sum of the two is the latency of a
/// frame, not the rate the display is fed at — the two threads overlap — so
/// neither is the signal. The browser publishes no such split: the main thread
/// is told when a frame starts, nothing is told what drawing it cost, and a
/// backdrop filter is paid for on the compositor side. What a page can see is
/// **when its frames arrive**, and a compositor that cannot keep up delays the
/// next one, so the interval between frames is the Web's signal.
///
/// The two are not the same kind of number, which is why they cannot share
/// thresholds. A cost is under the budget when the frame was cheap, so it
/// shows headroom as well as overrun; an interval is exactly one budget when
/// the page is healthy and a whole number of them when it is not, so it shows
/// overrun only.
enum CoreFrameMetric {
  /// How long the frame took to draw — raster time. Flutter's.
  cost,

  /// The time from one frame to the next. The Web's.
  interval,
}

/// The multiples of the frame budget at which a metric means "over" and
/// "comfortable".
@immutable
class CoreQualityThresholds {
  /// Creates the thresholds of one metric.
  const CoreQualityThresholds({
    required this.warmupStart,
    required this.warmupStride,
    required this.over,
    required this.under,
  });

  /// The thresholds for [CoreFrameMetric.cost].
  ///
  /// **Designer-judgement values (디자이너 판단 값):** a frame whose drawing
  /// takes longer than the budget misses the display by definition, so the
  /// warm-up starts stepping down at one budget (of the 75th percentile) and
  /// takes one more rung for every further half budget, and the runtime calls
  /// a window over when its 95th percentile passes one budget. Headroom is
  /// half a budget: a rung up draws more, and a window does not say how much.
  /// On the scenes `tool/frame_timing` draws (an Apple M3 Max, profile mode),
  /// the step from `full` to `noRefraction` takes up to a tenth off a glass
  /// scene's raster time (a fifth for five cards laid over one another) and
  /// the step from `noRefraction` to `solid` another tenth to a third, so a
  /// window that is merely under budget does not show that the rung above
  /// fits.
  static const CoreQualityThresholds cost = CoreQualityThresholds(
    warmupStart: 1,
    warmupStride: 0.5,
    over: 1,
    under: 0.5,
  );

  /// The thresholds for [CoreFrameMetric.interval].
  ///
  /// **Designer-judgement values (디자이너 판단 값):** an interval is one
  /// budget when the frame was on time and two when one was dropped, so the
  /// line between them is one and a half; the warm-up takes a rung for every
  /// further dropped frame. "Comfortable" is a hair over one budget, the
  /// jitter an on-time page still shows.
  static const CoreQualityThresholds interval = CoreQualityThresholds(
    warmupStart: 1.5,
    warmupStride: 1,
    over: 1.5,
    under: 1.15,
  );

  /// The thresholds for [metric].
  static CoreQualityThresholds of(CoreFrameMetric metric) => switch (metric) {
    CoreFrameMetric.cost => cost,
    CoreFrameMetric.interval => interval,
  };

  /// The warm-up's 75th percentile, as a multiple of the budget, at which the
  /// first rung is given up.
  final double warmupStart;

  /// How much further the warm-up's percentile has to be, in budgets, for each
  /// rung beyond the first.
  final double warmupStride;

  /// A window whose percentile is above this many budgets is over.
  final double over;

  /// A window whose percentile is below this many budgets is comfortable.
  final double under;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreQualityThresholds &&
          warmupStart == other.warmupStart &&
          warmupStride == other.warmupStride &&
          over == other.over &&
          under == other.under;

  @override
  int get hashCode => Object.hash(warmupStart, warmupStride, over, under);
}

/// Every number the quality governor decides by.
///
/// **Provisional, all of it.** None of these is derived: they are the
/// designer-judgement starting points, the things a measurement on the target
/// hardware (`tool/frame_timing`) is there to settle. Each default is a
/// `static const` here and nowhere else, and the governor reads the instance,
/// so an app, a test and a calibration run state their own without touching a
/// seat.
///
/// The durations are **seconds of nominal display time**, not frames or
/// milliseconds: the governor turns them into frame counts with the budget,
/// so a window is two seconds of a 60 Hz display and also two seconds of a
/// 120 Hz one. They count frames rather than the wall clock because a frame
/// that did not happen cannot be measured — an idle screen produces none and
/// must not read as a stretch of comfortable ones.
@immutable
class CoreQualityTuning {
  /// Creates a tuning; every omitted number is its `default*`.
  const CoreQualityTuning({
    this.skipSeconds = defaultSkipSeconds,
    this.warmupSeconds = defaultWarmupSeconds,
    this.windowSeconds = defaultWindowSeconds,
    this.cooldownSeconds = defaultCooldownSeconds,
    this.settleSeconds = defaultSettleSeconds,
    this.sampleGraceSeconds = defaultSampleGraceSeconds,
    this.warmupPercentile = defaultWarmupPercentile,
    this.windowPercentile = defaultWindowPercentile,
    this.degradeWindows = defaultDegradeWindows,
    this.recoverWindows = defaultRecoverWindows,
    this.probationWindows = defaultProbationWindows,
    this.maxBackoffDoublings = defaultMaxBackoffDoublings,
  });

  /// Frames dropped at the start and after a reset, so that the first route,
  /// the first shader compile and a GPU still clocking up do not read as the
  /// device. Upstream's package drops the first 90 frames of a 60 Hz display;
  /// this is the same time.
  static const double defaultSkipSeconds = 1.5;

  /// Frames collected after the skip to settle the starting tier.
  static const double defaultWarmupSeconds = 3;

  /// The length of one evaluation window at runtime.
  static const double defaultWindowSeconds = 2;

  /// The least time between two changes of tier, measured on the frames'
  /// own timestamps.
  static const double defaultCooldownSeconds = 8;

  /// How long after the last hold is released measurement stays off: the
  /// engine hands over its timings in batches, and the work that was held
  /// has a tail.
  static const double defaultSettleSeconds = 1;

  /// How long after the last sign that something is moving the Web keeps
  /// sampling frames before it stops and lets the page idle.
  ///
  /// The browser has no stream of frame timings; the page asks for one frame
  /// at a time, and a page that asks for every frame forever never lets the
  /// browser sleep. So the Web samples only while a pointer, a scroll, a key,
  /// a transition or a long frame says the page is in motion, and for this
  /// long after. Flutter's engine hands over the timings of the frames it
  /// draws and draws none when nothing changes, so it does not read this.
  ///
  /// **Designer-judgement value (디자이너 판단 값):** long enough to see a
  /// momentum scroll or a two-hundred-millisecond transition to its end, short
  /// enough that an idle page is idle.
  static const double defaultSampleGraceSeconds = 2;

  /// The warm-up decides by this percentile of its frames.
  static const int defaultWarmupPercentile = 75;

  /// A runtime window is judged by this percentile of its frames.
  static const int defaultWindowPercentile = 95;

  /// Consecutive over windows that give up one rung. Degrading is fast on
  /// purpose: a dropped frame is noticed at once, and the look that costs it
  /// is a rung away.
  static const int defaultDegradeWindows = 2;

  /// Consecutive comfortable windows that take one rung back. Five times the
  /// degrade count: recovering is slow on purpose, because a change of look
  /// the user did not ask for is worse than a rung they did not need.
  static const int defaultRecoverWindows = 10;

  /// How many windows a rung just taken back has to survive without being
  /// given up again before the step up is called a success.
  static const int defaultProbationWindows = 5;

  /// How many times a failed step up doubles the wait for the next one.
  static const int defaultMaxBackoffDoublings = 3;

  /// See [defaultSkipSeconds].
  final double skipSeconds;

  /// See [defaultWarmupSeconds].
  final double warmupSeconds;

  /// See [defaultWindowSeconds].
  final double windowSeconds;

  /// See [defaultCooldownSeconds].
  final double cooldownSeconds;

  /// See [defaultSettleSeconds].
  final double settleSeconds;

  /// See [defaultSampleGraceSeconds].
  final double sampleGraceSeconds;

  /// See [defaultWarmupPercentile].
  final int warmupPercentile;

  /// See [defaultWindowPercentile].
  final int windowPercentile;

  /// See [defaultDegradeWindows].
  final int degradeWindows;

  /// See [defaultRecoverWindows].
  final int recoverWindows;

  /// See [defaultProbationWindows].
  final int probationWindows;

  /// See [defaultMaxBackoffDoublings].
  final int maxBackoffDoublings;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreQualityTuning &&
          skipSeconds == other.skipSeconds &&
          warmupSeconds == other.warmupSeconds &&
          windowSeconds == other.windowSeconds &&
          cooldownSeconds == other.cooldownSeconds &&
          settleSeconds == other.settleSeconds &&
          sampleGraceSeconds == other.sampleGraceSeconds &&
          warmupPercentile == other.warmupPercentile &&
          windowPercentile == other.windowPercentile &&
          degradeWindows == other.degradeWindows &&
          recoverWindows == other.recoverWindows &&
          probationWindows == other.probationWindows &&
          maxBackoffDoublings == other.maxBackoffDoublings;

  @override
  int get hashCode => Object.hash(
    skipSeconds,
    warmupSeconds,
    windowSeconds,
    cooldownSeconds,
    settleSeconds,
    sampleGraceSeconds,
    warmupPercentile,
    windowPercentile,
    degradeWindows,
    recoverWindows,
    probationWindows,
    maxBackoffDoublings,
  );
}
