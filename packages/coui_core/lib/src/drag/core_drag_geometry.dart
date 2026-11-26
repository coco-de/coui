import 'dart:math' as math;

import 'package:meta/meta.dart';

/// A point in the drag coordinate space.
///
/// The space is whatever the platform adapter measures in — Flutter global
/// logical pixels, Web client CSS pixels. The engine never converts between
/// spaces; it only requires that pointer positions and measured rects come
/// from the *same* space within one scope.
@immutable
class CoreDragPoint {
  /// Creates a point.
  const CoreDragPoint(this.x, this.y);

  /// The origin.
  static const CoreDragPoint zero = CoreDragPoint(0, 0);

  /// Horizontal coordinate.
  final double x;

  /// Vertical coordinate.
  final double y;

  /// Returns this point moved by [dx] / [dy].
  CoreDragPoint translate(double dx, double dy) => .new(x + dx, y + dy);

  /// The straight-line distance to [other].
  double distanceTo(CoreDragPoint other) =>
      math.sqrt(math.pow(other.x - x, 2) + math.pow(other.y - y, 2));

  @override
  bool operator ==(Object other) =>
      other is CoreDragPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(CoreDragPoint, x, y);

  @override
  String toString() => 'CoreDragPoint($x, $y)';
}

/// Translation applied to a dragged item, anchored at the drag start.
///
/// The engine reports movement as a transform rather than an accumulated
/// delta so a consumer can compute `startPosition + transform` — a value
/// that cannot drift, however many move events were coalesced or dropped.
@immutable
class CoreDragOffset {
  /// Creates a translation.
  const CoreDragOffset({this.x = 0, this.y = 0});

  /// No translation.
  static const CoreDragOffset zero = CoreDragOffset();

  /// Whether this offset moves anything at all.
  bool get isActive => x != 0 || y != 0;

  /// Horizontal translation.
  final double x;

  /// Vertical translation.
  final double y;

  @override
  bool operator ==(Object other) =>
      other is CoreDragOffset && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(CoreDragOffset, x, y);

  @override
  String toString() => 'CoreDragOffset($x, $y)';
}

/// A measured rectangle in the drag coordinate space.
@immutable
class CoreDragRect {
  /// Creates a rectangle.
  const CoreDragRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  }) : assert(width >= 0, 'CoreDragRect width must be non-negative.'),
       assert(height >= 0, 'CoreDragRect height must be non-negative.');

  /// The left edge.
  final double left;

  /// The top edge.
  final double top;

  /// The horizontal extent.
  final double width;

  /// The vertical extent.
  final double height;

  /// The right edge.
  double get right => left + width;

  /// The bottom edge.
  double get bottom => top + height;

  /// The centre point.
  CoreDragPoint get center => .new(left + width / 2, top + height / 2);

  /// Whether [point] falls inside this rectangle (edges inclusive).
  bool contains(CoreDragPoint point) =>
      point.x >= left &&
      point.x <= right &&
      point.y >= top &&
      point.y <= bottom;

  /// Returns this rectangle moved by [offset].
  CoreDragRect shift(CoreDragOffset offset) => .new(
    left: left + offset.x,
    top: top + offset.y,
    width: width,
    height: height,
  );

  @override
  bool operator ==(Object other) =>
      other is CoreDragRect &&
      other.left == left &&
      other.top == top &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(CoreDragRect, left, top, width, height);

  @override
  String toString() =>
      'CoreDragRect(left: $left, top: $top, width: $width, height: $height)';
}
