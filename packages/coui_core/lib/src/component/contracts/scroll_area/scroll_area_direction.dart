/// Scroll axis for `ScrollArea`.
enum CoreScrollAreaDirection {
  /// Vertical scrolling. Content overflowing along the Y axis becomes
  /// scrollable; the X axis is clipped.
  vertical,

  /// Horizontal scrolling. Content overflowing along the X axis becomes
  /// scrollable; the Y axis is clipped.
  horizontal;

  /// Widget default direction. Flutter and Web `ScrollArea`
  /// constructors reference this so silent platform divergence is
  /// impossible.
  static const CoreScrollAreaDirection defaultDirection = vertical;
}
