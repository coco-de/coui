import 'package:coui_core/coui_core.dart';

/// Turns the browser's frame stream into what the quality governor judges, and
/// decides when the page should be asked for frames at all.
///
/// DOM-free on purpose: the browser's part is the thin glue in
/// `quality_feed_web.dart` (listeners, the `requestAnimationFrame` loop, the
/// observers), and everything it decides — which interval is a sample, when to
/// stop sampling, what a hidden tab or a reduce-transparency preference does —
/// is here, where a test can run it with a clock it moves by hand.
///
/// ## What the Web measures
///
/// The interval between two `requestAnimationFrame` callbacks
/// (`CoreFrameMetric.interval`). A browser does not say what drawing a frame
/// cost — a backdrop filter is paid for on the compositor side, out of the
/// page's sight — but a compositor that cannot keep up delays the next frame,
/// and that the page can see. The display's refresh rate is not reported
/// either, so it is read off the first intervals
/// (`CoreFrameBudget.estimateRefreshRate`) unless the app states its target.
///
/// ## Why it samples only while something moves
///
/// A page that asks for a frame on every refresh never lets the browser idle:
/// it wakes at the display's rate for as long as the tab is open. So the loop
/// runs only while a sign says the page is in motion (a pointer, a scroll, a
/// key, a transition, a long frame) and for
/// `CoreQualityTuning.sampleGraceSeconds` after the last one. The first frame
/// after the loop starts again has no interval, so a stretch of idleness is
/// never mistaken for a long frame.
///
/// ## What stops it
///
/// * A hidden tab: the browser throttles frames to a crawl, which is not the
///   glass. Coming back starts the warm-up over, as an app returning from the
///   background does on Flutter.
/// * A reduce-transparency preference, for as long as it lasts: every surface
///   is already at the lowest tier. Ending it starts the warm-up over.
/// * A hold the app opened ([hold]).
final class WebQualitySampler {
  /// Creates the sampler for [stated] and starts it on the top of the page's
  /// life: visible, with no sign of motion yet.
  ///
  /// [onChange] hears each change of tier; the sampler has already applied it
  /// (its [tier] is the new one).
  WebQualitySampler({
    required this.stated,
    required this.onChange,
    this.drawable = const {
      CoreQualityEffect.refraction,
      CoreQualityEffect.backdropPass,
    },
    this.ladder = CoreQualityLadder.standard,
  }) {
    _tier = stated.startTier(drawable, ladder: ladder);
    _governor = stated.governor(
      drawable: drawable,
      metric: CoreFrameMetric.interval,
      budgetMicros: stated.budgetMicros(null),
      onChange: _handleChange,
      ladder: ladder,
    );
    // The display's rate is the page's to find out unless the app states the
    // rate it targets.
    _estimating = _governor != null && stated.targetFrameRate == null;
  }

  /// What the app stated.
  final CoreAdaptiveQuality stated;

  /// Called after the tier changed.
  final void Function(CoreQualityChange change) onChange;

  /// What the surfaces on this page can be asked to go without.
  final Set<CoreQualityEffect> drawable;

  /// The ladder the tiers come from.
  final CoreQualityLadder ladder;

  late CoreQualityTier _tier;
  CoreQualityGovernor? _governor;
  CoreQualityHold? _accessibilityHold;

  bool _estimating = false;
  final List<int> _estimate = [];

  bool _visible = true;
  bool _reduced = false;
  bool _gateOpen = false;
  double _activeUntilMs = 0;
  double? _lastFrameMs;

  /// The tier the surfaces are drawn at.
  CoreQualityTier get tier => _tier;

  /// The governor, or null when none runs — a tier is forced, or there is
  /// only one rung to be on.
  CoreQualityGovernor? get governor => _governor;

  /// Whether the page is reading its display's rate off its first intervals.
  bool get estimating => _estimating;

  /// Whether the page should be asked for frames now: there is something to
  /// decide, the tab is visible, nothing says less transparency, and the page
  /// has shown a sign of motion lately.
  bool get wantsFrames =>
      _governor != null && _visible && !_reduced && _gateOpen;

  /// A sign that the page is in motion at [nowMs] (the page's own clock, the
  /// one `requestAnimationFrame` timestamps are on): a pointer, a scroll, a
  /// key, a transition, a long frame.
  void onActivity(double nowMs) {
    final graceMs = stated.tuning.sampleGraceSeconds * 1000;
    final until = nowMs + graceMs;
    if (until > _activeUntilMs) _activeUntilMs = until;
    _gateOpen = true;
  }

  /// A frame at [timestampMs] — the callback's own timestamp.
  void onFrame(double timestampMs) {
    final governor = _governor;
    if (governor == null) return;
    final last = _lastFrameMs;
    _lastFrameMs = timestampMs;

    if (timestampMs > _activeUntilMs) {
      // Quiet for the whole grace: stop, and forget this frame so that the
      // next stretch's first frame is not measured from this one.
      _gateOpen = false;
      _lastFrameMs = null;

      return;
    }
    if (last == null) return;
    final interval =
        ((timestampMs - last) * Duration.microsecondsPerMillisecond).round();
    // Two callbacks in one frame are one frame.
    if (interval <= 0) return;

    if (_estimating) {
      _estimate.add(interval);
      if (_estimate.length >= CoreFrameBudget.estimateIntervals) {
        governor.setBudget(
          stated.budgetMicros(CoreFrameBudget.estimateRefreshRate(_estimate)),
        );
        _estimating = false;
        _estimate.clear();
      }

      return;
    }
    governor.add(
      interval,
      (timestampMs * Duration.microsecondsPerMillisecond).round(),
    );
  }

  /// The tab was hidden or shown at [nowMs].
  void onVisibilityChanged({required bool hidden, required double nowMs}) {
    if (hidden) {
      _visible = false;
      _gateOpen = false;
      _lastFrameMs = null;

      return;
    }
    if (_visible) return;
    _visible = true;
    _lastFrameMs = null;
    // The page comes back warm from nowhere: clocks down, timers throttled for
    // as long as it was away. What was measured before says nothing about it.
    _governor?.reset();
    onActivity(nowMs);
  }

  /// The reduce-transparency preference is [reduced] now.
  void onReducedTransparency({required bool reduced}) {
    if (reduced == _reduced) return;
    _reduced = reduced;
    final governor = _governor;
    if (governor == null) return;
    if (reduced) {
      _accessibilityHold ??= governor.hold();
      _gateOpen = false;
      _lastFrameMs = null;
    } else {
      _accessibilityHold?.release();
      _accessibilityHold = null;
      governor.reset();
    }
  }

  /// Stops frame measurement until the returned hold is released.
  CoreQualityHold hold() => _governor?.hold() ?? CoreQualityHold.none();

  void _handleChange(CoreQualityChange change) {
    _tier = change.to;
    onChange(change);
  }
}
