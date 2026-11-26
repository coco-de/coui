/// Position enum for unified swiper components.
library;

/// The edge from which a swiper overlay slides into the viewport.
///
/// The swipe gesture that opens the overlay is the inverse of the
/// slide direction — e.g. a [left] overlay is revealed by swiping
/// rightwards.
enum CoreSwiperPosition {
  /// Overlay slides in from the left edge (revealed by swiping right).
  left,

  /// Overlay slides in from the right edge (revealed by swiping left).
  right,

  /// Overlay slides in from the top edge (revealed by swiping down).
  top,

  /// Overlay slides in from the bottom edge (revealed by swiping up).
  bottom;

  /// Widget default position. The Flutter / Web `Swiper` constructor
  /// default references this value so the two platforms cannot
  /// silently diverge.
  static const CoreSwiperPosition defaultPosition = left;

  /// Whether this position slides along the horizontal axis.
  bool get isHorizontal => this == .left || this == .right;
}
