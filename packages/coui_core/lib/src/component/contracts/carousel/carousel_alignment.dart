/// Alignment of the active carousel slide inside the viewport.
library;

/// Fraction of the leftover viewport extent placed before a centred slide.
const double _kCenterAlignment = 0.5;

/// Where the active carousel slide sits inside the viewport.
///
/// Only observable when a slide is smaller than the viewport (see
/// `CoreCarouselSizeConstraint`) — a slide that fills the viewport has no
/// leftover extent to distribute.
enum CoreCarouselAlignment {
  /// Equal leftover extent before and after the active slide.
  center(_kCenterAlignment),

  /// All leftover extent before the active slide (slide at the trailing edge).
  end(1),

  /// No leftover extent before the active slide (slide at the leading edge).
  start(0);

  const CoreCarouselAlignment(this.alignment);

  /// Fraction of the leftover viewport extent placed before the slide —
  /// `0` = leading edge, `0.5` = centred, `1` = trailing edge.
  final double alignment;
}
