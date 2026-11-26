/// Cross-axis alignment for `CoreFrameContract` children when
/// `direction` is set (i.e. flex layout is enabled).
///
/// Maps to:
/// - Flutter: `Row.crossAxisAlignment` / `Column.crossAxisAlignment` /
///   `Flex.crossAxisAlignment`.
/// - Web: CSS `align-items`.
/// - Figma: Auto Layout cross-axis alignment.
enum CoreCrossAxisAlignment {
  /// Align children to the start of the cross axis.
  start,

  /// Align children to the end of the cross axis.
  end,

  /// Centre children on the cross axis.
  center,

  /// Stretch children to fill the cross axis.
  stretch,

  /// Align children's first text baseline.
  baseline,
}
