/// Stroke width primitive tokens.
///
/// Ten primitive tokens (`stroke0`–`stroke8`, with the hairline `stroke0_5`
/// between `stroke0` and `stroke1`, the active boundary `stroke1_5` between
/// `stroke1` and `stroke2`, and `stroke5` between `stroke4` and `stroke6`).
/// Applies to all line-shaped UI surfaces (border, divider, focus ring,
/// underline).
abstract final class CoreStrokeWidth {
  const CoreStrokeWidth._();

  /// 0px — no stroke.
  static const double stroke0 = 0;

  /// 0.5px — hairline: one device pixel on a 2x screen.
  ///
  /// The decimal point is written `_` everywhere: a Dart identifier cannot
  /// hold a `.`, and neither can a Figma variable name (`createVariable`
  /// throws "invalid variable name"). So every spelling of this step reads
  /// `0_5` — `stroke0_5`, the Figma variable `stroke/0_5`, and
  /// `--coui-stroke-width-0_5`.
  ///
  /// Below [hairlineMinDevicePixelRatio] both platforms draw it one pixel
  /// wide — the design's choice for a screen where half a logical pixel is a
  /// sub-pixel line, fainter than the colour it is drawn in — and from there
  /// up at its own 0.5, exactly one device pixel on a 2x screen
  /// ([hairlineAt]). Web reads the screen in a media query on
  /// `--coui-stroke-width-0_5`; Flutter folds the screen's ratio into the
  /// theme geometry, which draws every stroke.
  static const double stroke0_5 = 0.5;

  /// The device pixel ratio from which the two steps with half a pixel in
  /// them — the hairline ([stroke0_5]) and the active boundary
  /// ([stroke1_5]) — are drawn at their own width: where a logical pixel is
  /// two device pixels or more, so the half is a whole device pixel.
  static const double hairlineMinDevicePixelRatio = 2;

  /// The width the hairline draws at on a screen of [devicePixelRatio]:
  /// [stroke1] below [hairlineMinDevicePixelRatio], [stroke0_5] from there
  /// up.
  static double hairlineAt(double devicePixelRatio) =>
      devicePixelRatio < hairlineMinDevicePixelRatio ? stroke1 : stroke0_5;

  /// 1px — default stroke. Input/Card border, Divider, Table border.
  static const double stroke1 = 1;

  /// 1.5px — a boundary one step heavier than the default: a selected option
  /// row, the ring around the navigation bar's notification dot, and an
  /// input's active boundary when the caller states a heavier one (the
  /// default active boundary is [stroke1], and so is the checkbox and radio
  /// frame).
  ///
  /// Written `1_5` everywhere for the reason [stroke0_5] gives — the Figma
  /// variable is `stroke/1_5` and the CSS variable `--coui-stroke-width-1_5`.
  ///
  /// Not the keyboard focus ring — that stays `CoreFocusRing.ringWidth` and
  /// draws outside the box.
  ///
  /// Below [hairlineMinDevicePixelRatio] both platforms draw it one pixel
  /// wide ([activeBoundaryAt]): a 1x screen has no half pixel, and Chrome
  /// draws a 1.5 CSS px border there as one whole pixel (measured on a
  /// 1.5 checkbox frame), so a Flutter border drawing the half as a blurred
  /// second row was the one that differed. From a 2x screen up it is its
  /// own 1.5 — exactly three device pixels at 2x. Web reads the screen in a
  /// media query on `--coui-stroke-width-1_5`; Flutter folds the screen's
  /// ratio into the theme geometry, which draws every stroke.
  static const double stroke1_5 = 1.5;

  /// The width the active boundary ([stroke1_5]) draws at on a screen of
  /// [devicePixelRatio]: [stroke1] below [hairlineMinDevicePixelRatio],
  /// [stroke1_5] from there up.
  static double activeBoundaryAt(double devicePixelRatio) =>
      devicePixelRatio < hairlineMinDevicePixelRatio ? stroke1 : stroke1_5;

  /// 2px — emphasized stroke. Selected card, active tab underline.
  static const double stroke2 = 2;

  /// 3px — strong emphasis. Recommended for focus ring.
  static const double stroke3 = 3;

  /// 4px — bold/decorative stroke. Section dividers, accent borders.
  static const double stroke4 = 4;

  /// 5px — the selected ring of the `lg` and `xl` radio buttons, where the
  /// ring leaves a hole of 8 and 10.
  static const double stroke5 = 5;

  /// 6px — strong bold stroke. Strong section emphasis.
  static const double stroke6 = 6;

  /// 8px — maximum stroke. Special decorative use only.
  static const double stroke8 = 8;

  /// Tailwind class name record for compile-safe interpolation.
  ///
  /// Usage: `stroke-${CoreStrokeWidth.scale.stroke1}` → `stroke-stroke1`.
  static const ({
    String stroke0,
    String stroke0_5,
    String stroke1,
    String stroke1_5,
    String stroke2,
    String stroke3,
    String stroke4,
    String stroke5,
    String stroke6,
    String stroke8,
  })
  scale = (
    stroke0: 'stroke0',
    stroke0_5: 'stroke0_5',
    stroke1: 'stroke1',
    stroke1_5: 'stroke1_5',
    stroke2: 'stroke2',
    stroke3: 'stroke3',
    stroke4: 'stroke4',
    stroke5: 'stroke5',
    stroke6: 'stroke6',
    stroke8: 'stroke8',
  );
}
