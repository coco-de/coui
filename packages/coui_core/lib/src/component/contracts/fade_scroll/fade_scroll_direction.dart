/// Scroll axis for `FadeScroll`.
enum CoreFadeScrollDirection {
  /// Vertical scrolling. Fade is applied to the top and bottom edges.
  vertical,

  /// Horizontal scrolling. Fade is applied to the start and end edges.
  horizontal;

  /// Widget default direction. Flutter and Web `FadeScroll`
  /// constructors reference this so silent platform divergence is
  /// impossible.
  static const CoreFadeScrollDirection defaultDirection = vertical;
}
