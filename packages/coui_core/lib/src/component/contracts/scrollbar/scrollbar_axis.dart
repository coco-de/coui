/// Scroll axis constraint for a unified scrollbar component.
library;

/// Axis along which a `Scrollbar` reports / displays its thumb.
///
/// Flutter maps this to `RawScrollbar.scrollbarOrientation`; Web maps
/// it to axis-specific `overflow` rules on the wrapper element.
enum CoreScrollbarAxis {
  /// Both axes scroll — `overflow: auto` on the wrapper.
  both,

  /// Vertical scrolling only — `overflow-y: auto; overflow-x: hidden`.
  vertical,

  /// Horizontal scrolling only — `overflow-x: auto; overflow-y: hidden`.
  horizontal;

  /// Default axis for `Scrollbar` — both Flutter and Web constructors
  /// reference this so the platforms cannot silently diverge.
  static const CoreScrollbarAxis defaultAxis = both;
}
