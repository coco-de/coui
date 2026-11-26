/// Theme overrides for the unified Hidden component.
library;

import 'package:coui_core/src/component/contracts/hidden/core_hidden_direction.dart';
import 'package:coui_core/src/component/contracts/hidden/hidden_style.dart';
import 'package:coui_core/src/motion/easing_scale.dart';
import 'package:meta/meta.dart';

/// Project-level style overrides for a unified Hidden component.
@immutable
class CoreHiddenTheme {
  /// Creates a [CoreHiddenTheme].
  const CoreHiddenTheme({
    this.style,
    this.direction,
    this.duration,
    this.curve,
    this.keepSpace,
    this.reverse,
  });

  /// Project-level chrome style override (transition duration and
  /// easing). Folds into the resolver's merge chain ahead of the
  /// design-system default.
  final CoreHiddenStyle? style;

  /// Default collapse direction.
  final CoreHiddenDirection? direction;

  /// Default transition duration.
  final Duration? duration;

  /// Default transition easing, as cubic-bezier control points. Both
  /// platforms read the same record — Flutter converts it to a `Curve`,
  /// Web to a `cubic-bezier(...)` timing function.
  final CoreCubicBezier? curve;

  /// Default reservation of space behaviour.
  final bool? keepSpace;

  /// Default reverse-collapse behaviour.
  final bool? reverse;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoreHiddenTheme &&
        other.style == style &&
        other.direction == direction &&
        other.duration == duration &&
        other.curve == curve &&
        other.keepSpace == keepSpace &&
        other.reverse == reverse;
  }

  @override
  int get hashCode =>
      Object.hash(style, direction, duration, curve, keepSpace, reverse);
}
