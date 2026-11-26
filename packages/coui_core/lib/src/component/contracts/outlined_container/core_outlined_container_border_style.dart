/// Border style for `CoreOutlinedContainerContract`.
///
/// Maps to:
/// - Flutter: [solid] uses `BorderStyle.solid`; [dashed] and [dotted]
///   use `CustomPaint`, and [none] draws and reserves no border.
/// - Web: [solid] uses a CSS border, [dashed] and [dotted] use an SVG
///   overlay, and [none] draws and reserves no border.
enum CoreOutlinedContainerBorderStyle {
  /// Solid border (default).
  solid,

  /// Dashed border.
  dashed,

  /// Dotted border.
  dotted,

  /// No border is drawn or reserved in the layout.
  none,
}
