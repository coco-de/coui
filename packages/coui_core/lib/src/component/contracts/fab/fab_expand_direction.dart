/// Direction in which `Fab` speed-dial actions expand.
///
/// Both Flutter and Web compute action offsets from the same formula
/// so the speed dial unfolds identically on each platform.
library;

/// Direction in which the speed-dial actions expand.
enum CoreFabExpandDirection {
  /// Actions expand upward.
  up,

  /// Actions expand downward.
  down,

  /// Actions expand to the left.
  left,

  /// Actions expand to the right.
  right,

  /// Actions expand in a quarter-circle fan / flower pattern.
  fan;

  /// Widget default direction. Flutter / Web `Fab` constructors
  /// reference this so neither platform diverges silently.
  static const CoreFabExpandDirection defaultDirection = up;
}
