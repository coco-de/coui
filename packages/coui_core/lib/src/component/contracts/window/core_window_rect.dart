import 'package:meta/meta.dart';

/// Platform-neutral rectangle used by the Window contract.
///
/// Mirrors Flutter's `Rect.fromLTWH` semantics but lives in `coui_core`
/// so the contract is free of `dart:ui` dependencies and can be shared
/// with Jaspr Web.
@immutable
class CoreWindowRect {
  /// Creates a rectangle from the given left/top/width/height.
  const CoreWindowRect.fromLTWH(this.left, this.top, this.width, this.height);

  /// Linearly interpolates between [a] and [b] by [t] (0..1).
  CoreWindowRect.lerp(CoreWindowRect a, CoreWindowRect b, double t)
    : left = a.left + (b.left - a.left) * t,
      top = a.top + (b.top - a.top) * t,
      width = a.width + (b.width - a.width) * t,
      height = a.height + (b.height - a.height) * t;

  /// Left offset in logical pixels (or relative 0..1 when used for
  /// `maximized`).
  final double left;

  /// Top offset in logical pixels (or relative 0..1 when used for
  /// `maximized`).
  final double top;

  /// Width in logical pixels (or relative 0..1).
  final double width;

  /// Height in logical pixels (or relative 0..1).
  final double height;

  /// Right edge (`left + width`).
  double get right => left + width;

  /// Bottom edge (`top + height`).
  double get bottom => top + height;

  /// Returns a copy translated by ([dx], [dy]).
  CoreWindowRect translate(double dx, double dy) =>
      .fromLTWH(left + dx, top + dy, width, height);

  @override
  bool operator ==(Object other) =>
      other is CoreWindowRect &&
      other.left == left &&
      other.top == top &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(left, top, width, height);

  @override
  String toString() => 'CoreWindowRect.fromLTWH($left, $top, $width, $height)';
}
