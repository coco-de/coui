/// Per-instance style for `Switcher`.
library;

import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/motion/easing_scale.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Switcher` animates between
/// views.
///
/// Carries the transition chrome only — the [duration] and [curve] of
/// the slide / fade animation. Platform-neutral: [curve] is stored as
/// cubic-bezier control points, which Flutter turns into a `Curve` and
/// Web into a CSS `cubic-bezier(...)` timing function.
///
/// All design-system defaults live here as `static const` fields so
/// the Flutter and Web resolvers share a single source of truth.
@immutable
class CoreSwitcherStyle implements CoreStyle<CoreSwitcherStyle> {
  /// Creates a [CoreSwitcherStyle].
  const CoreSwitcherStyle({this.duration, this.curve});

  // ─── Design-system defaults ───────────────────────────────────────

  /// Default slide / fade transition duration.
  static const Duration defaultDuration = Duration(
    milliseconds: CoreDuration.moderate,
  );

  /// Default slide / fade transition easing.
  ///
  /// [CoreEasing.move] — the alias for movement between two
  /// on-screen states, which is exactly what a view switch is.
  static const CoreCubicBezier defaultCurve = CoreEasing.move;

  // ─── Fields ───────────────────────────────────────────────────────

  /// Slide / fade transition duration.
  final Duration? duration;

  /// Slide / fade transition easing, as cubic-bezier control points.
  /// `null` → [defaultCurve].
  final CoreCubicBezier? curve;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreSwitcherStyle merge(CoreSwitcherStyle? other) {
    if (other == null) return this;
    return CoreSwitcherStyle(
      duration: other.duration ?? duration,
      curve: other.curve ?? curve,
    );
  }

  /// Returns a copy with the supplied non-null fields overridden.
  CoreSwitcherStyle copyWith({Duration? duration, CoreCubicBezier? curve}) {
    return CoreSwitcherStyle(
      duration: duration ?? this.duration,
      curve: curve ?? this.curve,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSwitcherStyle &&
          runtimeType == other.runtimeType &&
          duration == other.duration &&
          curve == other.curve;

  @override
  int get hashCode => Object.hash(duration, curve);
}
