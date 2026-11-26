import 'package:meta/meta.dart';

/// Platform-neutral size constraints used by the Window contract.
///
/// Mirrors Flutter's `BoxConstraints` (min/max width & height) but has no
/// `dart:ui` dependency so it can be shared with Jaspr Web.
@immutable
class CoreWindowConstraints {
  /// Creates a [CoreWindowConstraints].
  const CoreWindowConstraints({
    this.minWidth = 0,
    this.maxWidth = double.infinity,
    this.minHeight = 0,
    this.maxHeight = double.infinity,
  });

  /// Creates constraints where min width/height are both [size] and max
  /// are unbounded.
  const CoreWindowConstraints.minimum(double size)
    : minWidth = size,
      maxWidth = double.infinity,
      minHeight = size,
      maxHeight = double.infinity;

  /// Minimum width in logical pixels.
  final double minWidth;

  /// Maximum width in logical pixels. May be `double.infinity`.
  final double maxWidth;

  /// Minimum height in logical pixels.
  final double minHeight;

  /// Maximum height in logical pixels. May be `double.infinity`.
  final double maxHeight;

  @override
  bool operator ==(Object other) =>
      other is CoreWindowConstraints &&
      other.minWidth == minWidth &&
      other.maxWidth == maxWidth &&
      other.minHeight == minHeight &&
      other.maxHeight == maxHeight;

  @override
  int get hashCode => Object.hash(minWidth, maxWidth, minHeight, maxHeight);

  @override
  String toString() =>
      'CoreWindowConstraints(min: ${minWidth}x$minHeight, '
      'max: ${maxWidth}x$maxHeight)';
}

/// Default window constraints — 200×200 minimum, unbounded maximum.
const kCoreDefaultWindowConstraints = CoreWindowConstraints.minimum(200);
