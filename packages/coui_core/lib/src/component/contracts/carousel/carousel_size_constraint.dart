/// Sizing policy for a single carousel slide.
library;

import 'package:meta/meta.dart';

/// How far one carousel slide extends along the carousel axis.
///
/// A slide narrower (or shorter, for a vertical carousel) than the viewport
/// leaves its neighbours partly visible; where the slack goes is decided by
/// `CoreCarouselAlignment`.
@immutable
abstract class CoreCarouselSizeConstraint {
  /// Creates a [CoreCarouselSizeConstraint].
  const CoreCarouselSizeConstraint();

  /// A slide that extends [size] logical pixels along the carousel axis.
  const factory CoreCarouselSizeConstraint.fixed(double size) =
      CoreCarouselFixedConstraint;

  /// A slide that extends [fraction] of the viewport along the carousel axis.
  const factory CoreCarouselSizeConstraint.fractional(double fraction) =
      CoreCarouselFractionalConstraint;
}

/// A slide sized to an absolute extent in logical pixels.
@immutable
class CoreCarouselFixedConstraint extends CoreCarouselSizeConstraint {
  /// Creates a [CoreCarouselFixedConstraint].
  ///
  /// [size] must be greater than 0.
  const CoreCarouselFixedConstraint(this.size)
    : assert(size > 0, 'size must be greater than 0');

  /// Slide extent along the carousel axis, in logical pixels.
  final double size;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCarouselFixedConstraint &&
          runtimeType == other.runtimeType &&
          size == other.size;

  @override
  int get hashCode => size.hashCode;
}

/// A slide sized to a fraction of the viewport extent.
@immutable
class CoreCarouselFractionalConstraint extends CoreCarouselSizeConstraint {
  /// Creates a [CoreCarouselFractionalConstraint].
  ///
  /// [fraction] must be greater than 0. `1` fills the viewport.
  const CoreCarouselFractionalConstraint(this.fraction)
    : assert(fraction > 0, 'fraction must be greater than 0');

  /// Slide extent as a fraction of the viewport (`1` = full viewport).
  final double fraction;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCarouselFractionalConstraint &&
          runtimeType == other.runtimeType &&
          fraction == other.fraction;

  @override
  int get hashCode => fraction.hashCode;
}
