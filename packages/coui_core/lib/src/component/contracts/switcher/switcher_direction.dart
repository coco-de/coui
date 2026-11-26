/// Transition direction enum for `Switcher`.
library;

/// Direction in which a `Switcher` slides when its active index
/// changes.
///
/// Mirrors the four cardinal directions of the legacy Flutter
/// `Switcher` (`AxisDirection`). The Web `Switcher` honours all four
/// so the two platforms stay 1:1.
enum CoreSwitcherDirection {
  /// New view slides in from the bottom, old view exits upward.
  up,

  /// New view slides in from the top, old view exits downward.
  down,

  /// New view slides in from the right, old view exits to the left.
  left,

  /// New view slides in from the left, old view exits to the right.
  right;

  /// Widget default direction — referenced by both the Flutter and
  /// Web `Switcher` constructors so the two platforms never
  /// diverge.
  static const CoreSwitcherDirection defaultDirection = left;

  /// Whether this direction animates along the horizontal axis.
  bool get isHorizontal => this == .left || this == .right;
}
