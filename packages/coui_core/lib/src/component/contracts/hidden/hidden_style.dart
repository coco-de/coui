/// Per-instance style for `Hidden`.
library;

import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/motion/easing_scale.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Hidden` collapse / expand
/// transition should animate.
///
/// `Hidden` exposes its behavioural inputs (`direction` / `duration`
/// / `keepSpace` / `reverse` / `curve`) directly on the contract — those
/// stay flat on the widget. `CoreHiddenStyle` owns the design-system
/// chrome defaults (transition duration and easing) plus the matching
/// per-instance override slots, so the Flutter / Web resolvers fold a
/// single merge chain:
///
/// ```text
/// design-system default
///   → CoreHiddenTheme.style                       // 프로젝트 공통
///   → widget.duration / widget.curve (behavioural fast-path override)
/// ```
@immutable
class CoreHiddenStyle implements CoreStyle<CoreHiddenStyle> {
  /// Creates a [CoreHiddenStyle].
  const CoreHiddenStyle({this.transitionDuration, this.transitionCurve});

  /// Default collapse / expand transition duration.
  ///
  /// Flutter consumes the [Duration] directly, Web embeds the
  /// millisecond value in the inline `transition` CSS shorthand.
  static const Duration defaultTransitionDuration = Duration(
    milliseconds: CoreDuration.normal,
  );

  /// Default collapse / expand transition easing.
  ///
  /// [CoreEasing.move] — the alias for movement between two
  /// on-screen states. Flutter converts the four control points to a
  /// `Curve`, Web emits them as the `cubic-bezier(...)` timing function
  /// of the same inline `transition` shorthand, so both platforms
  /// animate on one curve.
  static const CoreCubicBezier defaultTransitionCurve = CoreEasing.move;

  /// Collapse / expand transition duration override. `null` →
  /// [defaultTransitionDuration].
  final Duration? transitionDuration;

  /// Collapse / expand transition easing override. `null` →
  /// [defaultTransitionCurve].
  final CoreCubicBezier? transitionCurve;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreHiddenStyle merge(CoreHiddenStyle? other) {
    if (other == null) return this;
    return CoreHiddenStyle(
      transitionDuration: other.transitionDuration ?? transitionDuration,
      transitionCurve: other.transitionCurve ?? transitionCurve,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreHiddenStyle copyWith({
    Duration? transitionDuration,
    CoreCubicBezier? transitionCurve,
  }) {
    return CoreHiddenStyle(
      transitionDuration: transitionDuration ?? this.transitionDuration,
      transitionCurve: transitionCurve ?? this.transitionCurve,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreHiddenStyle &&
          runtimeType == other.runtimeType &&
          transitionDuration == other.transitionDuration &&
          transitionCurve == other.transitionCurve;

  @override
  int get hashCode => Object.hash(transitionDuration, transitionCurve);
}
