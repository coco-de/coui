/// Responsive breakpoints shared by Flutter and Web.
///
/// Widths match Tailwind CSS defaults so that the Web implementation can
/// map each breakpoint directly onto its `sm:`/`md:`/`lg:`/`xl:` classes.
enum CoreBreakpoint {
  /// Everything from 0 up to but not including [sm].
  xs(0),

  /// ≥ 640 px.
  sm(640),

  /// ≥ 768 px.
  md(768),

  /// ≥ 1024 px.
  lg(1024),

  /// ≥ 1280 px.
  xl(1280),

  /// ≥ 1536 px.
  xxl(1536);

  /// Minimum viewport width (px) at which this breakpoint becomes active.
  const CoreBreakpoint(this.minWidth);

  /// Minimum viewport width in logical pixels.
  final double minWidth;

  /// The breakpoint active at a viewport [width] in logical pixels — the
  /// widest one whose [minWidth] the width reaches.
  ///
  /// The one place a width becomes a breakpoint. Both platforms' breakpoint
  /// resolvers and the typography tier read it, so a width cannot land in
  /// one breakpoint for layout and another for type.
  static CoreBreakpoint forWidth(double width) => values.lastWhere(
    (breakpoint) => width >= breakpoint.minWidth,
    orElse: () => xs,
  );
}
