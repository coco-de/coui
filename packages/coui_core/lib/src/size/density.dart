import 'package:coui_core/src/size/control_size.dart';
import 'package:coui_core/src/spacing/spacing.dart';

/// The document attribute a Web page carries while a density other than
/// [CoreDensity.standard] is active.
///
/// Lives here for the reason `kSurfaceStyleAttribute` does: the stylesheet
/// that writes rules for it, the switch that sets it and any consumer that
/// reads it must agree on one string, and a second spelling anywhere is a
/// silent no-op rather than an error.
const String kDensityAttribute = 'data-coui-density';

/// How tightly a whole app sets its spacing, its control rows and the
/// corners that follow those rows.
///
/// A theme axis: one choice that moves every component at once. It is read
/// at the geometry seat (`resolveThemeGeometry`) beside the surface style
/// and never by a component — a component that branched on it would be the
/// only one that followed it.
///
/// Each member moves a value along the scale it already sits on. It is not
/// a multiplier, and the difference is measurable rather than taste: the
/// one compact layout this kit authored by hand shrinks its seven fields by
/// four different ratios, which no single factor reproduces, and a factor
/// applied after a surface style's floor would always win over that floor.
/// A step re-map keeps every value on its scale — which on Web is what lets
/// the re-map travel through the `--coui-*` variables at all — and states a
/// floor as "no step below this one".
///
/// Three scales move together, and the third follows the second on
/// purpose:
///
/// * **Spacing** — padding, gaps and margins move one rung on the 4px grid
///   of `CoreSpace` (4 · 8 · 12 … 64, then 72 · 80 …). Values of 4 and
///   below do not move: they are the gap between an icon and its label, and
///   halving it glues the two together.
/// * **Control rows** — the heights of `CoreControlSize` move one rung of
///   that ladder.
/// * **Corners that follow a row** — a control's corner is its height × 0.25
///   (`CoreControlSize.cornerRatio`), so a density that moved the height
///   and not the corner would break that rule on every row. Corners on that
///   band (6 … 16) move one rung of it, which keeps every row's ratio — the
///   ends included, because both ladders stop at the same rung.
enum CoreDensity {
  /// Tighter: one rung down on each scale.
  ///
  /// A control row stops at `CoreControlSize.heightSm`. Density does not
  /// change type, and the label of a row from `sm` up is a line box (its
  /// label role at 140%) taller than what a 24px row leaves inside the 4px
  /// vertical padding no density moves — Flutter would grow the row to fit
  /// while the stylesheet held it, and the two platforms would part. The
  /// corner band stops at the matching rung.
  compact,

  /// The values as authored.
  standard,

  /// Roomier: one rung up on each scale, stopping at the top rung.
  spacious;

  /// The density used when a theme states none.
  static const CoreDensity defaultDensity = standard;

  /// Spacing at or below this does not move under any density.
  static const double spaceFloor = CoreSpace.space4;

  /// The rungs spacing moves along — the space scale on its 4px grid.
  ///
  /// The scale itself steps by 2 up to 18; moving one of those 2px steps is
  /// too small to read as a density at all, and moving two would make the
  /// rung size depend on where on the scale a value sits.
  static final List<double> spaceRungs = [
    for (final step in CoreSpace.steps)
      if (step >= spaceFloor && step % CoreSpace.space4 == 0) step,
  ];

  /// The rungs a corner that follows a control row moves along — the
  /// control ladder at its corner ratio.
  static final List<double> cornerRungs = [
    for (final height in CoreControlSize.steps)
      height * CoreControlSize.cornerRatio,
  ];

  /// The spacing step this density draws where [px] was authored.
  ///
  /// Off-scale values inside the scale's span move to the next rung in the
  /// same direction, so a deliberate 13 under [compact] becomes 12 rather
  /// than staying put. Values past either end of the scale stay: the scale
  /// says nothing about them.
  double space(double px) {
    if (px <= spaceFloor) return px;

    return switch (this) {
      compact => _down(spaceRungs, px, floor: spaceFloor),
      standard => px,
      spacious => _up(spaceRungs, px, from: spaceFloor),
    };
  }

  /// The height this density draws for a control row authored at [px].
  ///
  /// Only for a control row's height. An icon or an avatar that happens to
  /// measure 40 is not a row, which is why this is separate from [space]
  /// and is not applied to sizes in general.
  ///
  /// A height off the control ladder (`CoreControlSize.isRung`) is returned
  /// as authored under every density: it is not a row of the ladder, so
  /// there is no rung to move it to. This is the one place that is decided —
  /// Flutter, Web and the Figma exporter read this answer instead of each
  /// testing ladder membership themselves.
  double controlHeight(double px) {
    if (!CoreControlSize.isRung(px)) return px;

    return switch (this) {
      compact => _down(
        CoreControlSize.steps,
        px,
        floor: CoreControlSize.heightSm,
      ),
      standard => px,
      spacious => _up(
        CoreControlSize.steps,
        px,
        from: CoreControlSize.heightXs,
      ),
    };
  }

  /// The corner this density draws where [px] was authored.
  ///
  /// Moves only corners on the band a control row's corner lives on;
  /// smaller corners (a part's 4) and larger ones (a sheet's 24, a pill's
  /// 9999) are not a row's corner and stay.
  double radius(double px) => switch (this) {
    compact => _down(cornerRungs, px, floor: _compactCornerFloor),
    standard => px,
    spacious => _up(cornerRungs, px, from: cornerRungs.first),
  };

  /// The corner of the lowest row [compact] moves — the rung where the row
  /// ladder stops, at the corner ratio.
  static const double _compactCornerFloor =
      CoreControlSize.heightSm * CoreControlSize.cornerRatio;

  /// One rung down [rungs]: the largest rung strictly below [px], never
  /// below [floor]. Values at or below [floor], and values past the top
  /// rung, stay.
  static double _down(List<double> rungs, double px, {required double floor}) {
    if (px <= floor || px > rungs.last) return px;

    var found = floor;
    for (final rung in rungs) {
      if (rung >= px) break;
      if (rung > found) found = rung;
    }

    return found;
  }

  /// One rung up [rungs]: the smallest rung strictly above [px]. Values
  /// below [from], and values at or past the top rung, stay.
  static double _up(List<double> rungs, double px, {required double from}) {
    if (px < from || px >= rungs.last) return px;

    for (final rung in rungs) {
      if (rung > px) return rung;
    }

    return px;
  }
}
