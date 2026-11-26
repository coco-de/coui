/// Style of text decoration line.
///
/// Maps to:
/// - Flutter: `TextDecorationStyle`.
/// - Web: CSS `text-decoration-style`.
enum CoreTextDecorationStyle {
  /// Single solid line.
  solid,

  /// Two parallel solid lines.
  double,

  /// Dotted line.
  dotted,

  /// Dashed line.
  dashed,

  /// Sinusoidal wavy line (typically used for spell-check indicators).
  wavy,
}
