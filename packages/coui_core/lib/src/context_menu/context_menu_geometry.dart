/// The one box type the context menu's pointer and placement rules speak.
///
/// Both rules compare lengths that two renderers measure differently — a
/// Flutter render box in logical pixels, a DOM rect in CSS pixels — so they
/// are written once over plain numbers and each seat converts its own
/// measurement into this box before asking.
library;

import 'package:meta/meta.dart';

/// An axis-aligned box in one coordinate space: x grows to the right, y grows
/// downward, and every length is a logical pixel (Flutter) or a CSS pixel
/// (Web).
///
/// A box is **half-open**: it contains its [left] and [top] edges and not its
/// [right] and [bottom] edges. Two boxes that touch share an edge, and a point
/// on that edge belongs to the box that starts there — never to both, never to
/// neither. That is the answer a hit test needs, and it is the one both seats
/// get without deciding it themselves.
@immutable
class CoreMenuBox {
  /// Creates a box from its four edges.
  const CoreMenuBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  /// Creates a box from its top-left corner and its size.
  factory CoreMenuBox.fromLTWH(
    double left,
    double top,
    double width,
    double height,
  ) => CoreMenuBox(
    left: left,
    top: top,
    right: left + width,
    bottom: top + height,
  );

  /// The left edge, inclusive.
  final double left;

  /// The top edge, inclusive.
  final double top;

  /// The right edge, exclusive.
  final double right;

  /// The bottom edge, exclusive.
  final double bottom;

  /// The horizontal extent.
  double get width => right - left;

  /// The vertical extent.
  double get height => bottom - top;

  /// Whether the box encloses no area — a pointer cannot be inside it.
  bool get isEmpty => right <= left || bottom <= top;

  /// Whether the point ([x], [y]) is inside the box.
  bool containsPoint(double x, double y) =>
      x >= left && x < right && y >= top && y < bottom;

  /// The part of this box that [other] also covers, or `null` when they share
  /// no area (boxes that only touch share none).
  CoreMenuBox? intersect(CoreMenuBox other) {
    final box = CoreMenuBox(
      left: left > other.left ? left : other.left,
      top: top > other.top ? top : other.top,
      right: right < other.right ? right : other.right,
      bottom: bottom < other.bottom ? bottom : other.bottom,
    );

    return box.isEmpty ? null : box;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMenuBox &&
          left == other.left &&
          top == other.top &&
          right == other.right &&
          bottom == other.bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);

  @override
  String toString() =>
      'CoreMenuBox(left: $left, top: $top, right: $right, bottom: $bottom)';
}
