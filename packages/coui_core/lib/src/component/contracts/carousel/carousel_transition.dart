/// How a carousel moves from one slide to the next.
library;

import 'package:meta/meta.dart';

/// Which motion a carousel uses between slides.
///
/// Both platforms render both modes: [sliding] translates the slides along
/// the carousel axis, [fading] cross-fades them in place.
enum CoreCarouselTransitionMode {
  /// Slides cross-fade in place — every slide stays at the same offset and
  /// only its opacity changes with the carousel progress.
  fading,

  /// Slides translate along the carousel axis, optionally separated by a gap.
  sliding,
}

/// Platform-neutral carousel transition.
///
/// Carries the two values both renderers need — the [mode] and the [gap]
/// between adjacent slides. Flutter layers its own slide-placement renderer
/// on top of this base; Web reads the same two values to emit either a
/// translated flex track or a stack of cross-faded slides.
@immutable
abstract class CoreCarouselTransition {
  /// Creates a [CoreCarouselTransition].
  const CoreCarouselTransition();

  /// A transition that translates slides along the carousel axis.
  ///
  /// [gap] is the space between adjacent slides in logical pixels.
  const factory CoreCarouselTransition.sliding({double gap}) =
      CoreCarouselSlidingTransition;

  /// A transition that cross-fades slides in place.
  const factory CoreCarouselTransition.fading() = CoreCarouselFadingTransition;

  /// Which motion this transition renders.
  CoreCarouselTransitionMode get mode;

  /// Space between adjacent slides along the carousel axis, in logical
  /// pixels. `0` for modes that stack slides at the same offset.
  double get gap;
}

/// Translating carousel transition.
@immutable
class CoreCarouselSlidingTransition extends CoreCarouselTransition {
  /// Creates a [CoreCarouselSlidingTransition].
  const CoreCarouselSlidingTransition({this.gap = 0});

  @override
  final double gap;

  @override
  CoreCarouselTransitionMode get mode => .sliding;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCarouselSlidingTransition &&
          runtimeType == other.runtimeType &&
          gap == other.gap;

  @override
  int get hashCode => gap.hashCode;
}

/// Cross-fading carousel transition.
@immutable
class CoreCarouselFadingTransition extends CoreCarouselTransition {
  /// Creates a [CoreCarouselFadingTransition].
  const CoreCarouselFadingTransition();

  @override
  double get gap => 0;

  @override
  CoreCarouselTransitionMode get mode => .fading;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCarouselFadingTransition && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}
