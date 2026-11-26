/// Per-app style for the page transition — how a new screen arrives.
library;

import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/motion/easing_scale.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a new screen arrives and leaves.
///
/// The arriving screen fades in while it rises into place by
/// [slideDistance] over [enterDuration]; leaving, it fades out while it
/// sinks back over [exitDuration]. The screen underneath does not move.
///
/// This is the page transition wherever the platform has no page motion
/// of its own: desktop, the web, and the browser's own page navigation.
/// On iOS and Android a screen arrives with the platform's own motion
/// instead, because that motion carries the platform's back gesture —
/// the edge swipe on iOS and the predictive back on Android. Apps can use
/// [usePlatformDurations] to customize the timing of those transitions. A
/// reduced-motion request makes every page transition instant.
///
/// Platform-neutral: the curves are cubic-bezier control points, which
/// Flutter turns into a `Curve` and Web into a CSS timing function. All
/// design-system defaults live here as `static const` fields so the
/// Flutter and Web readers share a single source of truth.
@immutable
class CorePageTransitionStyle implements CoreStyle<CorePageTransitionStyle> {
  /// Creates a [CorePageTransitionStyle].
  const CorePageTransitionStyle({
    this.enterDuration,
    this.exitDuration,
    this.enterCurve,
    this.exitCurve,
    this.slideDistance,
    this.usePlatformDurations,
    this.animateAppBarTitle,
  });

  // ─── Design-system defaults ───────────────────────────────────────

  /// Default arrival — [CoreDuration.slow], the design system's step for a
  /// page-level transition.
  static const Duration defaultEnterDuration = Duration(
    milliseconds: CoreDuration.slow,
  );

  /// Default departure — [CoreDuration.moderate]. A screen the user is done
  /// with leaves faster than a new one arrives.
  static const Duration defaultExitDuration = Duration(
    milliseconds: CoreDuration.moderate,
  );

  /// Default easing of the arrival — [CoreEasing.enter].
  static const CoreCubicBezier defaultEnterCurve = CoreEasing.enter;

  /// Default easing of the departure — [CoreEasing.exit].
  static const CoreCubicBezier defaultExitCurve = CoreEasing.exit;

  /// Default rise — [CoreSpace.space16], in logical pixels.
  ///
  /// Enough to read as "this came in on top", short enough that the screen
  /// is never far from where it ends.
  static const double defaultSlideDistance = CoreSpace.space16;

  /// Blur of an app-bar title at the edge of a route transition.
  static const double defaultTitleBlurSigma = 4;

  // ─── Fields ───────────────────────────────────────────────────────

  /// How long a new screen takes to arrive.
  ///
  /// `null` → [defaultEnterDuration].
  final Duration? enterDuration;

  /// How long a screen takes to leave when it is closed.
  ///
  /// `null` → [defaultExitDuration].
  final Duration? exitDuration;

  /// Easing of the arrival, as cubic-bezier control points.
  ///
  /// `null` → [defaultEnterCurve].
  final CoreCubicBezier? enterCurve;

  /// Easing of the departure, as cubic-bezier control points.
  ///
  /// `null` → [defaultExitCurve].
  final CoreCubicBezier? exitCurve;

  /// How far below its place a new screen starts, in logical pixels.
  ///
  /// `null` → [defaultSlideDistance]. It grows with the app's scaling like
  /// every other length; it is not a spacing step, so the density setting
  /// does not change it.
  final double? slideDistance;

  /// Whether iOS and Android use their native transition durations.
  ///
  /// Defaults to true. When false, native routes use [enterDuration] and
  /// [exitDuration] with the platform's curves and back gesture.
  final bool? usePlatformDurations;

  /// Whether the app bar fades and blurs its title during a route transition.
  ///
  /// Defaults to true. Disable this to let the page transition carry the title
  /// with the rest of the page and avoid a separate title effect.
  final bool? animateAppBarTitle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CorePageTransitionStyle merge(CorePageTransitionStyle? other) {
    if (other == null) return this;

    return CorePageTransitionStyle(
      enterDuration: other.enterDuration ?? enterDuration,
      exitDuration: other.exitDuration ?? exitDuration,
      enterCurve: other.enterCurve ?? enterCurve,
      exitCurve: other.exitCurve ?? exitCurve,
      slideDistance: other.slideDistance ?? slideDistance,
      usePlatformDurations: other.usePlatformDurations ?? usePlatformDurations,
      animateAppBarTitle: other.animateAppBarTitle ?? animateAppBarTitle,
    );
  }

  /// Returns a copy with the supplied non-null fields overridden.
  CorePageTransitionStyle copyWith({
    Duration? enterDuration,
    Duration? exitDuration,
    CoreCubicBezier? enterCurve,
    CoreCubicBezier? exitCurve,
    double? slideDistance,
    bool? usePlatformDurations,
    bool? animateAppBarTitle,
  }) {
    return CorePageTransitionStyle(
      enterDuration: enterDuration ?? this.enterDuration,
      exitDuration: exitDuration ?? this.exitDuration,
      enterCurve: enterCurve ?? this.enterCurve,
      exitCurve: exitCurve ?? this.exitCurve,
      slideDistance: slideDistance ?? this.slideDistance,
      usePlatformDurations: usePlatformDurations ?? this.usePlatformDurations,
      animateAppBarTitle: animateAppBarTitle ?? this.animateAppBarTitle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CorePageTransitionStyle &&
          runtimeType == other.runtimeType &&
          enterDuration == other.enterDuration &&
          exitDuration == other.exitDuration &&
          enterCurve == other.enterCurve &&
          exitCurve == other.exitCurve &&
          slideDistance == other.slideDistance &&
          usePlatformDurations == other.usePlatformDurations &&
          animateAppBarTitle == other.animateAppBarTitle;

  @override
  int get hashCode => Object.hash(
    enterDuration,
    exitDuration,
    enterCurve,
    exitCurve,
    slideDistance,
    usePlatformDurations,
    animateAppBarTitle,
  );
}
