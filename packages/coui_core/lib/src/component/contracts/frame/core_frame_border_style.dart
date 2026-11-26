/// Border style for `CoreFrameContract`.
///
/// Maps to:
/// - Flutter: `BorderStyle.solid` for [solid] / [none]; [dashed] /
///   [dotted] are drawn via `CustomPaint` (Flutter has no native
///   dashed/dotted border on `BoxDecoration`).
/// - Web: CSS `border-style: solid | dashed | dotted | none`.
/// - Figma: Stroke style (Solid / Dashed / Custom).
///
/// Replaces the previous `CoreOutlinedContainerBorderStyle` —
/// `OutlinedContainer` is absorbed into `Frame`, and this enum
/// becomes the unified border style for every frame.
enum CoreFrameBorderStyle {
  /// Solid border (default).
  solid,

  /// Dashed border.
  dashed,

  /// Dotted border.
  dotted,

  /// No border drawn.
  none,
}
