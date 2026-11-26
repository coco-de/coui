/// How to clip content that overflows the viewport bounds.
///
/// Mirrors a subset of Flutter's `Clip` enum that can be expressed on both
/// Flutter and Web. Flutter's anti-alias modes are collapsed onto [hardEdge]
/// on Web because CSS `overflow: auto` is always a hard edge clip.
enum CoreClip {
  /// No clipping. Overflowing content spills outside the viewport.
  ///
  /// On Web this maps to `overflow: visible` (which disables scrolling) and
  /// is therefore only useful when the viewport is already large enough to
  /// contain the content — mostly an escape hatch for edge cases.
  none,

  /// Clip with a fast hard-edged rectangle. Matches Web `overflow: auto/hidden`.
  hardEdge,

  /// Clip with anti-aliasing (Flutter-only; treated as [hardEdge] on Web).
  antiAlias,

  /// Clip with anti-aliasing + save layer (Flutter-only; treated as
  /// [hardEdge] on Web).
  antiAliasWithSaveLayer,
}
