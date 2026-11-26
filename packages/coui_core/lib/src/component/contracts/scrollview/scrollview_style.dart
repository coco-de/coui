/// Per-instance tuning style for `ScrollViewInterceptor`.
library;

import 'package:coui_core/src/component/core_style.dart';
import 'package:meta/meta.dart';

/// Immutable auto-scroll tuning style for `ScrollViewInterceptor`.
///
/// `ScrollViewInterceptor` simulates middle-mouse-button hold-scroll.
/// The cross-platform tuning it owns is the drag-speed multiplier and
/// the maximum scroll velocity cap — both feed the same per-second
/// velocity calculation on Flutter and Web. Behavioural fields
/// (`enabled`, `child`) stay flat on the widget.
///
/// ```text
/// CoreScrollViewInterceptorStyle.defaultX
///   → CoreScrollViewInterceptorTheme.style
///   → widget.scrollViewInterceptorStyle
/// ```
@immutable
class CoreScrollViewInterceptorStyle
    implements CoreStyle<CoreScrollViewInterceptorStyle> {
  /// Creates a [CoreScrollViewInterceptorStyle].
  const CoreScrollViewInterceptorStyle({this.dragSpeed, this.maxScrollSpeed});

  /// Multiplier applied to the pointer offset before the easing curve.
  final double? dragSpeed;

  /// Maximum absolute scroll velocity per frame (logical px).
  final double? maxScrollSpeed;

  /// Default drag-speed multiplier — the historical CoUI tuning.
  static const double defaultDragSpeed = 0.02;

  /// Default maximum scroll velocity per frame (logical px).
  static const double defaultMaxScrollSpeed = 10;

  /// Easing exponent applied to the pointer offset.
  ///
  /// A cubic curve makes a small pointer travel scroll gently and a
  /// large travel scroll fast — the familiar desktop autoscroll feel.
  static const double cubicPower = 3;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreScrollViewInterceptorStyle merge(CoreScrollViewInterceptorStyle? other) {
    if (other == null) return this;
    return CoreScrollViewInterceptorStyle(
      dragSpeed: other.dragSpeed ?? dragSpeed,
      maxScrollSpeed: other.maxScrollSpeed ?? maxScrollSpeed,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreScrollViewInterceptorStyle copyWith({
    double? dragSpeed,
    double? maxScrollSpeed,
  }) {
    return CoreScrollViewInterceptorStyle(
      dragSpeed: dragSpeed ?? this.dragSpeed,
      maxScrollSpeed: maxScrollSpeed ?? this.maxScrollSpeed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreScrollViewInterceptorStyle &&
          runtimeType == other.runtimeType &&
          dragSpeed == other.dragSpeed &&
          maxScrollSpeed == other.maxScrollSpeed;

  @override
  int get hashCode => Object.hash(dragSpeed, maxScrollSpeed);
}
