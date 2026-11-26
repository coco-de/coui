import 'dart:ui' show FramePhase, FrameTiming;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/scheduler.dart';

/// The quality tier the surfaces under it are drawn at, and the way to ask the
/// governor behind it to stop measuring.
///
/// Named and shaped like the Web scope so an app reads the same call on both
/// platforms. Only the transport differs: here a new tier rebuilds the subtree
/// with a theme whose material has already gone without what the tier gives
/// up, while on the Web the document gains an attribute the stylesheet keys
/// off.
///
/// Components do not read this. The tier reaches them the way the surface
/// style does — already folded into the theme where the recipe becomes a
/// material (`applySurfaceStyle`) — so none of them can be the one that
/// forgets. The scope exists so an app can show what is active and can hold
/// the governor off around heavy work of its own.
class AdaptiveQualityScope extends InheritedWidget {
  /// Creates a scope publishing [tier] to [child]. Mounted by [CoUILayer].
  const AdaptiveQualityScope({
    required this.tier,
    required this.opensHold,
    required super.child,
    super.key,
  });

  /// The tier the surfaces are drawn at, with a reduce-transparency
  /// preference already taken into it.
  final CoreQualityTier tier;

  /// Opens a hold on the governor behind the scope, or null when none is
  /// running.
  final CoreQualityHold Function()? opensHold;

  /// The tier at [context], or the default when no scope is above it.
  static CoreQualityTier of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AdaptiveQualityScope>()
          ?.tier ??
      CoreQualityTier.defaultTier;

  /// Stops frame measurement until the returned hold is released.
  ///
  /// Wrap heavy work of the app's own — a model loading, a large import —
  /// that competes with the glass for the device, so the slowdown is not
  /// mistaken for a device that cannot draw it:
  ///
  /// ```dart
  /// final hold = AdaptiveQualityScope.holdMeasurement(context);
  /// try {
  ///   await heavyWork();
  /// } finally {
  ///   hold.release();
  /// }
  /// ```
  ///
  /// Returns a hold that holds nothing where no governor is running — the
  /// app did not opt in, or fixed a tier — so the call needs no guard.
  static CoreQualityHold holdMeasurement(BuildContext context) =>
      context
          .getInheritedWidgetOfExactType<AdaptiveQualityScope>()
          ?.opensHold
          ?.call() ??
      CoreQualityHold.none();

  @override
  bool updateShouldNotify(AdaptiveQualityScope oldWidget) =>
      tier != oldWidget.tier;
}

/// Owns the quality governor of an app: feeds it the engine's frame timings,
/// publishes the tier it settles on and tells the app when that changes.
///
/// Mounted by [CoUILayer] and not by the app. With no
/// `CoUIApp.adaptiveQuality` it is a pass-through that measures nothing and
/// publishes the top tier, so an app that says nothing renders every surface
/// at the full tier its style states, exactly as before.
///
/// ## What it measures, and why raster time
///
/// The engine hands over each frame's timings in batches
/// (`SchedulerBinding.addTimingsCallback`). The governor is fed the **raster**
/// duration: the refraction program and the backdrop pass run on the raster
/// thread, so it is the one stage a tier can lower. Build time is the app's
/// own work — a tier change even adds one rebuild to it — and the sum of the
/// two is a frame's latency, not the rate the display is fed at, since the
/// threads overlap. See `CoreFrameMetric` for the Web's counterpart.
///
/// ## What stops it
///
/// * A reduce-transparency preference holds the governor for as long as it is
///   on — every surface is already at the lowest tier, so frames measured then
///   say nothing about the glass — and starts the warm-up over when it ends.
/// * The app returning from the background starts the warm-up over: the device
///   has cooled, the clocks are down, and the first frames after a resume
///   are slow for reasons that are not the glass.
/// * A hold the app opened ([AdaptiveQualityScope.holdMeasurement]).
class AdaptiveQualityHost extends StatefulWidget {
  /// Creates the host for [adaptiveQuality] around [child].
  const AdaptiveQualityHost({
    required this.adaptiveQuality,
    required this.reduceTransparency,
    required this.child,
    super.key,
  });

  /// What the app states, or null for none.
  final CoreAdaptiveQuality? adaptiveQuality;

  /// Whether the app took a reduce-transparency preference into the theme.
  final bool reduceTransparency;

  /// The subtree the tier is published to.
  final Widget child;

  @override
  State<AdaptiveQualityHost> createState() => AdaptiveQualityHostState();
}

/// The state of an [AdaptiveQualityHost].
///
/// Public so a test can reach the governor the host is running; nothing else
/// has a reason to.
class AdaptiveQualityHostState extends State<AdaptiveQualityHost>
    with WidgetsBindingObserver {
  CoreQualityTier _tier = CoreQualityTier.defaultTier;
  CoreQualityGovernor? _governor;
  CoreQualityHold? _accessibilityHold;
  bool _timing = false;
  bool _pausedSinceResume = false;

  /// The governor this host runs, or null when none is.
  @visibleForTesting
  CoreQualityGovernor? get governor => _governor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _configure();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _followDisplay();
  }

  @override
  void didChangeMetrics() => _followDisplay();

  @override
  void didUpdateWidget(AdaptiveQualityHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameTerms(widget.adaptiveQuality, oldWidget.adaptiveQuality)) {
      _configure();
      _followDisplay();
    }
    _followAccessibility();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTiming();
    _accessibilityHold?.release();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Back from the background: what was measured before says nothing about
      // a device that has cooled and clocked down. The tier is kept until the
      // new warm-up decides.
      if (_pausedSinceResume) _governor?.reset();
      _pausedSinceResume = false;
    } else {
      _pausedSinceResume = true;
    }
  }

  /// Opens a hold on the governor.
  CoreQualityHold hold() => _governor?.hold() ?? CoreQualityHold.none();

  /// What the surfaces can be asked to go without on this engine.
  Set<CoreQualityEffect> get _drawable => {
    CoreQualityEffect.backdropPass,
    if (SurfaceRefractionProgram.supported) CoreQualityEffect.refraction,
  };

  void _configure() {
    _stopTiming();
    _accessibilityHold = null;
    _governor = null;
    final stated = widget.adaptiveQuality;
    if (stated == null) {
      _tier = CoreQualityTier.defaultTier;

      return;
    }
    final drawable = _drawable;
    _tier = stated.startTier(drawable);
    _governor = stated.governor(
      drawable: drawable,
      metric: CoreFrameMetric.cost,
      budgetMicros: stated.budgetMicros(null),
      onChange: _handleChange,
    );
    if (_governor != null) _startTiming();
    _followAccessibility();
  }

  void _startTiming() {
    if (_timing) return;
    _timing = true;
    SchedulerBinding.instance.addTimingsCallback(_handleTimings);
  }

  void _stopTiming() {
    if (!_timing) return;
    _timing = false;
    SchedulerBinding.instance.removeTimingsCallback(_handleTimings);
  }

  /// Judges later frames against the rate the display runs at now.
  void _followDisplay() {
    final stated = widget.adaptiveQuality;
    final governor = _governor;
    if (stated == null || governor == null) return;
    final view = View.maybeOf(context);
    governor.setBudget(stated.budgetMicros(view?.display.refreshRate));
  }

  /// Holds the governor off while the surfaces are at the lowest tier because
  /// the user asked for less transparency, and starts over when they stop.
  void _followAccessibility() {
    final governor = _governor;
    if (governor == null) return;
    if (widget.reduceTransparency) {
      _accessibilityHold ??= governor.hold();
    } else if (_accessibilityHold != null) {
      _accessibilityHold!.release();
      _accessibilityHold = null;
      governor.reset();
    }
  }

  void _handleTimings(List<FrameTiming> timings) {
    final governor = _governor;
    if (governor == null) return;
    for (final timing in timings) {
      governor.add(
        timing.rasterDuration.inMicroseconds,
        timing.timestampInMicroseconds(FramePhase.rasterFinish),
      );
    }
  }

  void _handleChange(CoreQualityChange change) {
    if (!mounted) return;
    setState(() => _tier = change.to);
    // After the frame that applies the tier, so an app that logs or persists
    // what it learns hears about a change that is on screen.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.adaptiveQuality?.onQualityChanged?.call(change);
    });
  }

  @override
  Widget build(BuildContext context) {
    final published = CoreQualityLadder.standard.effective(
      _tier,
      reduceTransparency: widget.reduceTransparency,
    );

    return AdaptiveQualityScope(
      tier: published,
      opensHold: _governor == null ? null : hold,
      child: widget.child,
    );
  }
}

/// Whether two statements ask for the same thing — both none, or equal terms.
bool _sameTerms(CoreAdaptiveQuality? a, CoreAdaptiveQuality? b) =>
    a == null || b == null ? a == null && b == null : a.sameTerms(b);
