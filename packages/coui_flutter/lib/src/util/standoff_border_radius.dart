import 'package:flutter/painting.dart';

/// Grows a corner for a ring that stands off from a box.
///
/// A ring drawn `distance` outside a rounded box follows the box when each
/// of its corners is the box's corner plus `distance` — the two curves then
/// share a centre. One shared rule, read by every standoff ring on Flutter
/// (`FocusOutline`'s circle branch, `Avatar`'s ring), so the two cannot
/// drift apart.
extension StandoffBorderRadius on BorderRadius {
  /// Returns this radius with every round corner grown by [distance].
  ///
  /// A corner that is already square stays square. A theme axis can cap
  /// every radius at zero; growing that corner back would repaint a corner
  /// the theme just squared, and it would leave Flutter alone in making
  /// it — a CSS `box-shadow` spread grows a corner only when that corner
  /// is already round, so Web draws the square ring the preset asked for
  /// either way.
  ///
  /// Above zero this is the plain sum, which is what CSS also converges on
  /// once the radius reaches the spread distance. The two differ slightly
  /// in between; a standoff is a few logical pixels wide and the corner
  /// ladder has no step inside that gap, so the distinction has nowhere to
  /// land.
  BorderRadius standoff(double distance) {
    Radius grow(Radius corner) => corner.x == 0 && corner.y == 0
        ? corner
        : corner + Radius.circular(distance);

    return BorderRadius.only(
      topLeft: grow(topLeft),
      topRight: grow(topRight),
      bottomLeft: grow(bottomLeft),
      bottomRight: grow(bottomRight),
    );
  }
}
