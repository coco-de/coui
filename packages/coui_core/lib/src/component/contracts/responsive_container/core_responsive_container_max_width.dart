/// Maximum-width presets for `ResponsiveContainer` across platforms.
///
/// Values map 1:1 to the `CoreBreakpoint` scale so Flutter's
/// `ConstrainedBox(maxWidth: ...)` and Web's inline
/// `max-width: <rem>` line up at exactly the same pixel widths.
///
/// `full` opts out of the max-width constraint entirely (equivalent to
/// Flutter's `double.infinity` / Web's `max-width: 100%`).
enum CoreResponsiveContainerMaxWidth {
  /// Small — 640 px.
  sm(640),

  /// Medium — 768 px.
  md(768),

  /// Large — 1024 px.
  lg(1024),

  /// Extra large — 1280 px.
  xl(1280),

  /// 2× extra large — 1536 px.
  xxl(1536),

  /// No max-width constraint (stretch to parent).
  full(null);

  /// Maximum width in logical pixels at 1.0 scaling, or `null` for
  /// [full] which has no upper bound.
  const CoreResponsiveContainerMaxWidth(this.maxWidth);

  /// Logical pixel value for this preset. `null` means "no limit".
  final double? maxWidth;
}
