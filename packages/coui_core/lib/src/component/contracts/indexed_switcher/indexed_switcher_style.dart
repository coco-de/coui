/// Per-instance style for `IndexedSwitcher`.
library;

import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/motion/easing_scale.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how an `IndexedSwitcher` moves from one
/// view to the next.
///
/// The switch is a fade through: the outgoing view fades out over
/// [exitDuration], then the incoming view fades in over [enterDuration].
/// The two phases never overlap. Halfway through a cross-fade two
/// unrelated screens sit on top of each other at half strength; a fade
/// through never shows both.
///
/// Both durations are transition-tier motion, so a reduced-motion
/// request makes the switch instant on both platforms.
///
/// Platform-neutral: the curves are cubic-bezier control points, which
/// Flutter turns into a `Curve` and Web into a CSS timing function.
/// All design-system defaults live here as `static const` fields so the
/// Flutter and Web resolvers share a single source of truth.
@immutable
class CoreIndexedSwitcherStyle implements CoreStyle<CoreIndexedSwitcherStyle> {
  /// Creates a [CoreIndexedSwitcherStyle].
  const CoreIndexedSwitcherStyle({
    this.exitDuration,
    this.enterDuration,
    this.exitCurve,
    this.enterCurve,
  });

  // ─── Design-system defaults ───────────────────────────────────────

  /// Default fade-out of the outgoing view — [CoreDuration.instant].
  ///
  /// Short on purpose: once another destination is picked, the old view
  /// only has to get out of the way.
  static const Duration defaultExitDuration = Duration(
    milliseconds: CoreDuration.instant,
  );

  /// Default fade-in of the incoming view — [CoreDuration.normal].
  ///
  /// Starts when the fade-out ends. With both defaults the whole switch
  /// takes [CoreDuration.moderate].
  static const Duration defaultEnterDuration = Duration(
    milliseconds: CoreDuration.normal,
  );

  /// Default easing of the fade-out — [CoreEasing.exit], the alias for an
  /// element leaving.
  static const CoreCubicBezier defaultExitCurve = CoreEasing.exit;

  /// Default easing of the fade-in — [CoreEasing.enter], the alias for an
  /// element arriving.
  static const CoreCubicBezier defaultEnterCurve = CoreEasing.enter;

  // ─── Fields ───────────────────────────────────────────────────────

  /// How long the outgoing view takes to fade out.
  ///
  /// `null` → [defaultExitDuration].
  final Duration? exitDuration;

  /// How long the incoming view takes to fade in, once the outgoing view
  /// is gone.
  ///
  /// `null` → [defaultEnterDuration].
  final Duration? enterDuration;

  /// Easing of the fade-out, as cubic-bezier control points.
  ///
  /// `null` → [defaultExitCurve].
  final CoreCubicBezier? exitCurve;

  /// Easing of the fade-in, as cubic-bezier control points.
  ///
  /// `null` → [defaultEnterCurve].
  final CoreCubicBezier? enterCurve;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreIndexedSwitcherStyle merge(CoreIndexedSwitcherStyle? other) {
    if (other == null) return this;

    return CoreIndexedSwitcherStyle(
      exitDuration: other.exitDuration ?? exitDuration,
      enterDuration: other.enterDuration ?? enterDuration,
      exitCurve: other.exitCurve ?? exitCurve,
      enterCurve: other.enterCurve ?? enterCurve,
    );
  }

  /// Returns a copy with the supplied non-null fields overridden.
  CoreIndexedSwitcherStyle copyWith({
    Duration? exitDuration,
    Duration? enterDuration,
    CoreCubicBezier? exitCurve,
    CoreCubicBezier? enterCurve,
  }) {
    return CoreIndexedSwitcherStyle(
      exitDuration: exitDuration ?? this.exitDuration,
      enterDuration: enterDuration ?? this.enterDuration,
      exitCurve: exitCurve ?? this.exitCurve,
      enterCurve: enterCurve ?? this.enterCurve,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreIndexedSwitcherStyle &&
          runtimeType == other.runtimeType &&
          exitDuration == other.exitDuration &&
          enterDuration == other.enterDuration &&
          exitCurve == other.exitCurve &&
          enterCurve == other.enterCurve;

  @override
  int get hashCode =>
      Object.hash(exitDuration, enterDuration, exitCurve, enterCurve);
}
