/// Direction along which content is laid out / scrolled.
///
/// Mirrors Flutter's `AxisDirection` enum so it can be shared by the
/// cross-platform ScrollableClient contract without pulling in the Flutter
/// SDK on Web builds.
enum CoreAxisDirection {
  /// Vertical, forward direction is upward (origin at the bottom).
  up,

  /// Horizontal, forward direction is to the right (origin at the left).
  right,

  /// Vertical, forward direction is downward (origin at the top).
  down,

  /// Horizontal, forward direction is to the left (origin at the right).
  left,
}
