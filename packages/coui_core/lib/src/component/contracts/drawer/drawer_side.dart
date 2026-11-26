/// Side enum for unified drawer components.
library;

/// The side from which a drawer slides in.
enum CoreDrawerSide {
  /// Slides in from the left edge.
  left,

  /// Slides in from the right edge.
  right,

  /// Slides in from the top edge.
  top,

  /// Slides in from the bottom edge.
  bottom;

  /// Widget default side. The Flutter / Web `Drawer` constructor
  /// default references this value so the two platforms cannot
  /// silently diverge.
  static const CoreDrawerSide defaultSide = left;
}
