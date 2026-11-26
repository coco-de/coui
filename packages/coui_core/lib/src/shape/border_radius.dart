/// Platform-neutral border radius (4-corner) for CoUI component styles.
///
/// CoUI components share a single Style class across Flutter and Web
/// (Epic #1415 option D). Border radius is expressed as
/// [CoreBorderRadius] in the platform-neutral Style; resolvers convert
/// to `BorderRadius` (Flutter) or a CSS `border-radius` string (Web)
/// at render time.
library;

import 'package:meta/meta.dart';

/// Four-corner radii in logical pixels.
///
/// Mirrors Flutter's `BorderRadius` surface but is platform-neutral so
/// the same value flows through Flutter and Web pipelines unchanged.
@immutable
class CoreBorderRadius {
  /// Creates [CoreBorderRadius] with the four corners given explicitly.
  const CoreBorderRadius.only({
    this.topLeft = 0,
    this.topRight = 0,
    this.bottomLeft = 0,
    this.bottomRight = 0,
  });

  /// Creates [CoreBorderRadius] with all four corners equal to [value].
  const CoreBorderRadius.all(double value)
    : topLeft = value,
      topRight = value,
      bottomLeft = value,
      bottomRight = value;

  /// Creates [CoreBorderRadius] with all four corners equal to [value]
  /// (alias of [CoreBorderRadius.all] for parity with
  /// `BorderRadius.circular`).
  const CoreBorderRadius.circular(double value)
    : topLeft = value,
      topRight = value,
      bottomLeft = value,
      bottomRight = value;

  /// Creates [CoreBorderRadius] with symmetric top / bottom radii.
  const CoreBorderRadius.vertical({double top = 0, double bottom = 0})
    : topLeft = top,
      topRight = top,
      bottomLeft = bottom,
      bottomRight = bottom;

  /// Creates [CoreBorderRadius] with symmetric left / right radii.
  const CoreBorderRadius.horizontal({double left = 0, double right = 0})
    : topLeft = left,
      bottomLeft = left,
      topRight = right,
      bottomRight = right;

  /// Zero radius on all four corners.
  static const CoreBorderRadius zero = CoreBorderRadius.all(0);

  /// Top-left corner radius (px).
  final double topLeft;

  /// Top-right corner radius (px).
  final double topRight;

  /// Bottom-left corner radius (px).
  final double bottomLeft;

  /// Bottom-right corner radius (px).
  final double bottomRight;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreBorderRadius &&
          runtimeType == other.runtimeType &&
          topLeft == other.topLeft &&
          topRight == other.topRight &&
          bottomLeft == other.bottomLeft &&
          bottomRight == other.bottomRight;

  @override
  int get hashCode => Object.hash(topLeft, topRight, bottomLeft, bottomRight);

  @override
  String toString() =>
      'CoreBorderRadius(tl=$topLeft, tr=$topRight, '
      'bl=$bottomLeft, br=$bottomRight)';
}
