/// How visual overflow should be handled when text exceeds its
/// container's bounds.
///
/// Maps to:
/// - Flutter: `TextOverflow`.
/// - Web: CSS `text-overflow` + `overflow` rules.
enum CoreTextOverflow {
  /// Clip the overflowing text without any indicator.
  clip,

  /// Fade the overflowing text out.
  fade,

  /// Use an ellipsis (`…`) to indicate overflow.
  ellipsis,

  /// Render overflowing text outside its container (no clipping).
  visible,
}
