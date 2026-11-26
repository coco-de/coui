/// How a 2-dimensional scroll view handles diagonal drags.
///
/// Mirrors Flutter's `DiagonalDragBehavior` so it can be shared by the
/// cross-platform ScrollableClient contract. CSS native scrolling always
/// allows diagonal drags, so the Web implementation treats every value
/// other than [none] as identical (free).
enum CoreDiagonalDragBehavior {
  /// Disallow diagonal drags — only one axis scrolls at a time.
  none,

  /// Picks an axis based on the initial drag gesture (pointer weight).
  weightedEvent,

  /// Picks an axis based on continuous drag direction (dominant axis).
  weightedContinuous,

  /// Both axes scroll freely and simultaneously.
  free,
}
