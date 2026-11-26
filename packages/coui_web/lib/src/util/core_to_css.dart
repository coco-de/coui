/// Conversion utilities from CoUI core platform-neutral types
/// to CSS strings consumed by jaspr `Styles(raw: ...)`.
///
/// Every platform-neutral type exposes `.toValue()` here for Web
/// (returning CSS strings); the Flutter side mirrors this in
/// `coui_flutter/lib/src/util/core_to_flutter.dart`, returning Flutter
/// primitives instead.
///
/// A unified `.toValue()` name means user code and Co\* components
/// have a single mental model regardless of platform.
library;

import 'dart:math' as math;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/util/web_constants.dart';

String _rem(double px) => '${px / kRemDivisor}rem';

/// Maps a corner-radius value (logical px) to a CSS variable when it
/// matches a `CoreRadius` token, or falls back to a `px` literal when
/// it is an arbitrary user override.
///
/// Token-bound values flow through `--coui-radius-*` CSS variables so
/// a designer override (e.g. `--coui-radius-8: 6px;`) is reflected in
/// every component automatically. Arbitrary overrides (e.g.
/// `CoreBorderRadius.all(7)`) are emitted as literal `px` because the
/// caller deliberately chose that value — there is no token slot to
/// match.
/// Maps a corner radius (logical px) to a CSS `border-radius` value.
///
/// The scalar analogue of [strokeWidthCss], for the places that emit one
/// corner rather than a whole [CoreBorderRadius] — a derived pill, an
/// indicator dot. They need the same variable reference, or they are the
/// corners a surface style cannot reach.
String radiusCss(double px) {
  // Exact comparison, not `toInt()`. Truncating made a deliberate 4.7
  // indistinguishable from the radius-4 token and silently emit that
  // token's variable — the opposite of what the comment above promises,
  // and actively harmful once a surface style can move that variable.
  for (final step in kRadiusSteps) {
    if (px == step.value) return 'var(--coui-radius-${step.key})';
  }

  return '${px}px';
}

/// Radius steps that resolve to a `--coui-radius-*` variable.
///
/// Every step on the scale, and the completeness is load-bearing rather
/// than tidy. A step missing here does not lose its variable — it loses
/// the *reference* to it. `radiusCss` falls through to a literal, and a
/// literal is the one thing a surface style cannot move: the preset
/// writes `--coui-radius-48` faithfully and nothing reads it. The
/// component silently opts out of every preset, at the exact corner the
/// caller named.
///
/// That was not hypothetical. This list held nine of the nineteen steps
/// while the theme bent all nineteen, so ten documented `.radiusNN`
/// chain getters — 2, 6, 10, 14, 20, 28, 36, 48, 56, 64 — emitted
/// literals. Under neo-brutalism a `.radius48` chip stayed a pill on Web
/// while its Flutter twin, which bends any value rather than only listed
/// ones, came back as a rounded rect. Under the default style the two
/// agree, because identity geometry makes the literal and the variable
/// the same number — which is why it survived until someone turned a
/// preset on.
///
/// Shared with the theme's variable-writing side rather than duplicated:
/// the two must name the same steps, and two lists that each claim to
/// mirror the other is how they came apart.
const List<({String key, double value})> kRadiusSteps = [
  (key: '0', value: CoreRadius.radius0),
  (key: '2', value: CoreRadius.radius2),
  (key: '4', value: CoreRadius.radius4),
  (key: '6', value: CoreRadius.radius6),
  (key: '8', value: CoreRadius.radius8),
  (key: '10', value: CoreRadius.radius10),
  (key: '12', value: CoreRadius.radius12),
  (key: '14', value: CoreRadius.radius14),
  (key: '16', value: CoreRadius.radius16),
  (key: '20', value: CoreRadius.radius20),
  (key: '24', value: CoreRadius.radius24),
  (key: '28', value: CoreRadius.radius28),
  (key: '32', value: CoreRadius.radius32),
  (key: '36', value: CoreRadius.radius36),
  (key: '40', value: CoreRadius.radius40),
  (key: '48', value: CoreRadius.radius48),
  (key: '56', value: CoreRadius.radius56),
  (key: '64', value: CoreRadius.radius64),
  (key: '9999', value: CoreRadius.radius9999),
];

/// Maps a spacing value (logical px) to a CSS length: a `--coui-space-*`
/// variable when it is a step of the `CoreSpace` scale, or a literal `rem`
/// when it is not.
///
/// The spacing analogue of [radiusCss], for inline `padding` / `margin` /
/// `gap` declarations. A Tailwind spacing class already reads the variable
/// (`p-space16` → `var(--coui-space-16)`); an inline declaration has to
/// name it too, or it is the one place a re-mapped variable — a designer
/// override (`--coui-space-16: 0.875rem;`), a density axis — does not
/// reach. The variables are `rem` themselves, so a step renders exactly
/// the length the literal did and follows the browser's root font size the
/// same way.
///
/// What stays out of reach, by construction: a value off the scale (an
/// arbitrary override, a sum like `16 + 1`) and any negative value are
/// emitted as literals, because no variable carries them. Re-mapping the
/// spacing variables moves every step a component emits and none of these.
/// A length derived from a step — half a gap, an indent times a depth —
/// stays in reach only when the caller keeps the step as an operand
/// (`calc(${spaceCss(gap)} / 2)`) instead of emitting the computed number.
String spaceCss(double px) =>
    CoreSpace.steps.contains(px) ? 'var(--coui-space-${px.toInt()})' : _rem(px);

/// A length (logical px) that rides a spacing property without being
/// spacing, as a literal `rem` — never a `--coui-space-*` variable, even
/// when it equals a step.
///
/// The counterpart of [spaceCss] for a value that belongs to other
/// geometry: a cap taken from a size, a device's safe area, a pull-back that
/// centres a box on half its own width, margins that cancel another box's
/// footprint. Each holds an exact relation to something that does not move
/// with spacing, so a variable would let a designer override or a density
/// axis move one side of that relation and not the other. The same
/// reasoning keeps [pictureStrokeCss] off the stroke-width variables.
///
/// It exists as a converter rather than an inline literal so the reason
/// travels with the conversion — a `'${x / kRemDivisor}rem'` at the call
/// site reads like a missed [spaceCss], and the spacing guard flags it as
/// one. The guard also counts this converter's uses against a ratchet, so a
/// new one is a declared decision rather than a quiet opt-out.
String pinnedLengthCss(double px) => _rem(px);

/// A length already measured in the browser's CSS pixels, including its
/// current text scale. Use only for CSSOM geometry, never authored spacing.
/// Converting it through the design-time rem divisor would scale it twice.
String measuredLengthCss(double cssPixels) => '${cssPixels}px';

/// Maps a stroke-width value (logical px) to a CSS `border-*-width`
/// value: a `--coui-stroke-width-*` variable when it matches a
/// `CoreStrokeWidth` token, or a literal `px` when it is an arbitrary
/// user override.
///
/// Border width is **px-fixed, never rem**: a stroke is a physical
/// hairline, not a layout dimension, so it must not thicken when the
/// user enlarges the browser's root font-size (the axis `rem` responds
/// to). Flutter agrees — its `textScaling` axis reaches typography and
/// icons only, never `borderWidth`. Flutter's `theme.scaling` (platform
/// density) has no Web counterpart, so `rem` cannot mirror it either —
/// `rem` tracks the text axis, not density.
///
/// Token-bound values still flow through the px-valued
/// `--coui-stroke-width-*` variables so a designer override
/// (`--coui-stroke-width-2: 3px;`) reaches every component; arbitrary
/// overrides emit a literal `px` because there is no token slot to
/// match. This mirrors [radiusCss] one-to-one — a CSS-variable
/// *reference*, not a reverse-derived Tailwind scale key, so it is not
/// the forbidden `scaleKeyOf` single-source violation.
///
/// This is the border-width analogue of [CoreBorderRadiusToCss.toValue]
/// / [CoreEdgeInsetsToCss.toValue]. A stroke width has no wrapping
/// domain type (it is a raw `double`), so the converter is a free
/// function rather than a method.
String strokeWidthCss(double px) {
  final n = px.toInt();
  if (px == CoreStrokeWidth.stroke0) return 'var(--coui-stroke-width-0)';
  if (px == CoreStrokeWidth.stroke0_5) return 'var(--coui-stroke-width-0_5)';
  if (px == CoreStrokeWidth.stroke1) return 'var(--coui-stroke-width-1)';
  if (px == CoreStrokeWidth.stroke1_5) return 'var(--coui-stroke-width-1_5)';
  if (px == CoreStrokeWidth.stroke2) return 'var(--coui-stroke-width-2)';
  if (px == CoreStrokeWidth.stroke3) return 'var(--coui-stroke-width-3)';
  if (px == CoreStrokeWidth.stroke4) return 'var(--coui-stroke-width-4)';
  if (px == CoreStrokeWidth.stroke5) return 'var(--coui-stroke-width-5)';
  if (px == CoreStrokeWidth.stroke6) return 'var(--coui-stroke-width-6)';
  if (px == CoreStrokeWidth.stroke8) return 'var(--coui-stroke-width-8)';
  // Integer-valued arbitrary overrides render without a trailing `.0`.
  return px == n ? '${n}px' : '${px}px';
}

/// The width an active boundary adds beyond the resting border, as a CSS
/// length for the spread of an inset `box-shadow` — or `null` when it adds
/// nothing ([active] is no wider than [rest]).
///
/// A focused / errored input keeps its resting `border` in the layout and
/// draws only the difference as an inset shadow, so the content does not move
/// when the boundary widens (and the border stays for forced-colours mode,
/// which recolours borders but draws no shadows). Both widths go through
/// [strokeWidthCss], so a style preset's stroke floor — which moves the
/// `--coui-stroke-width-*` variables — lifts both to one width and the
/// difference reads 0; `max(0px, …)` keeps it from turning negative and
/// drawing inward.
String? activeBoundaryInsetCss({required double rest, required double active}) {
  if (active <= rest) return null;
  return 'max(0px, calc(${strokeWidthCss(active)} - ${strokeWidthCss(rest)}))';
}

/// The inset `box-shadow` layer an active boundary is drawn with — [inset]
/// (from [activeBoundaryInsetCss]) in [color] — or `null` when there is
/// nothing to draw: the active width adds nothing, or [color] paints
/// nothing (a chromeless composition states a transparent boundary).
///
/// The one shape of the layer for both halves of both inputs — the error
/// boundary drawn inline and the focused one published on
/// [kActiveBoundaryVar] — so the two cannot drift apart.
String? activeBoundaryLayerCss({
  required String? inset,
  required CoreColor color,
}) => inset == null || color.paintsNothing
    ? null
    : 'inset 0 0 0 $inset ${color.toValue()}';

/// A stroke width (logical px) of a drawn picture as a literal CSS `px`
/// length, px-fixed like [strokeWidthCss] but never a stroke-width variable.
///
/// A surface style's stroke floor moves `--coui-stroke-width-*`; a stroke
/// that is part of a picture (a hardware rim, a battery outline) is light
/// on an edge rather than a boundary border, so a width that happens to
/// equal a step must not be thickened with it.
String pictureStrokeCss(double px) {
  final n = px.toInt();

  return px == n ? '${n}px' : '${px}px';
}

/// The declarations that draw a [CoreSurfaceEdgeSheen] as four gradient
/// runs, keyed by CSS property.
///
/// Four background layers rather than a border: a border cannot hold two
/// colours and a per-run fade at once, and this treatment's whole point
/// is that the horizontal runs disagree with the vertical ones. Each
/// layer is sized to one edge and positioned against it, so the same
/// declaration serves an element of any size — which is what lets the
/// sheen live on a theme axis at all.
///
/// The stop positions come from `effectiveFade`, not the raw `fade`, so
/// an out-of-range theme means the same thing here as it does in the
/// Flutter painter. Returning a map rather than a rule string keeps the
/// caller in charge of the selector — the band is drawn on a
/// pseudo-element whose other declarations belong to that caller.
Map<String, String> surfaceEdgeSheenCss(CoreSurfaceEdgeSheen sheen) {
  final light = sheen.lightColor.toValue();
  final dark = sheen.darkColor.toValue();
  final band = strokeWidthCss(sheen.width);
  final start = (sheen.effectiveFade * kPercentScale).toStringAsFixed(2);
  final end = ((1 - sheen.effectiveFade) * kPercentScale).toStringAsFixed(2);

  String run(String direction, String color) =>
      'linear-gradient(to $direction,transparent,'
      '$color $start%,$color $end%,transparent)';

  return {
    // Order is layer order: the two horizontal runs are declared first
    // and therefore paint over the vertical ones where they overlap at a
    // corner. Both are transparent there, so the choice is not visible —
    // it is fixed only so the two platforms cannot drift apart on it.
    'background-image':
        '${run('right', light)},${run('right', light)},'
        '${run('bottom', dark)},${run('bottom', dark)}',
    'background-size': '100% $band,100% $band,$band 100%,$band 100%',
    'background-position': 'top left,bottom left,top left,top right',
    'background-repeat': 'no-repeat',
  };
}

/// The rim's sweep around one element, as a `conic-gradient`.
///
/// The stops are Core's — `CoreSurfaceEdgeBevel.rimSweep`, the same call
/// the Flutter painter makes for the same box — so the peak lands on the
/// same arc on both platforms by construction. This only spells them in
/// CSS: `from 0deg` starts at the top and runs clockwise, which is the
/// convention the stops are stated in, so no angle is converted here.
///
/// The colour is the highlight variable at each stop's opacity, so the
/// rim follows a theme switch the way the wall does.
String surfaceEdgeRimSweepCss(
  CoreSurfaceEdgeBevel bevel, {
  required double width,
  required double height,
  required double radius,
}) {
  final stops = bevel.rimSweep(width: width, height: height, radius: radius);
  if (stops.isEmpty) return 'none';

  final buffer = StringBuffer('conic-gradient(from 0deg at 50% 50%');
  for (final stop in stops) {
    final pct = (stop.alpha * kPercentScale).toStringAsFixed(1);
    final deg = stop.angle.toStringAsFixed(2);
    buffer.write(',rgb(var(--coui-surface-highlight) / $pct%) ${deg}deg');
  }
  buffer.write(')');

  return buffer.toString();
}

/// Maps a duration (milliseconds) to a CSS `transition-duration` /
/// `animation-duration` value: a `--coui-duration-*` variable when [ms]
/// matches one of `CoreDuration`'s scale steps. An arbitrary transition-tier
/// value uses a media-controlled factor; display-tier values stay literal.
///
/// The media query in `theme_config.dart` zeroes transition-tier token
/// variables. The factor brings arbitrary transition durations under the same
/// Core policy without changing their normal duration or suppressing
/// display-tier timing.
String durationMsCss(int ms) {
  const steps = [
    CoreDuration.ms0,
    CoreDuration.ms50,
    CoreDuration.ms100,
    CoreDuration.ms150,
    CoreDuration.ms200,
    CoreDuration.ms250,
    CoreDuration.ms300,
    CoreDuration.ms350,
    CoreDuration.ms400,
    CoreDuration.ms450,
    CoreDuration.ms500,
    CoreDuration.ms1000,
    CoreDuration.ms2000,
    CoreDuration.ms3000,
    CoreDuration.ms4000,
    CoreDuration.ms5000,
    CoreDuration.indeterminate,
  ];
  if (steps.contains(ms)) return 'var(--coui-duration-$ms)';
  if (CoreReducedMotion.isTransitionMotion(Duration(milliseconds: ms))) {
    return 'calc(${ms}ms * var($kTransitionMotionFactorVar, 1))';
  }
  return '${ms}ms';
}

/// SVG viewBox user unit → CSS length.
///
/// Geometry inside an `<svg>` with a fixed `viewBox` lives in *user units*,
/// not in reader-scaled lengths. `rem` would rescale such a value with the
/// root font size and desync it from the viewBox the path was drawn in, so
/// `px` is the correct unit here — the same reasoning that makes
/// [strokeWidthCss] px-fixed rather than rem.
///
/// This exists as a converter rather than an inline string so the reason
/// travels with the conversion: a `'${x}px'` literal written at a call site
/// reads like an accessibility-scaling bypass and the token guard flags it as
/// one. Reach for this only for geometry measured in viewBox units.
String svgUserUnitCss(double units) {
  final n = units.toInt();
  return units == n ? '${n}px' : '${units.toStringAsFixed(2)}px';
}

/// A length the browser measured, in CSS pixels → CSS length.
///
/// A value read back from layout (`clientHeight`, `scrollHeight`, a thumb
/// position derived from them) is already in the unit the page is laid out
/// in, so it goes back in as `px`. `rem` would rescale it by the root font
/// size and put it a few pixels off the box it was measured against — the
/// same reason [strokeWidthCss] and [svgUserUnitCss] are px-fixed. This is a
/// converter rather than an inline string so the reason travels with it: a
/// `'${x}px'` literal at a call site reads like an accessibility-scaling
/// bypass and the token guard flags it as one.
///
/// Reach for this only for geometry measured from the DOM. A length the
/// design states is spacing or size, and goes through [spaceCss] /
/// [pinnedLengthCss].
String measuredPxCss(double px) {
  final n = px.round();
  return (px - n).abs() < 0.005 ? '${n}px' : '${px.toStringAsFixed(2)}px';
}

/// CoreColor → CSS color string.
///
/// Tagged tokens (e.g. `scheme.primary`) emit `rgb(var(--coui-X))` so
/// daisyUI / dark-mode auto-switching keeps working in the browser. The
/// `--coui-X` custom properties hold a bare `R G B` triplet (e.g.
/// `--coui-primary: 66 115 215`), so they must be wrapped in `rgb(...)`
/// to form a valid CSS colour; an opacity modifier becomes the rgb
/// slash-alpha (`rgb(var(--coui-X) / NN%)`). Raw ARGB colours emit
/// `rgb(...)` / `rgba(...)`.
///
/// (Earlier this emitted `var(--color-X)`, but no `--color-*` variable
/// is ever defined — only `--coui-*` — so inline token colours rendered
/// transparent. Tailwind class composition keeps working because the
/// Tailwind config maps the token name to `rgb(var(--coui-X))`.)
///
/// For Tailwind class composition (`'bg-${cs.primary}'`), use Dart
/// string interpolation directly — [CoreColor.toString] returns the
/// token name (`'primary'`, `'on-surface/60'`).
extension CoreColorToCss on CoreColor {
  /// Returns the CSS colour value (for `Styles.raw` / inline `style`).
  String toValue() {
    final tok = token;
    if (tok != null) {
      final base = 'var(--coui-${tok.name})';
      if (opacity < 1.0) {
        final pct = (opacity * 100).toInt();
        return 'rgb($base / $pct%)';
      }
      return 'rgb($base)';
    }
    return toRgba();
  }
}

/// CoreGradient → CSS `linear-gradient(...)` / `radial-gradient(...)`.
///
/// The segments of a viewport a fold splits, as CSS reads them.
extension CoreFoldLayoutToCss on CoreFoldLayout {
  /// The browser's own measure of segment [index]'s [edge] — `left`, `top`,
  /// `width` or `height` — as `env(viewport-segment-<edge> <column> <row>)`.
  ///
  /// The browser numbers segments by column and row; [segments] lists them
  /// left to right and top to bottom, so a segment's column is how many
  /// distinct left edges lie before it, and its row how many top edges do.
  /// The geometry is the browser's, so a panel placed by it follows the fold
  /// exactly whatever the root font size; only which segment is decided by
  /// the rule.
  String segmentEnvCss(int index, String edge) {
    final segment = segments[index];
    final column = {
      for (final other in segments)
        if (other.left < segment.left) other.left,
    }.length;
    final row = {
      for (final other in segments)
        if (other.top < segment.top) other.top,
    }.length;

    return 'env(viewport-segment-$edge $column $row)';
  }
}

/// The one adapter every Web surface that paints a [CoreGradient] reads, so
/// a gradient means the same thing on `Frame`, `OutlinedContainer` and
/// `MockupDevice` — and the same thing as the Flutter adapter that turns it
/// into a `LinearGradient` / `RadialGradient`.
extension CoreGradientToCss on CoreGradient {
  /// Returns the CSS gradient value (for `background-image`).
  ///
  /// - **linear** — the angle runs from [CoreGradient.begin] to
  ///   [CoreGradient.end] (CSS `0deg` points up and grows clockwise, while
  ///   [CoreAlignment.y] grows downward). Exact for the axis-aligned
  ///   directions every authored gradient uses, where the CSS gradient line
  ///   spans the whole box the way Flutter's does.
  /// - **radial** — a circle centred on the box that reaches the nearest side
  ///   (`closest-side`), which is what Flutter's `RadialGradient` draws at
  ///   its default centre and radius (half the shortest side). A radial
  ///   gradient ignores [CoreGradient.begin], as the contract states: CSS's
  ///   default, `farthest-corner`, would stretch the gradient past the box
  ///   and leave the last stops unseen, and an off-centre `closest-side` has
  ///   no radius at all.
  ///
  /// Stop positions are written to two decimals in percent, trailing zeros
  /// dropped, so an authored `0.51` stays `51%` and `0.5` stays `50%`.
  String toValue() {
    final stopList = StringBuffer();
    for (var i = 0; i < colors.length; i += 1) {
      if (i > 0) stopList.write(', ');
      stopList.write(colors[i].toValue());
      final positions = stops;
      if (positions != null && i < positions.length) {
        stopList.write(' ${_percent(positions[i])}%');
      }
    }
    switch (type) {
      case .linear:
        final dx = end.x - begin.x;
        final dy = end.y - begin.y;
        final radians = math.atan2(dx, -dy);
        final angle = (radians * _kDegreesPerHalfTurn / math.pi).round();
        return 'linear-gradient(${angle}deg, $stopList)';
      case .radial:
        return 'radial-gradient(circle closest-side at 50% 50%, $stopList)';
    }
  }
}

/// Half a turn in degrees — the `radians * 180 / pi` of the angle conversion.
/// Not a design token: pure unit conversion.
const double _kDegreesPerHalfTurn = 180;

/// A `0..1` fraction as a percentage number — two decimals, trailing zeros
/// dropped (`0.51` → `51`, `0.125` → `12.5`).
String _percent(double fraction) => (fraction * kPercentScale)
    .toStringAsFixed(2)
    .replaceFirst(
      RegExp(r'\.?0+$'),
      '',
    );

/// Tailwind class-name reference for a [CoreColor] token.
///
/// `bg-${color.tailwindColor}` and friends compose left-to-right with
/// the rest of this file's extension chain
/// (`CoreBorderRadius.tailwindRadius`, `CoreSpaceValue.tailwindSpace` …)
/// so platform style files use the same getter shape for every Core →
/// Tailwind conversion.
extension CoreColorTailwind on CoreColor {
  /// Renders this colour's token reference as the suffix consumed by
  /// Tailwind colour classes (`bg-{X}` / `text-{X}` / `border-{X}` …).
  ///
  /// Appends `/<pct>` (Tailwind's opacity modifier) when the colour
  /// carries an alpha below 1.
  ///
  /// Throws if the colour has no token reference — call [isTransparent]
  /// first when handling raw transparent sentinels.
  String get tailwindColor {
    final t = token!.name;
    final pct = (opacity * kPercentScale).toInt();
    return opacity < 1.0 ? '$t/$pct' : t;
  }

  /// `true` when this is the raw transparent sentinel (no token
  /// reference, ARGB 0). Web treats this as "no Tailwind class" — the
  /// background / border class is omitted entirely.
  ///
  /// This is "has no TOKEN", not "paints nothing": every raw colour reads
  /// `true`, a raw green included. Ask [paintsNothing] when the question is
  /// whether anything would be drawn.
  bool get isTransparent => token == null;

  /// `true` when drawing this colour leaves no mark: a zero [opacity], or a
  /// raw colour whose alpha byte is zero (the `CoreColor.transparent`
  /// sentinel). A token carries its colour at resolve time, so only a zero
  /// opacity makes one paint nothing.
  ///
  /// What a chromeless composition states for the boundary it hands to the
  /// frame around it — there is no boundary left to widen.
  bool get paintsNothing => opacity == 0 || (token == null && alpha == 0);
}

/// The inline declarations a surface publishes so a style preset can
/// restate its fill at a different alpha.
///
/// One function rather than a line repeated at each surface: the preset
/// side reads these custom properties, and a surface that spelled them
/// differently would silently opt out of every material style.
///
/// The triplet goes out bare, and the token's own alpha goes out beside it
/// ([kWebSurfaceFillAlphaVar]) whenever the token states one below 1. The
/// preset multiplies the two — a 10% tint under a 50% share paints at 5%,
/// the same `token alpha × share` the Flutter twin folds. An opaque fill
/// publishes no alpha and reads the reset every marked surface carries.
///
/// Empty when the fill is not token-bound. A caller who stated a raw
/// colour stated it — a preset restating it would be overruling an
/// explicit choice rather than giving a surface its material.
Map<String, String> surfaceFillVar(CoreColor fill) {
  final token = fill.token;
  if (token == null) return const {};

  return {
    kWebSurfaceFillVar: 'var(--coui-${token.name})',
    if (fill.opacity < 1) kWebSurfaceFillAlphaVar: _fraction(fill.opacity),
  };
}

/// The border a marked surface keeps, published so the material's edge band
/// reaches over it ([kWebSurfaceBleedVar]).
///
/// [borderWidth] is the surface's own `border-width` as CSS (a token routes
/// through its stroke variable, so a stroke-bending preset moves both
/// together). A surface that draws no border states nothing — the band's
/// default already sits on its outer edge.
///
/// One function for the same reason [surfaceFillVar] is: the stylesheet
/// reads one custom property, and a surface that spelled it differently
/// would leave the band a border inside its box.
Map<String, String> surfaceBleedVar(String borderWidth) => {
  kWebSurfaceBleedVar: borderWidth,
};

/// The border a marked surface keeps on its top edge only, published so the
/// band reaches over that line ([kWebSurfaceBleedTopVar]).
///
/// For a docked bar, whose hairline faces the content it separates from: the
/// other three edges have no border to skip, so they keep the box's own edge.
Map<String, String> surfaceBleedTopVar(String borderWidth) => {
  kWebSurfaceBleedTopVar: borderWidth,
};

/// The border a marked surface keeps on its bottom edge only, published so
/// the band reaches over that line ([kWebSurfaceBleedBottomVar]).
///
/// For a surface that closes with a rule — a banner, an app bar's header: the
/// other three edges have no border to skip, so they keep the box's own edge.
Map<String, String> surfaceBleedBottomVar(String borderWidth) => {
  kWebSurfaceBleedBottomVar: borderWidth,
};

/// The declarations a surface that clips its own content and keeps a border of
/// [borderWidth] states so a material that draws its own edge can fold the
/// border into the padding: the `border-style` through
/// [kWebSurfaceEdgeStyleVar], and the padding it owes when that border is
/// folded ([kWebSurfaceClipPadVar]) — zero until then, [borderWidth] after.
///
/// Pair it with [kWebSurfaceClipMarker] on the same element, and with a padding
/// that adds the owed padding
/// ([CoreEdgeInsetsClipPadToCss.toDeclarationsWithClipPad]) or leaves it to the
/// stylesheet. Its `border-width` is the plain one: the width does not change,
/// the style does.
Map<String, String> surfaceClipFold(String borderWidth) => {
  'border-style': 'var($kWebSurfaceEdgeStyleVar,solid)',
  kWebSurfaceClipPadVar: 'calc($borderWidth * var($kWebSurfaceFoldVar,0))',
};

/// [borderWidth] less what a folded border hands to the padding: the border a
/// clipping surface actually keeps, for a box whose padding is measured from
/// its outer edge ([CoreEdgeInsetsToCss.toDeclarationsWithinBorder]).
String surfaceClipKeptBorder(String borderWidth) =>
    'calc($borderWidth - var($kWebSurfaceClipPadVar,0px))';

/// The class form of [surfaceFillVar], for a fill that only a pseudo-state
/// paints (`hover:`, `disabled:`, `[aria-selected]` …) — those have no
/// per-state inline style, only a class. Tailwind arbitrary properties, one
/// per custom property, each prefixed with [pseudo] (empty = the rest state).
///
/// A pseudo-state publishes its alpha even when it is 1. Its classes win over
/// the rest state's while the state holds, and a rest fill that stated a
/// lower alpha would otherwise leak into a state whose fill is opaque.
///
/// Empty for a raw (token-less) colour, for the same reason [surfaceFillVar]
/// is.
List<String> surfaceFillClasses(CoreColor fill, {String pseudo = ''}) {
  final declarations = surfaceFillVar(fill);
  final triplet = declarations[kWebSurfaceFillVar];
  if (triplet == null) return const [];
  final alpha =
      declarations[kWebSurfaceFillAlphaVar] ??
      (pseudo.isEmpty ? null : _fraction(1));

  return [
    '$pseudo[$kWebSurfaceFillVar:$triplet]',
    if (alpha != null) '$pseudo[$kWebSurfaceFillAlphaVar:$alpha]',
  ];
}

/// Whether [fill] paints anything — the question the surface material hangs
/// on, because the material is a statement about a filled box.
///
/// `CoreColor.alpha` is off limits here: it throws on an unresolved token,
/// and on Web every token colour is unresolved by design (the browser
/// resolves it). So it reads the two ways a fill can be absent — the opacity
/// multiplier zeroed (a token stated at opacity 0), or a raw colour whose
/// own alpha is zero (the `transparent` sentinel).
bool surfacePaintsFill(CoreColor fill) =>
    fill.opacity > 0 &&
    (fill.token != null || (fill.argb >> _kAlphaShift) & _kByteMask > 0);

/// The bit offset of the alpha byte in a packed `0xAARRGGBB` colour.
/// Not a design token: pure channel arithmetic.
const int _kAlphaShift = 24;

/// One byte's mask. Not a design token: pure channel arithmetic.
const int _kByteMask = 0xFF;

/// A `0..1` fraction as a CSS number — four decimals, trailing zeros dropped
/// (`0.1` → `0.1`, `0.125` → `0.125`, `1` → `1`, `0` → `0`).
String _fraction(double value) =>
    value.toStringAsFixed(4).replaceFirst(RegExp(r'\.?0+$'), '');

/// CoreEdgeInsets → CSS `padding` / `margin` shorthand.
///
/// Every side goes through [spaceCss]: a side on the `CoreSpace` scale
/// becomes its `--coui-space-*` variable, an off-scale side a literal `rem`.
extension CoreEdgeInsetsToCss on CoreEdgeInsets {
  /// Returns CSS shorthand: `top right bottom left`.
  ///
  /// Throws on a directional value rather than flattening it — the
  /// shorthand has no logical form, so emitting it would be correct in a
  /// left-to-right locale and wrong in a right-to-left one with nothing
  /// to see in between. Use [toLogicalDeclarations] instead.
  String toValue() {
    if (isDirectional) {
      throw ArgumentError(
        'Directional insets have no shorthand — `padding` is physical by '
        'construction. Use toLogicalDeclarations().',
      );
    }

    return '${spaceCss(top)} ${spaceCss(right)} '
        '${spaceCss(bottom)} ${spaceCss(left)}';
  }

  /// Returns the declarations for [property], using logical sides when
  /// the value is directional.
  ///
  /// `padding-inline-start` resolves against the element's `dir`, so the
  /// browser does the mirroring — the same mechanism the Flutter twin
  /// gets from `EdgeInsetsDirectional`. The root now carries `dir` from
  /// the active locale, so this reaches the page.
  ///
  /// Longhands rather than the shorthand because the shorthand is
  /// physical by construction: `padding: a b c d` has no logical
  /// spelling. Kept separate from [toValue] so the ~100 symmetric
  /// emissions — direction-invariant already — keep the one-line
  /// shorthand they have.
  Map<String, String> toLogicalDeclarations(String property) => isDirectional
      ? {
          '$property-block-start': spaceCss(top),
          '$property-block-end': spaceCss(bottom),
          '$property-inline-start': spaceCss(start),
          '$property-inline-end': spaceCss(end),
        }
      : {property: toValue()};

  /// [toLogicalDeclarations] for a box whose inset is measured from its
  /// outer edge, border included: each side is `calc(<side> - <border>)`.
  ///
  /// A CSS `border` sits outside the padding, so a panel that states a
  /// padding of 6 and a border of 1 stands 7 from its edge to its content.
  /// Flutter's `DecoratedBox` paints the border over the padding instead, and
  /// the composed panels the design states (a menu's rows 6 in from the
  /// edge, the editor's selection toolbar 40 tall) are measured that way.
  /// Taking the border out of the padding keeps the border drawn and the
  /// box the size the padding says. A side narrower than the border clamps
  /// to zero — the content then starts at the border, never inside it.
  ///
  /// [border] is a CSS length — [strokeWidthCss] of the border's width, so a
  /// stroke variable still reaches it.
  Map<String, String> toDeclarationsWithinBorder(
    String property,
    String border,
  ) {
    String inside(double side) => 'calc(${spaceCss(side)} - $border)';

    return isDirectional
        ? {
            '$property-block-start': inside(top),
            '$property-block-end': inside(bottom),
            '$property-inline-start': inside(start),
            '$property-inline-end': inside(end),
          }
        : {
            property:
                '${inside(top)} ${inside(right)} '
                '${inside(bottom)} ${inside(left)}',
          };
  }
}

/// The padding a clipping surface owes a folded border, read where it is added.
/// It is stated inline beside the surface's `border-style`, so the fallback is
/// only there to keep a declaration valid; zero is the zero step.
String _clipPadOwed() => 'var($kWebSurfaceClipPadVar,${spaceCss(0)})';

/// [CoreEdgeInsetsToCss] for a surface that clips its own content and keeps a
/// border: each side is `calc(<side> + var(--coui-surface-clip-pad, 0px))`, so
/// the padding grows by exactly what a folded border gives up.
extension CoreEdgeInsetsClipPadToCss on CoreEdgeInsets {
  /// [toLogicalDeclarations] with the clip padding added to every side.
  Map<String, String> toDeclarationsWithClipPad(String property) {
    String padded(double side) => 'calc(${spaceCss(side)} + ${_clipPadOwed()})';

    if (isDirectional) {
      return {
        '$property-block-start': padded(top),
        '$property-block-end': padded(bottom),
        '$property-inline-start': padded(start),
        '$property-inline-end': padded(end),
      };
    }

    // One value for a uniform inset, as the plain shorthand states it.
    if (top == right && top == bottom && top == left) {
      return {property: padded(top)};
    }

    return {
      property:
          '${padded(top)} ${padded(right)} '
          '${padded(bottom)} ${padded(left)}',
    };
  }
}

/// CoreBorderRadius → CSS `border-radius` shorthand.
extension CoreBorderRadiusToCss on CoreBorderRadius {
  /// Returns CSS shorthand: `topLeft topRight bottomRight bottomLeft`.
  ///
  /// Token-bound corners emit `var(--coui-radius-N)` so designer
  /// overrides flow through; arbitrary user overrides emit `px`. See
  /// [radiusCss] for the policy.
  String toValue() =>
      '${radiusCss(topLeft)} ${radiusCss(topRight)} '
      '${radiusCss(bottomRight)} ${radiusCss(bottomLeft)}';

  /// Returns a single uniform `rem` value from the top-left corner —
  /// for caret / cursor radius where CSS expects one scalar (rem escape
  /// hatch for the runtime override value). Assumes the four corners are
  /// equal (uniform caret radius).
  String get uniformRem => _rem(topLeft);

  /// Returns the CSS `border-radius` shorthand for a box that wraps the
  /// shape this radius describes with a border [outset] (logical px) thick
  /// on every side, so the *inside* of that border keeps this radius.
  ///
  /// A border's inner edge is the outer radius minus the border width, so
  /// an element that draws its shape on the padding box (`background-clip:
  /// padding-box` inside a transparent border) has to ask for the radius
  /// plus the border to show the radius it means. Without it a 4px corner
  /// wrapped by a 2px border is drawn at 2px.
  ///
  /// Each corner stays a `var(--coui-radius-N)` reference when it is on the
  /// scale — the growth is added to the reference with `calc()`, so a
  /// designer override of the variable still reaches the corner. The
  /// [outset] is `rem`, like the border it describes.
  String outsetValue(double outset) {
    final growth = _rem(outset);
    return 'calc(${radiusCss(topLeft)} + $growth) '
        'calc(${radiusCss(topRight)} + $growth) '
        'calc(${radiusCss(bottomRight)} + $growth) '
        'calc(${radiusCss(bottomLeft)} + $growth)';
  }

  /// Returns the CSS `border-radius` shorthand for a shape drawn on the
  /// inside of a [border] (a CSS length — [strokeWidthCss] of the border's
  /// width) around a box with this radius: each corner less the border,
  /// clamped at 0, so the shape is concentric with the border's inner curve.
  ///
  /// The mirror of [outsetValue]. Each corner stays a `var(--coui-radius-N)`
  /// reference when it is on the scale and the border stays its stroke
  /// variable, so a designer override, a hairline screen and a style's
  /// stroke floor all reach the corner.
  String insideBorderValue(String border) {
    String inside(double r) => 'max(0px, calc(${radiusCss(r)} - $border))';
    return '${inside(topLeft)} ${inside(topRight)} '
        '${inside(bottomRight)} ${inside(bottomLeft)}';
  }

  /// Returns the CSS shorthand for the two **top** corners shrunk by
  /// [borderWidth] (clamped at 0), with the bottom corners zeroed.
  ///
  /// Used by the window-panel title bar where the inner background must
  /// follow the rounded inner edge of the outer frame (outer corner −
  /// container border width) instead of spilling onto the border. The
  /// corner reach-in stays inside this single CSS util so resolvers
  /// compose `merged.borderRadius.innerTopValue(borderWidth)` with no
  /// per-corner reach-in of their own. Mirrors Flutter
  /// `WindowPanel._innerTopRadius`.
  String innerTopValue(double borderWidth) {
    double shrink(double r) => r - borderWidth < 0 ? 0 : r - borderWidth;
    return CoreBorderRadius.only(
      topLeft: shrink(topLeft),
      topRight: shrink(topRight),
    ).toValue();
  }

  /// Returns the CSS `border-radius` shorthand with the corner pair
  /// docked against the viewport edge named by [flushEdge] zeroed and
  /// the viewport-facing pair kept.
  ///
  /// Used by edge-anchored overlay panels (drawer / swiper) where the
  /// docked edge sits flush with the viewport so its corners must be
  /// square. The corner reach-in stays inside this single CSS util so
  /// resolvers compose `merged.borderRadius.edgeFlushValue(edge)` with no
  /// per-corner reach-in of their own. [flushEdge] is one of `top`,
  /// `bottom`, `left`, `right`.
  String edgeFlushValue(String flushEdge) {
    final flushed = switch (flushEdge) {
      'left' => CoreBorderRadius.only(
        topRight: topRight,
        bottomRight: bottomRight,
      ),
      'right' => CoreBorderRadius.only(
        topLeft: topLeft,
        bottomLeft: bottomLeft,
      ),
      'top' => CoreBorderRadius.only(
        bottomLeft: bottomLeft,
        bottomRight: bottomRight,
      ),
      _ => CoreBorderRadius.only(
        topLeft: topLeft,
        topRight: topRight,
      ),
    };
    return flushed.toValue();
  }

  /// Returns the CSS `border-radius` shorthand selecting each corner
  /// from [tight] (when the matching `*Tight` flag is true) or from this
  /// radius (loose) otherwise.
  ///
  /// Used by the window snap-bar tiles where a corner abutting a sibling
  /// tile gets the tight field radius and an outer corner gets the loose
  /// banner radius. Keeping the per-corner reach-in inside this single
  /// CSS util means snap resolvers compose
  /// `loose.pickCornersValue(tight: tight, …)` with no per-corner
  /// reach-in of their own.
  String pickCornersValue({
    required CoreBorderRadius tight,
    required bool topLeftTight,
    required bool topRightTight,
    required bool bottomLeftTight,
    required bool bottomRightTight,
  }) => CoreBorderRadius.only(
    topLeft: topLeftTight ? tight.topLeft : topLeft,
    topRight: topRightTight ? tight.topRight : topRight,
    bottomLeft: bottomLeftTight ? tight.bottomLeft : bottomLeft,
    bottomRight: bottomRightTight ? tight.bottomRight : bottomRight,
  ).toValue();
}

/// The base every `--shadow-*` variable is baked with.
///
/// A stack can only be routed to one of those variables if it would have
/// been tinted the same way, so this is the value that decides it. Every
/// component's shadow tint now comes from the palette's `shadow` token, so
/// in practice they all qualify — but a caller that overrides the tint per
/// instance does not, and gets a literal.
const String kShadowVariableBase = 'rgb(var(--coui-shadow))';

/// The custom property that multiplies every cast layer's alpha — the Web
/// transport of the theme's brightness for shadows.
///
/// The dark blocks set it to `CoreShadow.darkStrength`; nothing else
/// writes it, so a light page reads the fallback 1 and a style's bent
/// stacks (re-pointed `--shadow-*`) are strengthened by the same rule as
/// the plain ones. It is read inside the layer's colour term rather than
/// by re-declaring `--shadow-*` per brightness, which is what lets it
/// reach a stack baked into a literal too — the same reach the Flutter
/// seat has (`CoreSurfaceGeometryConstraint.shadow`).
const String kShadowStrengthVariable = '--coui-shadow-strength';

/// The surface-style inset rim, as a `box-shadow` layer.
///
/// Always resolves — the base stylesheet declares it as a layer that
/// renders nothing, so a surface can name it unconditionally. An
/// undefined custom property would invalidate the whole declaration and
/// take the cast shadow with it.
///
/// Naming it is how a surface opts in. The rim is derived from the page
/// surface, so it belongs on things filled with that surface — panels —
/// and not on controls, whose fill is the opposite token.
const String kSurfaceRimVar = 'var(--coui-surface-rim)';

/// The shadow a surface style contributes to a control that casts none —
/// the shadow counterpart of [kSurfaceRimVar].
///
/// Always resolves — the base stylesheet declares it as a layer that
/// renders nothing, so a control can reference it unconditionally as
/// part of its `box-shadow`. Only a style with a non-empty
/// `CoreSurfaceGeometryConstraint.controlShadow` (neo-brutalism) resolves
/// it to something visible.
const String kControlShadowVar = 'var(--coui-control-shadow)';

/// The same shape as [kControlShadowVar], every layer's colour forced to
/// zero alpha — [CoreCastMotion.reverse]'s rest value.
///
/// A `reverse` control casts nothing at rest and grows the cast on
/// engage, which means the `box-shadow` transition runs from this value
/// to [kControlShadowVar]. Transitioning from the literal keyword `none`
/// instead risks a browser padding the shorter (zero-layer) side with a
/// UA-default colour rather than a transparent copy of the longer side's
/// own shape — measured, it flashes black mid-transition
/// (`process/verify.md` §7-24). Matching layer count, offset, blur and
/// spread here — differing only in colour alpha — keeps the transition a
/// pure colour interpolation, the same reasoning the focus-ring rules
/// elsewhere in this file already rely on.
///
/// Always resolves for the identical reason [kControlShadowVar] does —
/// declared unconditionally in the base stylesheet as the same
/// "renders nothing" layer, so a control can reference it whether or
/// not the active style states a `controlShadow` at all.
const String kControlShadowGhostVar = 'var(--coui-control-shadow-ghost)';

/// The CSS `box-shadow` value for a stack, through a variable when it can be.
///
/// A surface style bends shadow geometry by re-pointing `--shadow-*`, which
/// only reaches a component whose shadow resolves through those variables.
/// Baking the layers into a literal instead — which is what happens to any
/// stack that is not one of the scale steps — quietly opts that component
/// out of every preset, and the result reads as "this one component didn't
/// change" rather than as a missing indirection.
///
/// The same shape as [strokeWidthCss] and the colour emitters: a value on
/// the scale becomes a variable reference, anything else becomes a literal.
///
/// [strengthens] false leaves [kShadowStrengthVariable] out of every layer's
/// colour, so the dark scope draws the stack at the alpha it states. The
/// `--shadow-*` variables carry the strength inside them, so such a stack is
/// always written as its literal layers.
String emitShadow(
  List<CoreShadowLayer> layers, {
  required String base,
  bool strengthens = true,
}) {
  if (layers.isEmpty) return 'none';
  if (strengthens && base == kShadowVariableBase) {
    final key = _shadowScaleKey(layers);
    if (key != null) return 'var(--shadow-$key)';
  }

  return layers.toValue(base: base, strengthens: strengthens);
}

/// The CSS `filter: drop-shadow()` counterpart of [emitShadow], through
/// the matching `--shadow-*-filter` variable when it can be.
///
/// A stack with no inset layer casts through `filter` rather than
/// `box-shadow` so the shadow follows the child's rendered shape instead
/// of the wrapper's square border-box (`Hover`'s `shadow` effect is the
/// caller). Baking the layers into a `drop-shadow(...)` literal — which
/// [CoreShadowLayersToCss.toDropShadowValue] does on its own — reads a
/// surface style's `--shadow-*` bend exactly as little as an unrouted
/// `box-shadow` literal would: the component quietly sits out of every
/// preset while its `box-shadow` siblings bend.
///
/// `drop-shadow()` cannot express an inset layer at all, so the `inset`
/// step never routes here — there is no `--shadow-inset-filter` variable
/// to route to (mirrors the `hasInset` guard [CoreShadowLayersToCss]
/// callers already carry before reaching this function).
String emitDropShadowFilter(
  List<CoreShadowLayer> layers, {
  required String base,
}) {
  if (layers.isEmpty) return 'none';
  if (base == kShadowVariableBase) {
    final key = _shadowScaleKey(layers);
    if (key != null && key != 'inset') return 'var(--shadow-$key-filter)';
  }

  return layers.toDropShadowValue(base: base);
}

/// The scale key a stack is, or null when it is not one of the steps.
String? _shadowScaleKey(List<CoreShadowLayer> layers) {
  for (final step in const [
    (key: 'none', layers: CoreShadow.none),
    (key: 'xs', layers: CoreShadow.xs),
    (key: 'sm', layers: CoreShadow.sm),
    (key: 'md', layers: CoreShadow.md),
    (key: 'lg', layers: CoreShadow.lg),
    (key: 'xl', layers: CoreShadow.xl),
    (key: '2xl', layers: CoreShadow.xl2),
    (key: '3xl', layers: CoreShadow.xl3),
    (key: 'inset', layers: CoreShadow.inset),
  ]) {
    if (_sameStack(layers, step.layers)) return step.key;
  }

  return null;
}

bool _sameStack(List<CoreShadowLayer> a, List<CoreShadowLayer> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }

  return true;
}

/// The colour term of one shadow layer — [base] at the layer's opacity.
///
/// A cast ([strengthens]) multiplies that opacity by
/// [kShadowStrengthVariable] inside a `calc()`, so the dark scope draws it
/// stronger; CSS clamps the mix percentage to 100%, which is the cap the
/// Flutter seat states. A layer already at full opacity has nothing to
/// strengthen and keeps the bare base. A highlight (a rim, a bevel) is
/// light rather than shadow and passes `strengthens: false`.
///
/// The percentage keeps its fraction (`12.5%`): the layer's opacity is the
/// value Flutter paints, and truncating it would draw a different alpha on
/// Web.
String _shadowLayerColor(
  CoreShadowLayer l,
  String base, {
  required bool strengthens,
}) {
  if (l.opacity >= 1.0) return base;
  final percent = '${_percentOf(l.opacity)}%';
  final amount = strengthens
      ? 'calc($percent * var($kShadowStrengthVariable, 1))'
      : percent;

  return 'color-mix(in srgb, $base $amount, transparent)';
}

/// [opacity] × 100 with float noise rounded off and no trailing `.0`.
String _percentOf(double opacity) {
  final hundredths = (opacity * 10000).round();

  return hundredths % 100 == 0 ? '${hundredths ~/ 100}' : '${hundredths / 100}';
}

/// `List<CoreShadowLayer>` → CSS `box-shadow` value.
///
/// `base` supplies the base color (typically a CSS color string from the
/// active theme such as `onSurface`); each layer applies its `opacity`
/// via `color-mix(...)`, multiplied by the dark scope's
/// [kShadowStrengthVariable] unless `strengthens` is false.
extension CoreShadowLayersToCss on List<CoreShadowLayer> {
  /// Returns the CSS `box-shadow` value (comma-separated layers).
  ///
  /// [strengthens] is false only for a highlight drawn as a shadow layer
  /// (a surface rim, a glass bevel): the dark strengthens what shades the
  /// page, not what lights it.
  String toValue({required String base, bool strengthens = true}) => map((l) {
    final prefix = l.inset ? 'inset ' : '';
    final layer =
        '$prefix${_rem(l.offsetX)} ${_rem(l.offsetY)} '
        '${_rem(l.blurRadius)} ${_rem(l.spreadRadius)}';

    return '$layer ${_shadowLayerColor(l, base, strengthens: strengthens)}';
  }).join(', ');

  /// Whether any layer draws inside the element.
  ///
  /// Decides which CSS property a stack can use: `filter: drop-shadow()`
  /// has no way to express an inset layer, so a stack containing one has
  /// to go through `box-shadow` instead.
  bool get hasInset => any((l) => l.inset);

  /// Returns the CSS `filter` value using chained `drop-shadow()` layers.
  ///
  /// Unlike [toValue] (`box-shadow`, which follows the element's square
  /// border-box), `drop-shadow` casts the shadow from the element's
  /// rendered alpha shape — a rounded child (e.g. a `Card`) yields a
  /// rounded shadow with no wrapper `border-radius` needed. `drop-shadow`
  /// has no spread parameter, so the layer `spreadRadius` is dropped (a
  /// minor size delta on soft shadows).
  ///
  /// Inset layers cannot be expressed here at all. This used to skip them,
  /// which meant a stack that mixed inset and outer layers rendered as if
  /// the inset ones had never been written — a shadow silently going
  /// missing is far harder to notice than one drawn on the wrong
  /// geometry. Callers must check [hasInset] first and take the
  /// `box-shadow` path when it is true.
  String toDropShadowValue({required String base}) {
    assert(
      !hasInset,
      'drop-shadow() cannot express an inset layer — check hasInset and '
      'emit box-shadow for this stack instead.',
    );

    return map((l) {
      final color = _shadowLayerColor(l, base, strengthens: true);
      return 'drop-shadow(${_rem(l.offsetX)} ${_rem(l.offsetY)} '
          '${_rem(l.blurRadius)} $color)';
    }).join(' ');
  }
}

/// How much of a Figma layer-blur *radius* is the CSS `blur()` argument.
///
/// Figma states a layer blur as a radius that spans the whole fall-off of
/// the blur, while CSS `blur()` takes the standard deviation of the Gaussian
/// — half of that radius. The factor is stated here once so every Web
/// surface that carries a measured Figma layer blur converts it the same way.
const double kFigmaBlurRadiusToCssBlur = 0.5;

/// A Figma layer-blur [radius] (logical px) as a CSS `filter` value.
///
/// Dimensions on this platform are `rem`, so the converted blur is too: it
/// scales with the root font size together with the shape it softens.
String figmaLayerBlurCss(double radius) =>
    'blur(${_rem(radius * kFigmaBlurRadiusToCssBlur)})';

/// `CoreMainAxisAlignment` → Tailwind `justify-*` class.
extension CoreMainAxisAlignmentTailwind on CoreMainAxisAlignment {
  /// The `justify-content` utility class for a flex container.
  String get tailwindJustify => switch (this) {
    .start => WebLayout.justifyStart,
    .end => WebLayout.justifyEnd,
    .center => WebLayout.justifyCenter,
    .spaceBetween => WebLayout.justifyBetween,
    .spaceAround => WebLayout.justifyAround,
    .spaceEvenly => WebLayout.justifyEvenly,
  };
}

/// `CoreTextAlign` → CSS `text-align` keyword.
extension CoreTextAlignToCss on CoreTextAlign {
  /// Returns the matching CSS `text-align` keyword. Also usable as a
  /// Tailwind `text-{value}` class fragment (`text-center`, `text-end`
  /// …).
  String toValue() => switch (this) {
    .start => 'start',
    .end => 'end',
    .center => 'center',
    .justify => 'justify',
    .left => 'left',
    .right => 'right',
  };
}

/// `CoreVerticalAlign` → CSS vertical-alignment keywords.
///
/// Two surfaces: [alignItemsValue] for a flex container's
/// `align-items` (cross-axis alignment of a row), and
/// [verticalAlignValue] for an inline element's `vertical-align`.
extension CoreVerticalAlignToCss on CoreVerticalAlign {
  /// Returns the matching CSS `align-items` keyword for a flex row.
  String get alignItemsValue => switch (this) {
    .top => 'flex-start',
    .center => 'center',
    .bottom => 'flex-end',
  };

  /// Returns the matching CSS `vertical-align` keyword for inline text.
  String get verticalAlignValue => switch (this) {
    .top => 'top',
    .center => 'middle',
    .bottom => 'bottom',
  };
}

/// `CoreCubicBezier` → CSS `transition-timing-function` value.
///
/// `coui_core` stores easing as four control points only, which maps 1:1
/// to the CSS function; the Flutter mirror is
/// `CoreCubicBezierToFlutter.toValue()` returning a `Cubic`. Emitting the
/// points rather than a `var(--easing-*)` reference is what lets a
/// per-instance override carry an off-scale curve: the record has no
/// token key to look up, and reconstructing one from the numbers would
/// be a third encoding of the same value.
extension CoreCubicBezierToCss on CoreCubicBezier {
  /// Returns the CSS `cubic-bezier(x1, y1, x2, y2)` literal.
  String toCss() => 'cubic-bezier($x1, $y1, $x2, $y2)';
}

/// Maps a curve to its `--easing-*` CSS variable when it is one of
/// `CoreEasing`'s semantic aliases (`standard` / `decelerate` /
/// `accelerate` / `spring`) or [CoreEasing.linear], or falls back to
/// [CoreCubicBezierToCss.toCss]'s literal `cubic-bezier(...)` otherwise.
///
/// This is the easing analogue of [radiusCss] / [strokeWidthCss] /
/// [durationMsCss] — a component that hardcodes one of these five curves
/// (the common case: state-transition chrome has no per-instance curve
/// override) routes through the token so a future systemic easing
/// override has a variable to retime, instead of a CSS keyword literal
/// (`ease-in-out`) that no override can reach. A curve with no matching
/// alias — a genuinely arbitrary per-instance override, the same case
/// [strokeWidthCss] falls back to a literal `px` for — has no token key to
/// route through and keeps the literal `cubic-bezier(...)` form.
extension CoreCubicBezierToVarCss on CoreCubicBezier {
  /// Returns the `var(--easing-*)` reference for a known alias/raw curve,
  /// or the literal `cubic-bezier(...)` for anything else.
  String toVarCss() {
    if (this == CoreEasing.linear) {
      return 'var(--easing-${CoreEasing.scale.linear})';
    }
    if (this == CoreEasing.move) {
      return 'var(--easing-${CoreEasing.scale.easeInOut})';
    }
    if (this == CoreEasing.enter) {
      return 'var(--easing-${CoreEasing.scale.easeOut})';
    }
    if (this == CoreEasing.exit) {
      return 'var(--easing-${CoreEasing.scale.easeIn})';
    }
    if (this == CoreEasing.feedback) {
      return 'var(--easing-${CoreEasing.scale.easeOutBack})';
    }
    return toCss();
  }
}

/// CoreClipMode → CSS `overflow` value.
extension CoreClipModeToCss on CoreClipMode {
  /// Returns the CSS `overflow` value.
  ///
  /// Web flattens [CoreClipMode.hardEdge] / [CoreClipMode.antiAlias] /
  /// [CoreClipMode.antiAliasWithSaveLayer] to `hidden` — CSS has no
  /// anti-aliased clip primitive.
  String toValue() => switch (this) {
    .none => 'visible',
    .hardEdge || .antiAlias || .antiAliasWithSaveLayer => 'hidden',
  };
}

/// CoreTextDecoration → Tailwind `text-decoration-line` utility class.
extension CoreTextDecorationToCss on CoreTextDecoration {
  /// The utility class that sets this decoration. [CoreTextDecoration.none]
  /// is `no-underline`, which also clears an underline a UA stylesheet
  /// gives an `<a>`.
  String get tailwindDecoration => switch (this) {
    .none => 'no-underline',
    .underline => 'underline',
    .overline => 'overline',
    .lineThrough => 'line-through',
  };
}

/// The line-height declarations of [style]: the whole-pixel line box it
/// draws and the multiplier it hands to the text below it
/// (`--coui-leading`), or — for a size stated with no leading and no role
/// class to draw the box — the multiplier the element inherits, at its new
/// size. Empty when [style] states none of them.
///
/// A fixed line box wins over the multiplier — the precedence Flutter's
/// `height = lineHeightPx / fontSize` gives. It is a length, so it goes
/// through rem like `font-size`: the box follows the browser's text size
/// the way Flutter's follows the text scaler, where a `px` box would stay
/// put while the glyphs inside it grew. Both land on a whole pixel, the line
/// box Flutter's engine lays the text out in
/// (`CssVariableGenerator.lineHeightCss`), and both hand their multiplier
/// down, the way a Flutter style hands its `height` to the text it wraps. A
/// size stated alone keeps the inherited multiplier, as Flutter keeps the
/// inherited `height` when only the size changes.
///
/// The one place a [CoreTextStyle] becomes a line height on Web — every
/// emit that writes a style's fields inline goes through it.
Map<String, String> lineBoxCss(CoreTextStyle style) {
  final box = style.lineHeightPx;
  final multiplier = style.lineHeight;
  final size = style.fontSize;
  if (box != null) {
    return {
      'line-height': CssVariableGenerator.roundToPixelCss(_rem(box)),
      if (size != null) CssVariableGenerator.leadingVar: '${box / size}',
    };
  }
  if (multiplier != null) {
    return {
      'line-height': CssVariableGenerator.lineHeightCss(multiplier),
      CssVariableGenerator.leadingVar: '$multiplier',
    };
  }
  if (size != null && style.token == null) {
    return {'line-height': CssVariableGenerator.inheritedLineHeightCss()};
  }

  return const {};
}

/// `CoreTextStyle` → inline CSS property bundle.
///
/// Tailwind utility classes already cover the typography role
/// (`text-label-large`), the `CoreFontWeight.X` weights (`font-medium`),
/// and the design-system colour tokens (`text-on-surface`) — those flow
/// through className. Arbitrary per-instance overrides
/// (`fontSize: 17`, `lineHeight: 1.3`, `lineHeightPx: 21`, or a raw
/// `CoreColor.rgba(...)`) have no matching utility class, so they must be
/// emitted inline. [toInlineCss] returns exactly that override-bundle.
///
/// Returns an empty map when no field is set. Caller composes via:
///
/// ```dart
/// Styles(raw: {
///   'cursor': 'pointer',
///   ...style.toInlineCss(),
/// });
/// ```
extension CoreTextStyleToInlineCss on CoreTextStyle {
  /// Returns the inline-CSS property bundle for the populated
  /// per-instance override fields (`font-size` / `font-weight` /
  /// `line-height` / `letter-spacing` / `font-family` / `color`). Empty
  /// when no override is set.
  ///
  /// `line-height` comes from [lineBoxCss]: the whole-pixel box the style
  /// draws, and the multiplier it hands to the text below it.
  ///
  /// Set [includeColor] to `false` to omit `color` — the caller emits the
  /// colour separately through `scheme.resolve(...).toValue()` (dark-mode
  /// aware), since this bundle's `color` is a bare token `.toValue()`.
  Map<String, String> toInlineCss({bool includeColor = true}) {
    final raw = <String, String>{};
    if (fontSize != null) raw['font-size'] = _rem(fontSize!);
    if (fontWeight != null) raw['font-weight'] = '$fontWeight';
    // The line box and the multiplier handed down — see [lineBoxCss].
    raw.addAll(lineBoxCss(this));
    // `letterSpacing` is an `em` ratio (`CoreLetterSpacing.tight` = -0.025),
    // not a px length, so it does not go through the px→rem divisor.
    // Emitting `em` keeps the tracking in the same unit as the role variable
    // (`--coui-text-{role}-tracking: <em>em`) and equal to Flutter, which
    // multiplies the same ratio by the font size (`ls * fs`).
    if (letterSpacing != null) raw['letter-spacing'] = '${letterSpacing}em';
    // Font family override — a known face rides its
    // `--coui-font-family-{key}` variable (full fallback stack, reactive),
    // any other face is named with the text face behind it.
    final family = fontFamily;
    if (family != null) {
      raw['font-family'] = CssVariableGenerator.fontFamilyCss(family);
    }
    if (includeColor && color != null) raw['color'] = color!.toValue();
    return raw;
  }
}

/// `String` (a `CoreFontFamily.X` font name) → Tailwind scale key.
extension CoreFontFamilyValueToTailwind on String {
  /// Returns the Tailwind font-family class-name key (`'mono'`) for a
  /// [CoreFontFamily] name, or `null` when the string is not a known
  /// family (so callers omit the class / CSS variable). Use as
  /// `'font-${family.tailwindFontFamily}'` or the
  /// `var(--coui-font-family-{key})` CSS variable.
  String? get tailwindFontFamily => switch (this) {
    CoreFontFamily.sans => CoreFontFamily.scale.sans,
    CoreFontFamily.mono => CoreFontFamily.scale.mono,
    _ => null,
  };
}

// ════════════════════════════════════════════════════════════════════
// Tailwind class-name conversion
// ════════════════════════════════════════════════════════════════════
//
// Core 의 의미 단위 (`CoreRadius.radiusN` / `CoreStrokeWidth.strokeN`) 를
// Tailwind class 키 (`'radius16'` / `'stroke2'`) 로 변환하는 어댑터.
// Core 가 Tailwind 어휘를 직접 알지 않도록 분리 — 컴포넌트 도메인 토큰은
// `CoreXxxTokens.cornerRadius: double` 형태로만 노출하고, Web 사용처가
// 아래 extension 으로 매핑한다.
//
// 매핑 테이블은 `CoreRadius` / `CoreStrokeWidth` 의 멤버 값과 1:1 mirror —
// 새 토큰 추가 시 양쪽 같이 추가하지 않으면 `ArgumentError`.

/// `double` 원시토큰 (Flutter logical px) → Tailwind class 키.
extension CoreRadiusValueToTailwind on double {
  /// Returns the Tailwind radius class-name key (`'radius16'`). Use as
  /// `'rounded-${value.tailwindRadius}'`. Throws [ArgumentError] when
  /// the value does not match a `CoreRadius.radiusN` constant.
  String get tailwindRadius => switch (this) {
    CoreRadius.radius0 => CoreRadius.scale.radius0,
    CoreRadius.radius2 => CoreRadius.scale.radius2,
    CoreRadius.radius4 => CoreRadius.scale.radius4,
    CoreRadius.radius6 => CoreRadius.scale.radius6,
    CoreRadius.radius8 => CoreRadius.scale.radius8,
    CoreRadius.radius10 => CoreRadius.scale.radius10,
    CoreRadius.radius12 => CoreRadius.scale.radius12,
    CoreRadius.radius14 => CoreRadius.scale.radius14,
    CoreRadius.radius16 => CoreRadius.scale.radius16,
    CoreRadius.radius20 => CoreRadius.scale.radius20,
    CoreRadius.radius24 => CoreRadius.scale.radius24,
    CoreRadius.radius28 => CoreRadius.scale.radius28,
    CoreRadius.radius32 => CoreRadius.scale.radius32,
    CoreRadius.radius36 => CoreRadius.scale.radius36,
    CoreRadius.radius40 => CoreRadius.scale.radius40,
    CoreRadius.radius48 => CoreRadius.scale.radius48,
    CoreRadius.radius56 => CoreRadius.scale.radius56,
    CoreRadius.radius64 => CoreRadius.scale.radius64,
    CoreRadius.radius9999 => CoreRadius.scale.radius9999,
    _ => throw ArgumentError(
      'No CoreRadius.scale mapping for value $this — add it to '
      'CoreRadiusValueToTailwind.tailwindRadius.',
    ),
  };

  /// Returns the Tailwind stroke class-name key (`'stroke2'`). Use as
  /// `'border-${value.tailwindStroke}'`. Throws [ArgumentError] when the
  /// value does not match a `CoreStrokeWidth.strokeN` constant.
  String get tailwindStroke => switch (this) {
    CoreStrokeWidth.stroke0 => CoreStrokeWidth.scale.stroke0,
    CoreStrokeWidth.stroke0_5 => CoreStrokeWidth.scale.stroke0_5,
    CoreStrokeWidth.stroke1 => CoreStrokeWidth.scale.stroke1,
    CoreStrokeWidth.stroke1_5 => CoreStrokeWidth.scale.stroke1_5,
    CoreStrokeWidth.stroke2 => CoreStrokeWidth.scale.stroke2,
    CoreStrokeWidth.stroke3 => CoreStrokeWidth.scale.stroke3,
    CoreStrokeWidth.stroke4 => CoreStrokeWidth.scale.stroke4,
    CoreStrokeWidth.stroke5 => CoreStrokeWidth.scale.stroke5,
    CoreStrokeWidth.stroke6 => CoreStrokeWidth.scale.stroke6,
    CoreStrokeWidth.stroke8 => CoreStrokeWidth.scale.stroke8,
    _ => throw ArgumentError(
      'No CoreStrokeWidth.scale mapping for value $this — add it to '
      'CoreRadiusValueToTailwind.tailwindStroke.',
    ),
  };

  /// Returns the Tailwind space class-name key (`'space12'`). Use as
  /// `'p-${value.tailwindSpace}'` / `'gap-${value.tailwindSpace}'` /
  /// `'top-${value.tailwindSpace}'` / `'w-${value.tailwindSpace}'` etc.
  /// `CoreSpace.scale.spaceN` 의 멤버 이름이 `space{N}` 형식이라
  /// `'space${toInt()}'` 1:1 변환 — switch 36 cases 없이 가능.
  String get tailwindSpace => 'space${toInt()}';

  /// Returns the Tailwind size class-name key (`'size40'`). Use as
  /// `'h-${value.tailwindSize}'` / `'w-${value.tailwindSize}'` etc.
  /// `CoreSize.scale.sizeN` 의 멤버 이름이 `size{N}` 형식이라
  /// `'size${toInt()}'` 1:1 변환.
  String get tailwindSize => 'size${toInt()}';

  /// Returns the Tailwind control-row height key (`'control40'`). Use as
  /// `'h-${height.tailwindControlHeight}'` / `'min-h-…'` for a control
  /// row's height — the class a density re-points
  /// (`--coui-control-height-*`), where `tailwindSize` would hand it the
  /// size variable that icons and avatars share.
  String get tailwindControlHeight => 'control${toInt()}';

  /// Returns the Tailwind layout class-name key (`'layout640'`). Use as
  /// `'max-w-${value.tailwindLayout}'` / `'max-h-${value.tailwindLayout}'`
  /// / `'min-w-${value.tailwindLayout}'`. `CoreLayout.scale.layoutN` 의
  /// 멤버 이름이 `layout{N}` 형식이라 `'layout${toInt()}'` 1:1 변환.
  String get tailwindLayout => 'layout${toInt()}';
}

/// `CoreBorderRadius` → Tailwind class 키.
///
/// `tailwindRadius` (uniform 가정) 는 legacy — `CoreBorderRadius.all(...)`
/// 처럼 4 corner 가 같을 때만 안전. 새 코드는 4-corner-full [tailwindClasses]
/// 를 써서 asymmetric 입력도 정확히 클래스로 emit 하도록 한다.
extension CoreBorderRadiusToTailwind on CoreBorderRadius {
  /// (legacy) Returns the Tailwind radius class-name key (`'radius16'`)
  /// from the `topLeft` corner. Use as
  /// `'rounded-${border.tailwindRadius}'`. Silently drops the other
  /// three corners — prefer [tailwindClasses] for new code.
  String get tailwindRadius => topLeft.tailwindRadius;

  /// Returns the four corner-specific Tailwind class names — emits all
  /// four corners explicitly so symmetric and asymmetric inputs both
  /// translate accurately. Use as
  /// `'<wrapper> ${border.tailwindClasses()}'`.
  ///
  /// Example output (with `CoreBorderRadius.all(CoreRadius.radius16)`; the
  /// result is one space-joined string, wrapped here to fit):
  ///
  /// ```text
  /// rounded-tl-radius16 rounded-tr-radius16
  /// rounded-bl-radius16 rounded-br-radius16
  /// ```
  String tailwindClasses() =>
      'rounded-tl-${topLeft.tailwindRadius}'
      ' rounded-tr-${topRight.tailwindRadius}'
      ' rounded-bl-${bottomLeft.tailwindRadius}'
      ' rounded-br-${bottomRight.tailwindRadius}';
}

/// `CoreEdgeInsets` → Tailwind class 키 (4-side full).
///
/// 4-side full emit — symmetric (`CoreEdgeInsets.symmetric(...)`) 와
/// asymmetric (`CoreEdgeInsets.fromLTRB(...)`) 모두 정확히 클래스로
/// 떨어진다. 사용처는 prefix 만 넘기면 된다 — `'p'` (padding),
/// `'m'` (margin), `'inset'` (positioning) 등.
extension CoreEdgeInsetsToTailwind on CoreEdgeInsets {
  /// Returns the four side-specific Tailwind class names using
  /// [prefix] (e.g. `'p'` → `'pl-... pr-... pt-... pb-...'`).
  ///
  /// Example output (with
  /// `CoreEdgeInsets.symmetric(horizontal: 8, vertical: 6)`,
  /// `prefix = 'p'`):
  ///
  /// ```text
  /// pl-space8 pr-space8 pt-space6 pb-space6
  /// ```
  String tailwindClasses(String prefix) =>
      '$prefix'
      'l-${left.tailwindSpace}'
      ' $prefix'
      'r-${right.tailwindSpace}'
      ' $prefix'
      't-${top.tailwindSpace}'
      ' $prefix'
      'b-${bottom.tailwindSpace}';

  /// Returns the logical side classes using [prefix] — `ps-` / `pe-`
  /// rather than `pl-` / `pr-`, so the browser mirrors them against the
  /// element's `dir`.
  ///
  /// The Flutter twin gets the same behaviour from
  /// `EdgeInsetsDirectional`. Logical spacing utilities read the same
  /// scale as their physical counterparts, so a key that works for `pl-`
  /// works here.
  String tailwindLogicalClasses(String prefix) =>
      '${prefix}s-${start.tailwindSpace}'
      ' ${prefix}e-${end.tailwindSpace}'
      ' ${prefix}t-${top.tailwindSpace}'
      ' ${prefix}b-${bottom.tailwindSpace}';
}

/// `CoreTextStyle` (typography role const reference) → Tailwind
/// typography role 키 (`'body-medium'` …).
///
/// `CoreTypography.coui.X` 인스턴스를 reverse lookup 해서 role name 을
/// 얻는다. Component 도메인 토큰이 `static const CoreTextStyle defaultBody
/// = CoreTypography.coui.bodyMedium;` 형태로 노출하면, Web 사용처가
/// `'text-${CardStyle.defaultBody.tailwindTypographyRole}'` 로 변환.
///
/// 역할 목록은 손으로 적지 않고 `CoreTextStyles.values` 에서 읽는다 —
/// 역할이 늘어도 이 매핑이 따로 낡지 않는다. 같은 값의 const 는 한
/// 인스턴스로 합쳐지므로, 이 역참조는 `CoreTypography.coui` 의 두 역할이
/// 모든 칸에서 같지 않을 때만 성립한다(테스트가 역할마다 고정한다).
///
/// `CoreTypography.coui` 가 아닌 임의 `CoreTextStyle` 에 대해서는
/// [ArgumentError] — typography role 토큰이 아닌 임의 instance-level
/// style 은 inline CSS ([CoreTextStyleToInlineCss.toInlineCss]) 로
/// 가야 함.
extension CoreTextStyleToTailwindRole on CoreTextStyle {
  /// Returns the Tailwind typography role key (`'body-medium'`). Use as
  /// `'text-${style.tailwindTypographyRole}'`. Throws [ArgumentError]
  /// when the style is not one of `CoreTypography.coui.X`.
  String get tailwindTypographyRole {
    const scale = CoreTypography.coui;
    for (final token in CoreTextStyles.values) {
      if (identical(this, token.read(scale))) return token.name;
    }
    throw ArgumentError(
      'CoreTextStyle is not a CoreTypography.coui role — use '
      'CoreTextStyleToInlineCss.toInlineCss() for instance-level style.',
    );
  }
}

/// `int` (CSS font-weight 100..900) → Tailwind class 키.
extension CoreFontWeightValueToTailwind on int {
  /// Returns the Tailwind font-weight class-name key (`'medium'`). Use as
  /// `'font-${value.tailwindFontWeight}'`. Throws [ArgumentError] when
  /// the value does not match a `CoreFontWeight.X` constant.
  String get tailwindFontWeight => switch (this) {
    CoreFontWeight.thin => CoreFontWeight.scale.thin,
    CoreFontWeight.extraLight => CoreFontWeight.scale.extralight,
    CoreFontWeight.light => CoreFontWeight.scale.light,
    CoreFontWeight.regular => CoreFontWeight.scale.regular,
    CoreFontWeight.medium => CoreFontWeight.scale.medium,
    CoreFontWeight.semiBold => CoreFontWeight.scale.semibold,
    CoreFontWeight.bold => CoreFontWeight.scale.bold,
    CoreFontWeight.extraBold => CoreFontWeight.scale.extrabold,
    CoreFontWeight.black => CoreFontWeight.scale.black,
    _ => throw ArgumentError(
      'No CoreFontWeight.scale mapping for value $this — add it to '
      'CoreFontWeightValueToTailwind.tailwindFontWeight.',
    ),
  };

  /// Returns the Tailwind duration class-name key (`'ms300'`). Use as
  /// `'duration-${value.tailwindDuration}'`. Throws [ArgumentError]
  /// when the value does not match a `CoreDuration.msN` constant.
  String get tailwindDuration => switch (this) {
    CoreDuration.ms0 => CoreDuration.scale.ms0,
    CoreDuration.ms50 => CoreDuration.scale.ms50,
    CoreDuration.ms100 => CoreDuration.scale.ms100,
    CoreDuration.ms150 => CoreDuration.scale.ms150,
    CoreDuration.ms200 => CoreDuration.scale.ms200,
    CoreDuration.ms250 => CoreDuration.scale.ms250,
    CoreDuration.ms300 => CoreDuration.scale.ms300,
    CoreDuration.ms350 => CoreDuration.scale.ms350,
    CoreDuration.ms400 => CoreDuration.scale.ms400,
    CoreDuration.ms450 => CoreDuration.scale.ms450,
    CoreDuration.ms500 => CoreDuration.scale.ms500,
    CoreDuration.ms1000 => CoreDuration.scale.ms1000,
    CoreDuration.ms2000 => CoreDuration.scale.ms2000,
    CoreDuration.ms3000 => CoreDuration.scale.ms3000,
    CoreDuration.ms4000 => CoreDuration.scale.ms4000,
    CoreDuration.ms5000 => CoreDuration.scale.ms5000,
    CoreDuration.indeterminate => CoreDuration.scale.indeterminate,
    _ => throw ArgumentError(
      'No CoreDuration.scale mapping for value $this — add it to '
      'CoreFontWeightValueToTailwind.tailwindDuration.',
    ),
  };
}

/// `CoreOutlinedContainerElevation` → Tailwind shadow class.
///
/// Every component whose surface is a `OutlinedContainer` reads
/// elevation through this enum, so the Tailwind mapping lives here
/// (shared adapter) rather than in any per-component style file.
extension CoreOutlinedContainerElevationTailwind
    on CoreOutlinedContainerElevation {
  /// Returns the Tailwind shadow class for this elevation, or empty
  /// string for `none`.
  String get tailwindShadowClass => switch (this) {
    .none => '',
    .soft => 'shadow-sm',
    .medium => 'shadow-md',
    .strong => 'shadow-lg',
  };

  /// The stack this elevation names, before any conversion — the same
  /// `CoreShadow.sm/md/lg` scale the `shadow-{sm|md|lg}` classes resolve
  /// through `--shadow-*`, read from the one Core source the Flutter twin
  /// reads. `none` is empty.
  ///
  /// A caller that tints the stack with its own base colour needs the layers
  /// themselves: no `--shadow-*` variable carries a pinned tint.
  List<CoreShadowLayer> get layers => switch (this) {
    .none => const [],
    .soft => CoreOutlinedContainerStyle.defaultSoftShadow,
    .medium => CoreOutlinedContainerStyle.defaultMediumShadow,
    .strong => CoreOutlinedContainerStyle.defaultStrongShadow,
  };
}

// ════════════════════════════════════════════════════════════════════
// EMIT family — single class-vs-inline decision per design value
// ════════════════════════════════════════════════════════════════════
//
// One helper per `(Core type)` routes a design value to EXACTLY ONE of:
//
//   • class  — a Tailwind utility class exists for the value
//     (`bg-on-surface`, `text-body-medium`, `rounded-radius16`). Classes
//     carry caching + pseudo-state (`hover:`/`focus:`) that inline values
//     cannot express.
//   • inline — no preset class fits, emitted as `Styles(raw: {...})`
//     input (`CoreColor.rgba(...)`, `fontSize: 17`, an arbitrary
//     `CoreBorderRadius.all(7)`).
//
// Two ways the branch is decided, by Core type:
//
//   • color / typography (`emitColor`, `emitTypography`) — by the value's
//     `.token` identity. A token-bound colour / role emits a class even
//     when it came from a user override, so a token override stays
//     dark-mode reactive. Only a raw (`token == null`) colour or a raw
//     scalar overlay goes inline.
//   • spacing / radius (`emitSpacing`, `emitRadius`) — by `value == null`
//     (default vs override). The default (`value == null`) is always a
//     design-system token, so it emits a class; ANY override (`value !=
//     null`) goes inline. This deliberately does NOT inspect the resolved
//     px value's scale step — reverse-deriving a Tailwind key from a
//     logical-px value (`scaleKeyOf`) is a single-source violation.
//
// Every field flows through the same `[Emit]` shape so a resolver reads
// `emitted.className` / `emitted.inline` without re-deriving the branch
// per field.
//
// theme-free: these helpers take no `theme`/`scheme` — Web emits token
// names only and the browser resolves `--coui-*` at runtime.

/// The result of an [Emit] decision: a Tailwind class fragment (empty
/// when the value goes inline) and an optional inline-CSS property
/// bundle (`null` when the value goes to a class).
///
/// Exactly one of the two is populated for a given design value — the
/// resolver composes `emitted.className` into its class list and
/// `?emitted.inline` into its `Styles(raw: ...)` map.
typedef Emit = ({String className, Map<String, String>? inline});

/// Which Tailwind colour utility prefix a [emitColor] result targets.
enum ColorTarget {
  /// `background-color` — Tailwind `bg-{token}`.
  background('bg', 'background-color'),

  /// `color` (text) — Tailwind `text-{token}`.
  text('text', 'color'),

  /// `border-color` — Tailwind `border-{token}`.
  border('border', 'border-color'),

  /// `--tw-ring-color` — Tailwind `ring-{token}`, a decorative ring (the
  /// focus ring is an outline — see [focusRingClassName] /
  /// [focusRingScopedRule]).
  ring('ring', '--tw-ring-color');

  const ColorTarget(this.classPrefix, this.cssProperty);

  /// The Tailwind class prefix (`bg` / `text` / `border` / `ring`).
  final String classPrefix;

  /// The inline-CSS property name used when the value goes inline.
  final String cssProperty;
}

/// Emits a [CoreColor] for [target] as a single class-XOR-inline result.
///
/// Resolves `value ?? fallbackDefault`, then:
/// - token-bound (`token != null`) → Tailwind class
///   (`bg-on-surface`, `text-primary/60` …), no inline.
/// - raw / arbitrary (`token == null`) → inline
///   (`{'background-color': 'rgb(...)'}`), empty class.
///
/// The transparent sentinel ([CoreColor.transparent]) is token-less, so
/// it emits inline `transparent` via `.toValue()` rather than a class —
/// callers that want to OMIT the surface entirely should check
/// `value.isTransparent` before emitting.
Emit emitColor(
  CoreColor? value,
  CoreColor fallbackDefault,
  ColorTarget target,
) {
  final resolved = value ?? fallbackDefault;
  if (resolved.token != null) {
    return (
      className: '${target.classPrefix}-${resolved.tailwindColor}',
      inline: null,
    );
  }
  return (
    className: '',
    inline: {target.cssProperty: resolved.toValue()},
  );
}

/// Emits an optional [CoreColor] for [target] — `null` emits nothing.
///
/// The [emitColor] branch for a colour that has no design-system default
/// to fall back to. `Icon` leaves an unset colour unset on purpose so the
/// glyph inherits `currentColor` from whatever it sits in; forcing a
/// default class there would override the parent's foreground. A set
/// colour still splits the [emitColor] way — token-bound → class, raw →
/// inline — so a raw colour is painted instead of becoming a class
/// Tailwind cannot read.
Emit emitColorOrInherit(CoreColor? value, ColorTarget target) => value == null
    ? (className: '', inline: null)
    : emitColor(value, value, target);

/// Emits a [CoreTextStyle] as a class + optional-inline result.
///
/// Resolves `fallbackDefault.merge(value)` (composite — a caller that
/// overrides only `color` keeps the default role), then routes by
/// whether the resolved style carries a typography role token:
///
/// - **role present** (`resolved.token != null`) → the role emits a
///   `text-{role}` Tailwind class (+ `text-{colorToken}` when a token
///   colour is set), and ANY explicit scalar overlay
///   (`fontSize` / `fontWeight` / `lineHeight` / `lineHeightPx` /
///   `letterSpacing` / `fontFamily`) or raw (`token == null`) colour
///   layered on top of the role emits inline alongside the class. A pure
///   role (no overlay, no raw colour) yields the class with
///   `inline == null`.
/// - **arbitrary** (`resolved.token == null`) → no preset class fits, so
///   className is empty and every populated field emits inline via
///   [CoreTextStyleToInlineCss.toInlineCss].
///
/// ### Why role class + overlay inline coexist
///
/// [CoreTextStyle.token] stores ONLY the role identifier — the role's own
/// `fontSize` / `fontWeight` / `lineHeight` / `lineHeightPx` /
/// `letterSpacing` fields stay `null` (they are materialised at render
/// time by `token.read`). So a non-null scalar field on a token-bound
/// style is, by construction, an EXPLICIT per-instance overlay, never a
/// role-derived value. Emitting the role on a class (dark-mode /
/// accessibility-scale reactive) while overlaying only the explicit
/// scalars inline reproduces a component that pins one role across sizes
/// but varies `fontSize` per size (e.g. `Checkbox` = `bodySmall` role +
/// per-size `fontSize`), without losing the role.
///
/// A role with a fixed line box (`code-*`) carries that box on its class,
/// through the role's line-height variable. A `lineHeight` overlay on such
/// a role goes inline as a multiplier and wins over the box; a `fontSize`
/// overlay leaves the box as it is — the outcome `CoreTextStyle.merge`
/// gives the same overlay on the role's own style.
Emit emitTypography(CoreTextStyle? value, CoreTextStyle fallbackDefault) {
  final resolved = fallbackDefault.merge(value);
  final color = resolved.color;

  // Arbitrary (no role token) → no preset class; everything goes inline.
  if (resolved.token == null) {
    return (className: '', inline: resolved.toInlineCss());
  }

  // Role present → role class (+ token colour class). Explicit scalar
  // overlays + any raw (non-token) colour layered on top of the role go
  // inline; a token colour stays on a class so it stays dark-mode reactive.
  final classes = ['text-${resolved.token!.name}'];
  final tokenColour = color != null && color.token != null;
  if (tokenColour) classes.add('text-${color.tailwindColor}');

  // `toInlineCss` only emits populated fields — for a token-bound style
  // those are exactly the explicit overlays (the role's own fields are
  // null). Omit `color` when it is token-bound (carried by the class above).
  final inline = resolved.toInlineCss(includeColor: !tokenColour);
  return (
    className: classes.join(' '),
    inline: inline.isEmpty ? null : inline,
  );
}

/// [emitTypography] for text drawn at a fraction of its role's size — the
/// text of a picture of a screen, which is a small copy of the real thing.
///
/// The role still rides its `text-{role}` class (weight, leading and
/// tracking stay the role's own — tracking and a multiplier leading are
/// ratios, so they follow the shrunk size by themselves). Only the size is
/// overlaid inline: `role size × [factor]`, read from the role's CSS
/// variable so a project's own typography scale drives it exactly as it
/// drives the class. A style that states its own `fontSize` shrinks that
/// instead, and one that states its own `lineHeightPx` shrinks that box
/// with it — a length, the way `CoreTextStyle.scale` treats it. One with
/// neither a size nor a box anywhere emits nothing extra.
///
/// A role whose fixed line box (`code-*`) comes only from its class shrinks
/// that box by the same factor: the factor rides `--coui-text-scale`, which
/// the role class reads only for a box (`ThemeConfig`).
Emit emitScaledTypography(
  CoreTextStyle? value,
  CoreTextStyle fallbackDefault, {
  required double factor,
}) {
  final emitted = emitTypography(value, fallbackDefault);
  final resolved = fallbackDefault.merge(value);
  final stated = resolved.fontSize;
  final role = resolved.token;
  final box = resolved.lineHeightPx;
  final size = stated != null
      ? _rem(stated * factor)
      : role != null
      ? 'calc(var(--coui-text-${role.name}-size) * $factor)'
      : null;
  if (size == null && box == null) return emitted;

  return (
    className: emitted.className,
    inline: {
      ...?emitted.inline,
      'font-size': ?size,
      if (box != null)
        'line-height': CssVariableGenerator.roundToPixelCss(_rem(box * factor))
      else if (role != null)
        '--coui-text-scale': '$factor',
    },
  );
}

/// Emits a [CoreBorderRadius] as a single class-XOR-inline result.
///
/// The class-vs-inline split is decided ONLY by whether the user passed
/// an override ([value]), never by inspecting the resolved value's token
/// steps (which would be a single-source violation — reverse-deriving the
/// scale key from a logical-px value):
/// - [value] is `null` → emit the [fallbackDefault] (always a
///   design-system token, since defaults are token-bound) as Tailwind
///   four-corner classes ([CoreBorderRadiusToTailwind.tailwindClasses]),
///   no inline.
/// - [value] is non-null → emit the override inline
///   `{'border-radius': '<shorthand>'}` via [CoreBorderRadiusToCss.toValue]
///   (token corners become `var(--coui-radius-N)`, arbitrary corners
///   become `px`), empty class.
Emit emitRadius(CoreBorderRadius? value, CoreBorderRadius fallbackDefault) {
  if (value == null) {
    return (className: fallbackDefault.tailwindClasses(), inline: null);
  }
  return (
    className: '',
    inline: {'border-radius': value.toValue()},
  );
}

/// Emits a border width (`double`, logical px) as a single
/// class-XOR-inline result.
///
/// Same override-keyed split as [emitRadius] — decided ONLY by whether a
/// value was supplied, never by reverse-deriving a scale key from it:
/// - [value] is `null` → the [fallbackDefault] (a `CoreStrokeWidth`
///   token by construction) emits the `border-strokeN` class, no inline.
/// - [value] is non-null → inline `{'border-width': …}` via
///   [strokeWidthCss], empty class. A token-valued override still lands
///   on `var(--coui-stroke-width-N)`, so it renders the same as the
///   class; an arbitrary one (`1.25`) emits a literal `px`.
///
/// Why the override may not ride a class: [CoreRadiusValueToTailwind.
/// tailwindStroke] throws on a value off the stroke scale, and an
/// override is caller-supplied — reading it through that getter turns
/// `boxBorderWidth: 1.25` into a render-time crash.
Emit emitStrokeWidth(double? value, double fallbackDefault) {
  if (value == null) {
    return (
      className: 'border-${fallbackDefault.tailwindStroke}',
      inline: null,
    );
  }
  return (
    className: '',
    inline: {'border-width': strokeWidthCss(value)},
  );
}

/// Emits a [CoreEdgeInsets] (padding / margin) as a single
/// class-XOR-inline result for the Tailwind [prefix] (`'p'` / `'m'`).
///
/// The class-vs-inline split is decided ONLY by whether the user passed
/// an override ([value]), never by inspecting the resolved value's scale
/// steps (which would be a single-source violation — reverse-deriving the
/// scale key from a logical-px value):
/// - [value] is `null` → emit the [fallbackDefault] (always a
///   design-system token, since defaults are token-bound) as Tailwind
///   four-side classes ([CoreEdgeInsetsToTailwind.tailwindClasses]), no
///   inline.
/// - [value] is non-null → emit the override inline
///   `{'<cssProperty>': '<shorthand>'}` via [CoreEdgeInsetsToCss.toValue]
///   (each side through [spaceCss] — a step names its `--coui-space-*`
///   variable, an off-scale side is a literal `rem`), empty class.
///   [cssProperty] is `'padding'` or `'margin'`.
Emit emitSpacing(
  CoreEdgeInsets? value,
  CoreEdgeInsets fallbackDefault, {
  required String prefix,
  required String cssProperty,
}) {
  if (value == null) {
    return (className: fallbackDefault.tailwindClasses(prefix), inline: null);
  }
  return (
    className: '',
    inline: {cssProperty: value.toValue()},
  );
}

// ════════════════════════════════════════════════════════════════════
// PSEUDO-STATE EMIT family — class-vs-scoped-rule decision per value
// ════════════════════════════════════════════════════════════════════
//
// Pseudo-state chrome (`:hover` / `:focus-visible` / `:active` /
// `:disabled` / `[aria-selected]` / `::placeholder` / `::selection` …)
// CANNOT be expressed as inline CSS — a coloured pseudo-state value must
// ride EITHER a Tailwind pseudo class (`hover:bg-primary`) OR a scoped
// `<style>` rule (`#scopeId:hover{background-color: …}`).
//
// A Tailwind pseudo class is only available for a design-system TOKEN
// colour (`.tailwindColor` maps a token to its class key and null-bangs
// on a raw colour). So a caller / theme override with a RAW
// (`token == null`) colour on a pseudo-state slot has no class — it must
// fall back to a scoped CSS rule keyed on the element's [scopeSelector]
// (the proven `clickable` / `progress` pattern). Without this fallback a
// raw pseudo-state override throws `token!.name` at render.
//
// theme-free: like the inline emit family, these helpers emit token names
// only (via `.toValue()` / `.tailwindColor`) and never read `theme`.

/// The result of a pseudo-state [emitPseudoColor] decision: a Tailwind
/// pseudo-class fragment (empty when the value goes to a scoped rule) and
/// a scoped CSS rule fragment (empty when the value stays on a class).
///
/// Exactly one of the two is populated — the resolver composes
/// `pseudo.className` into its class list and accumulates `pseudo.rule`
/// into the component's scoped `<style>` block (a `Resolved*Rules` /
/// `<style>` child, keyed on the element's `scopeSelector`).
typedef PseudoEmit = ({String className, String rule});

/// A Web pseudo-state: its Tailwind variant prefix (`hover:`) and the
/// CSS selector it produces for the scoped-rule fallback path.
///
/// [selector] takes the element's base selector (`'#co-badge-1'` for a
/// single-root element, or `'.co-dot-1'` for a repeated element) and
/// returns the full scoped-rule selector. Ancestor / sibling variants
/// (`group-focus-visible`, `peer-disabled`) place the pseudo on the
/// related element via a combinator, mirroring Tailwind's own selectors.
enum WebPseudo {
  /// `:hover` — pointer over the element.
  hover('hover:'),

  /// `:hover` only while no descendant (or the element itself) holds focus —
  /// `:hover:not(:focus-within)`.
  ///
  /// For a hover step that must lose to a focused state on a focus-within
  /// container. Tailwind v3 emits `hover:` AFTER `focus-within:` at the same
  /// specificity, so a plain `hover:border-*` would beat
  /// `focus-within:border-*` while the pointer sits over a focused container.
  /// Excluding focus from the hover selector itself is cascade-order
  /// independent. Carried as an arbitrary-variant class
  /// (`[&:hover:not(:focus-within)]:border-*`).
  hoverUnlessFocusWithin('[&:hover:not(:focus-within)]:'),

  /// `:hover` only while the element itself is not focused —
  /// `:hover:not(:focus)`.
  ///
  /// The twin of [hoverUnlessFocusWithin] for a focusable element whose
  /// focus treatment is a ring around it (the border stays at rest while
  /// focused) rather than a border colour of its own, so there is no
  /// `focus:` border class for the cascade to arbitrate against.
  hoverUnlessFocus('[&:hover:not(:focus)]:'),

  /// `:focus` — element focused (any input modality).
  focus('focus:'),

  /// `:focus-visible` — element focused via keyboard (CoUI focus ring).
  focusVisible('focus-visible:'),

  /// `:focus-within` — element or a descendant is focused.
  focusWithin('focus-within:'),

  /// `:active` — element being pressed.
  active('active:'),

  /// `:disabled` — native disabled control.
  disabled('disabled:'),

  /// `[aria-selected="true"]` — ARIA-selected state.
  ariaSelected('aria-selected:'),

  /// `::placeholder` — placeholder text of a native input.
  placeholder('placeholder:'),

  /// `::selection` — highlighted text range.
  selection('selection:'),

  /// `.group:focus-visible <el>` — keyboard focus on a `.group` ancestor.
  groupFocusVisible('group-focus-visible:'),

  /// `.peer:disabled ~ <el>` — a prior `.peer` sibling is disabled.
  peerDisabled('peer-disabled:');

  const WebPseudo(this.classPrefix);

  /// The Tailwind variant prefix used on the class path (`'hover:'`).
  final String classPrefix;

  /// Builds the scoped-rule CSS selector for this pseudo, given the
  /// element's [base] selector (`'#id'` or `'.class'`).
  String selector(String base) => switch (this) {
    hover => '$base:hover',
    hoverUnlessFocusWithin => '$base:hover:not(:focus-within)',
    hoverUnlessFocus => '$base:hover:not(:focus)',
    focus => '$base:focus',
    focusVisible => '$base:focus-visible',
    focusWithin => '$base:focus-within',
    active => '$base:active',
    disabled => '$base:disabled',
    ariaSelected => '$base[aria-selected="true"]',
    placeholder => '$base::placeholder',
    selection => '$base::selection',
    groupFocusVisible => '.group:focus-visible $base',
    peerDisabled => '.peer:disabled ~ $base',
  };
}

/// Emits a single-property pseudo-state colour ([ColorTarget.background]
/// / [ColorTarget.text] / [ColorTarget.border]) as a
/// class-XOR-scoped-rule [PseudoEmit].
///
/// Resolves `value ?? fallbackDefault`, then:
/// - token-bound (`token != null`) → Tailwind pseudo class
///   (`hover:bg-primary`), no rule (byte-identical to the pre-fallback
///   emission, so token overrides / defaults are unchanged).
/// - raw / arbitrary (`token == null`) → scoped CSS rule
///   (`#scope:hover{background-color: rgb(...);}`) keyed on
///   [scopeSelector], empty class — the fallback that lets a raw
///   override render instead of throwing `token!.name`.
///
/// [ColorTarget.ring] is NOT valid here — a focus ring is a
/// multi-property outline (plus an optional band), use
/// [focusRingClassName] / [focusRingScopedRule] instead. Callers that want to OMIT a transparent pseudo colour
/// should check `resolved.isTransparent` before calling.
///
/// [important] makes the declaration `!important` (Tailwind's `!` utility
/// modifier on the class path, `!important` on the rule path). Needed only
/// by a caller whose same element also carries that property as an INLINE
/// declaration — inline outranks any selector regardless of specificity, so
/// without it the pseudo state compiles, matches, and never paints. A caller
/// with no competing inline declaration leaves it `false`.
PseudoEmit emitPseudoColor(
  CoreColor? value,
  CoreColor fallbackDefault,
  ColorTarget target, {
  required WebPseudo pseudo,
  required String scopeSelector,
  bool important = false,
}) {
  assert(
    target != .ring,
    'ColorTarget.ring is multi-property — use focusRingScopedRule, not '
    'emitPseudoColor.',
  );
  final resolved = value ?? fallbackDefault;
  if (resolved.token != null) {
    return (
      className:
          '${pseudo.classPrefix}${important ? '!' : ''}'
          '${target.classPrefix}-${resolved.tailwindColor}',
      rule: '',
    );
  }
  return (
    className: '',
    rule:
        '${pseudo.selector(scopeSelector)}'
        '{${target.cssProperty}: ${resolved.toValue()}'
        '${important ? ' !important' : ''};}',
  );
}

/// [emitPseudoColor] for a value that follows the HOVER of a NAMED ancestor
/// group instead of the hover of the element that paints it.
///
/// For a control whose pointer target is not the element that wears the
/// colour — a hidden native `<input>` spanning a row of decorative cells
/// that are `pointer-events: none`, so a `:hover` on a cell never matches.
/// The common ancestor carries `group/[group]`, the painted elements carry
/// the class this returns.
///
/// The group is NAMED on purpose: an unnamed `group-hover:` fires when ANY
/// `.group` ancestor is hovered, so a control inside an unrelated `.group`
/// container (a card, a carousel) would light up with that container.
///
/// Resolves `value ?? fallbackDefault`, then:
/// - token-bound → Tailwind class (`group-hover/otp:border-on-surface`),
///   no rule.
/// - raw / arbitrary → scoped rule
///   `.group\/otp:hover [scopeSelector]{border-color: …;}`, empty class —
///   [scopeSelector] must name the painted elements (a per-instance class,
///   since several instances can sit on one page).
///
/// This is the plain hover. A caller whose hover step must lose to a
/// focused state does not ask the cascade to arbitrate (Tailwind v3 emits
/// `hover:` after `focus-within:`, so the hover class would win) — it stops
/// putting this class on the elements that must not step.
PseudoEmit emitGroupHoverColor(
  CoreColor? value,
  CoreColor fallbackDefault,
  ColorTarget target, {
  required String group,
  required String scopeSelector,
}) {
  assert(
    target != .ring,
    'ColorTarget.ring is multi-property — use focusRingScopedRule, not '
    'emitGroupHoverColor.',
  );
  final resolved = value ?? fallbackDefault;
  if (resolved.token != null) {
    return (
      className:
          'group-hover/$group:${target.classPrefix}-${resolved.tailwindColor}',
      rule: '',
    );
  }
  return (
    className: '',
    rule:
        '.group\\/$group:hover $scopeSelector'
        '{${target.cssProperty}: ${resolved.toValue()};}',
  );
}

/// Whether a focus-ring gap band in [offsetColor] paints anything.
///
/// The band defaults to transparent (`CoreFocusRing.ringOffsetColor`) —
/// the gap between a control and its ring shows whatever is behind the
/// control. Only a component whose background is unknown states an
/// opaque band (`CoreFocusRing.opaqueOffsetColor`). A colour paints
/// nothing when its opacity multiplier is zero or when it is a raw
/// colour whose own alpha byte is zero (the [CoreColor.transparent]
/// sentinel). A token colour is opaque until its multiplier says
/// otherwise — its value lives in the browser, not here.
bool focusBandPaints(CoreColor offsetColor) =>
    offsetColor.opacity > 0 &&
    (offsetColor.token != null || (offsetColor.argb >> 24) & 0xFF > 0);

/// Whether a focus ring's outline (width, offset, colour) can ride the
/// Tailwind `outline-*` utility classes.
///
/// `outline-{n}` / `outline-offset-{n}` exist only for the scale steps,
/// and `outline-{colour}` needs a token and carries no alpha channel. So
/// the outline stays on classes only when the ring colour is token-bound,
/// the opacity multiplier is `1.0`, and the width + offset are scale
/// steps. The band is not part of this answer — see
/// [focusRingIsClassSafe] for the whole ring.
bool focusRingOutlineIsClassSafe({
  required CoreColor ringColor,
  required double ringOpacity,
  required double ringWidth,
  required double ringOffset,
}) =>
    // Exact comparison before `toInt()`, the same guard `radiusCss` above
    // needs and for the same reason. Truncating made a deliberate 2.5
    // indistinguishable from the 2 step and emitted it — the opposite of
    // what this doc promises, and silent: the class path has no way to
    // say "2.5 did not fit". Both numbers need it; the callers that
    // derive `offset = align - width` turn one fractional override into
    // a fractional pair.
    ringColor.token != null &&
    ringOpacity >= 1.0 &&
    ringWidth == ringWidth.roundToDouble() &&
    _kTailwindOutlineScale.contains(ringWidth.toInt()) &&
    ringOffset == ringOffset.roundToDouble() &&
    _kTailwindOutlineScale.contains(ringOffset.toInt());

/// Whether a whole focus ring — outline and gap band — can ride classes.
///
/// The outline must be class-expressible
/// ([focusRingOutlineIsClassSafe]) and the band must paint nothing
/// ([focusBandPaints]): a painted band is a `box-shadow` layer, which no
/// outline utility draws, so a band-on ring always takes
/// [focusRingScopedRule]. The default transparent band needs no class at
/// all — the outline offset is a real gap.
bool focusRingIsClassSafe({
  required CoreColor ringColor,
  required CoreColor offsetColor,
  required double ringOpacity,
  required double ringWidth,
  required double ringOffset,
}) =>
    !focusBandPaints(offsetColor) &&
    focusRingOutlineIsClassSafe(
      ringColor: ringColor,
      ringOpacity: ringOpacity,
      ringWidth: ringWidth,
      ringOffset: ringOffset,
    );

/// Tailwind's `outline-{n}` / `outline-offset-{n}` scale steps.
const Set<int> _kTailwindOutlineScale = {0, 1, 2, 4, 8};

/// The focus-ring utility classes for a class-safe ring
/// ([focusRingOutlineIsClassSafe]): width, offset and colour under
/// [pseudo] — `focus-visible:outline-2 focus-visible:outline-offset-2
/// focus-visible:outline-focus-ring`.
///
/// The host carries `outline-none` unconditionally beside these — that
/// is the ring's resting state (`2px solid transparent`, offset `2px`),
/// so focusing only moves the colour (and the geometry, when it is off
/// the default) and the ring fades on whatever transition the host owns
/// instead of flipping `outline-style`. The `2` steps route through
/// `--coui-ring-width` / `--coui-ring-offset` (`ThemeConfig`'s
/// `outlineWidth` / `outlineOffset` config).
///
/// The ring is an outline rather than a `box-shadow` so the gap between
/// control and ring is a real gap: an outline offset is never painted,
/// so whatever is behind the control shows through it.
String focusRingClassName({
  required WebPseudo pseudo,
  required CoreColor ringColor,
  required double ringWidth,
  required double ringOffset,
}) =>
    '${pseudo.classPrefix}outline-${ringWidth.toInt()} '
    '${pseudo.classPrefix}outline-offset-${ringOffset.toInt()} '
    '${pseudo.classPrefix}outline-${ringColor.tailwindColor}';

/// The focus ring's two lengths as CSS — the outline's width and its
/// offset (the gap between the control's border box and the ring).
///
/// The single place a ring's geometry becomes CSS, for every host that
/// does not ride the class path: the scoped rule, the gap band, and
/// `FocusOutline`'s inline wrapper chrome all read these two strings.
///
/// The width is a stroke-axis value, so it rides [strokeWidthCss] — px
/// fixed (a focus ring is a line, not a layout dimension, so it does not
/// grow with the browser's text size) and routed through
/// `--coui-stroke-width-N`, so a surface style's stroke floor reaches it
/// the way Flutter's `theme.geometry.stroke` reaches the same field. The
/// ring's outer edge stays where the caller put it ([ringOffset] +
/// [ringWidth]), so the offset is that edge minus whatever the width
/// resolves to — a subtraction that has to run in the browser, via
/// `calc()`, because the variable resolves only there.
///
/// The class path (`outline-2` / `outline-offset-2`) reads
/// `--coui-ring-width` / `--coui-ring-offset` instead, which are fixed px
/// values a stroke floor does not move.
({String width, String offset}) focusRingGeometryCss({
  required double ringWidth,
  required double ringOffset,
}) {
  final width = strokeWidthCss(ringWidth);
  // A width off the stroke scale is a literal, nothing can move it, so the
  // offset is the literal too.
  if (!width.startsWith('var(')) {
    final n = ringOffset.toInt();
    return (
      width: width,
      offset: ringOffset == n ? '${n}px' : '${ringOffset}px',
    );
  }
  return (width: width, offset: 'calc(${ringOffset + ringWidth}px - $width)');
}

/// The CSS value the class path's `outline-offset-{n}` resolves to — the
/// `--coui-ring-offset` variable at the default step (`ThemeConfig`'s
/// `outlineOffset` extension), Tailwind's own `{n}px` at every other
/// scale step.
///
/// For a gap band composed beside a class-path outline: the band has to
/// be exactly as wide as the gap the class leaves, so it reads the same
/// value the class does rather than re-deriving it.
String focusRingClassOffsetCss(double ringOffset) =>
    ringOffset == CoreFocusRing.ringOffset
    ? 'var(--coui-ring-offset)'
    : '${ringOffset.toInt()}px';

/// A focus ring's CSS declarations — `outline-color`, `outline-width`,
/// `outline-offset` and, when [bandColor] is given, the gap band as one
/// `box-shadow` spread layer exactly as wide as the offset.
///
/// The colours arrive as CSS values so a host that animates them (the
/// `FocusOutline` wrapper fades the same triplet between ` / 0` and its
/// active alpha) and a host that states them once (the scoped rule) share
/// one emitter for everything else. [restShadow] — a `box-shadow` value
/// the host shows at rest — is composed after the band so the band does
/// not erase it; it is ignored when no band paints, and the host keeps its
/// own `box-shadow` untouched.
Map<String, String> focusRingDeclarations({
  required String ringColor,
  required double ringWidth,
  required double ringOffset,
  String? bandColor,
  String restShadow = '',
}) {
  final geometry = focusRingGeometryCss(
    ringWidth: ringWidth,
    ringOffset: ringOffset,
  );
  return {
    'outline-color': ringColor,
    'outline-width': geometry.width,
    'outline-offset': geometry.offset,
    if (bandColor != null)
      'box-shadow':
          '0 0 0 ${geometry.offset} $bandColor'
          '${restShadow.isEmpty ? '' : ', $restShadow'}',
  };
}

/// The gap band as one `box-shadow` layer — a solid [offsetColor] ring
/// [gap] wide hugging the control's border box.
///
/// [gap] is the exact value the ring's outline offset resolves to, in the
/// same unit — [focusRingGeometryCss]'s offset beside a scoped outline,
/// [focusRingClassOffsetCss] beside a class-path one — so the band fills
/// the gap to the pixel at any root font size and under any stroke floor.
///
/// Only meaningful when [focusBandPaints]; a host that composes it with
/// its own resting shadow puts it first so the band paints on top.
String focusBandShadow({
  required CoreColor offsetColor,
  required String gap,
}) => '0 0 0 $gap ${offsetColor.toValue()}';

/// The custom property `Button` publishes its gap band in when the band
/// paints — read by the shared control focus rule in `ThemeConfig`,
/// which composes it over the button's resting shadow (an inline
/// `box-shadow` no selector can reach without `!important`).
const String kFocusBandVar = '--coui-focus-band';

/// Marks a control whose gap band paints — gates the shared control
/// focus rule in `ThemeConfig` to the controls that state a band, so a
/// band-less button keeps its own resting shadow untouched when focused.
const String kFocusBandMarker = 'coui-focus-band';

/// Marks the strip that holds the `Diff` handle — the full-height column
/// that takes the pointer. Hovering it lifts the handle's cast.
///
/// The state looks of the handle ride marker classes and custom properties
/// rather than an id and a scoped `<style>`: the values are fixed strings
/// for a given style, so the server and client markup agree, and the
/// shared `ThemeConfig` rule reads them on `:hover` and while the root
/// carries [kDiffDraggingAttribute].
const String kDiffHandleStripMarker = 'coui-diff-handle-strip';

/// Marks the focus-ring host around the `Diff` handle — the element that
/// shrinks while the handle is held (the ring shrinks with the disc, as in
/// the Flutter twin where the scale wraps the ring).
const String kDiffHandleMarker = 'coui-diff-handle';

/// Marks the `Diff` handle disc — the element whose cast changes between
/// rest, hover and held.
const String kDiffHandleDiscMarker = 'coui-diff-handle-disc';

/// Attribute a `Diff` root carries while a pointer holds the split. A
/// semantic state, read by the shared `ThemeConfig` rule.
const String kDiffDraggingAttribute = 'data-coui-dragging';

/// The handle's cast at rest, published on the strip.
const String kDiffHandleShadowVar = '--coui-diff-handle-shadow';

/// The handle's cast while the pointer is over the strip.
const String kDiffHandleHoverShadowVar = '--coui-diff-handle-shadow-hover';

/// The handle's cast while it is held.
const String kDiffHandlePressedShadowVar = '--coui-diff-handle-shadow-pressed';

/// How far the handle shrinks while held, as a ratio of its own size.
const String kDiffHandlePressedScaleVar = '--coui-diff-handle-pressed-scale';

/// The time the handle takes between rest, hover and held.
const String kDiffHandleDurationVar = '--coui-diff-handle-duration';

/// The custom property a text input's box publishes its focused active
/// boundary in — the whole inset `box-shadow` layer
/// (`inset 0 0 0 <added width> <colour>`), read by the shared
/// `ThemeConfig` rule while the box is focused.
///
/// A value, not a scoped rule: the layer is a per-instance value (the
/// width difference and the focus colour, token or raw), and carrying it
/// inline keeps the box free of an id and a `<style>` element. The value
/// is a fixed string for a given style, so the server and client markup
/// agree.
const String kActiveBoundaryVar = '--coui-active-boundary';

/// Marks a text input box that draws its focused active boundary on its
/// own `:focus-visible` — the bare `<input>` / `<textarea>`, which is the
/// focused element itself.
///
/// Present only when there is a boundary to widen on focus (not the bare
/// `plain` variant, not an error box — its boundary rides inline — not a
/// disabled box, not an active width no wider than the resting border,
/// not a focus colour that paints nothing), so a box without it keeps its
/// `box-shadow` untouched when focused.
const String kActiveBoundaryMarker = 'coui-active-boundary';

/// The [kActiveBoundaryMarker] twin for the affix wrapper — a box whose
/// focusable `<input>` / `<textarea>` sits inside it, so the boundary
/// rides `:focus-within`.
const String kActiveBoundaryWithinMarker = 'coui-active-boundary-within';

/// The custom property a control publishes its hover state layer in — the
/// layer colour already at the ramp's hover weight (`rgb(var(--coui-X) / 8%)`),
/// read by the shared `ThemeConfig` rule while the pointer is over the box.
///
/// A value, not a scoped rule: it is a fixed string for a given style, so the
/// box needs no id and no `<style>` element, and the server and client markup
/// agree.
const String kStateLayerHoverVar = '--coui-state-layer-hover';

/// Marks a box that wears a hover state layer.
///
/// The layer is laid as a `background-image` over the box's own
/// `background-color`, so it takes the box's shape and sits over whichever
/// face the box wears — the chosen segment's raised face, the edited
/// segment's primary-container face — without touching the face colour or
/// the border. Present only while the box can be pressed (a disabled box
/// carries none).
const String kStateLayerHoverMarker = 'coui-state-layer-hover';

/// Builds the scoped focus-ring CSS for values that have no class (a raw
/// override colour, a sub-1 [ringOpacity], an off-scale width / offset,
/// or a painted band — see [focusRingIsClassSafe]).
///
/// Three rules, each with one job:
///
/// - `<base>{outline-color:transparent;}` — the resting colour, so the
///   ring fades from nothing instead of from the text colour
///   (`currentColor`, the initial value) on whatever `outline-color`
///   transition the host owns.
/// - `:where(<base>){outline-style:solid;}` — the outline is on at rest,
///   transparent, so focusing moves only its colour and blurring fades it
///   back out instead of dropping `outline-style` to `none` (which stops
///   painting the outline in the same frame, leaving the colour transition
///   nothing to show). Zero specificity on purpose: under forced colours
///   the root rule `.coui-root :not(:focus-visible){outline-style:none;}`
///   must still win on a ring that sits on an element other than the
///   focused one ([target], `:focus-within`, a group ancestor), or the
///   platform paints a second ring beside the one it draws on the focused
///   element.
/// - the focused rule — [focusRingDeclarations]: the ring itself, plus the
///   band when [focusBandPaints], composed over [restShadow].
///
/// The [pseudo] gates when the ring paints; [scopeSelector] is the
/// element's base selector. Colours emit theme-free (`token →
/// rgb(var(--coui-X))`, raw → `rgb(...)`); [ringOpacity] scales the ring
/// colour's alpha (the class path cannot express it).
///
/// [target] is a selector appended after the pseudo-class — for a ring
/// that stands around a descendant of the focusable element rather than
/// around the element itself (`Checkbox`: `:focus-visible` lands on the
/// `Clickable` root, the ring hugs the box one level in). Empty by
/// default.
String focusRingScopedRule({
  required String scopeSelector,
  required WebPseudo pseudo,
  required CoreColor ringColor,
  required CoreColor offsetColor,
  required double ringWidth,
  required double ringOffset,
  required double ringOpacity,
  @Deprecated(
    'Ignored (since 0.159) — the ring is an outline, which no inline '
    'box-shadow competes with, so it needs no !important.',
  )
  bool important = false,
  String target = '',
  String restShadow = '',
}) {
  final base = '$scopeSelector$target';
  final focused = '${pseudo.selector(scopeSelector)}$target';
  final ring = ringOpacity >= 1.0
      ? ringColor.toValue()
      : ringColor.scaleAlpha(ringOpacity).toValue();
  final declarations = focusRingDeclarations(
    ringColor: ring,
    ringWidth: ringWidth,
    ringOffset: ringOffset,
    bandColor: focusBandPaints(offsetColor) ? offsetColor.toValue() : null,
    restShadow: restShadow,
  );
  final body = StringBuffer();
  declarations.forEach((property, value) => body.write('$property:$value;'));
  return '$base{outline-color:transparent;}'
      ':where($base){outline-style:solid;}'
      '$focused{$body}';
}

/// The CSS value of a state-layer wash — [ink] laid over [base] at
/// [weight] — as a `color-mix()`, so the two tokens stay tokens and the
/// browser composites them at runtime (dark-mode reactive, the same way
/// the platform composites `CoreStateLayer` weights on Flutter with
/// `Color.alphaBlend` against scheme-resolved colours).
///
/// The base keeps its own alpha (it is literally what is painted at rest —
/// `transparent` included, via `.toValue()`'s raw-colour fallback). The
/// ink drops its own alpha — the state-layer WEIGHT is what governs the
/// blend ratio, not whatever alpha the ink happened to carry.
String stateLayerWashCss({
  required CoreColor ink,
  required CoreColor base,
  required double weight,
}) {
  final inkToken = ink.token?.name;
  final inkCss = inkToken != null
      ? 'rgb(var(--coui-$inkToken))'
      : 'rgb(${ink.red}, ${ink.green}, ${ink.blue})';
  return 'color-mix(in srgb, $inkCss ${(weight * 100).round()}%, '
      '${base.toValue()})';
}

/// The [surfaceFillVar] form of a state-layer wash — what a marked surface
/// publishes while a state holds, so a style preset restates the washed
/// fill at its material's share the way it restates the resting one.
///
/// A preset's material rule paints `rgb(<triplet> / calc(<alpha> × share))`
/// from these two properties and outranks the state rule's own
/// `background-color`, so a wash written only as a colour would be lost
/// under the material — or, written `!important`, would paint the box
/// opaque while its backdrop still frosts. The wash is a `color-mix()`, not
/// a token, so the triplet is spelled with relative colour syntax
/// (`from <wash> r g b`), which drops into the rule's `rgb(… / …)` as
/// `rgb(from <wash> r g b / …)`. The alpha is the wash's own — the ink at
/// [weight] over the base at its alpha (`w + a × (1 − w)`) — because the
/// relative form keeps the channels and takes the alpha from the rule.
/// Together they are the Flutter twin's
/// `materialFill(alphaBlend(ink @ w, base))`. Only a material rule reads
/// them, so a browser without relative colour syntax loses the restated
/// fill under a translucent preset alone; every other style paints the
/// state rule's own colour.
///
/// Empty when [base] is not token-bound, for the reason [surfaceFillVar]
/// is: a raw fill rides inline, and a preset does not restate it.
Map<String, String> stateLayerWashFillVar({
  required CoreColor ink,
  required CoreColor base,
  required double weight,
}) {
  if (base.token == null) return const {};

  // The two terms as the CSS reads them — the weight rounded to the whole
  // percent `stateLayerWashCss` writes, the base alpha truncated the way
  // `toValue()` writes it — so the alpha agrees with the colour beside it.
  final w = (weight * kPercentScale).round() / kPercentScale;
  final a = base.opacity < 1
      ? (base.opacity * kPercentScale).toInt() / kPercentScale
      : 1.0;
  final wash = stateLayerWashCss(ink: ink, base: base, weight: weight);

  return {
    kWebSurfaceFillVar: 'from $wash r g b',
    kWebSurfaceFillAlphaVar: _fraction(w + a * (1 - w)),
  };
}

/// The ARIA `role` attribute value for a [CoreSemanticRole].
///
/// Web is the wider of the two platforms here — every value in the
/// enum has an ARIA spelling, so this switch never returns null. The
/// asymmetry lives entirely on the Flutter side, which is where
/// [CoreSemanticRole.support] is read.
///
/// The switch is exhaustive on purpose: adding a value to the enum
/// breaks this file until Web states an answer, which is the
/// compile-time equivalent of the "make the redefinition point
/// required" rule in `core/theme-axis-composition.md`.
extension CoreSemanticRoleToAria on CoreSemanticRole {
  /// This role's ARIA spelling — lower-case and unspaced, which is why
  /// several differ from the Dart identifier.
  String get ariaRole => switch (this) {
    .tabList => 'tablist',
    .tab => 'tab',
    .tabPanel => 'tabpanel',
    .dialog => 'dialog',
    .menu => 'menu',
    .menuBar => 'menubar',
    .menuItem => 'menuitem',
    .menuItemCheckbox => 'menuitemcheckbox',
    .menuItemRadio => 'menuitemradio',
    .list => 'list',
    .listItem => 'listitem',
    .radioGroup => 'radiogroup',
    .progressBar => 'progressbar',
    .table => 'table',
    .grid => 'grid',
    .row => 'row',
    .cell => 'cell',
    .gridCell => 'gridcell',
    .columnHeader => 'columnheader',
    .main => 'main',
    .navigation => 'navigation',
    .region => 'region',
    .contentInfo => 'contentinfo',
    .button => 'button',
    .link => 'link',
    .image => 'img',
    .checkbox => 'checkbox',
    .radio => 'radio',
    .toggleSwitch => 'switch',
    .textbox => 'textbox',
    .slider => 'slider',
    .separator => 'separator',
    .scrollbar => 'scrollbar',
    .banner => 'banner',
    .group => 'group',
    .presentation => 'presentation',
    .application => 'application',
    .listBox => 'listbox',
    .option => 'option',
    .tree => 'tree',
    .treeItem => 'treeitem',
    .toolbar => 'toolbar',
    .tooltip => 'tooltip',
    .comboBox => 'combobox',
    .status => 'status',
    .alert => 'alert',
  };
}

/// Core → CSS: a morph silhouette as a `clip-path` value.
extension CoreLiquidMorphOutlineToCss on CoreLiquidMorphOutline {
  /// The outline as `path("…")`, ready for `clip-path`.
  ///
  /// Carving the shape rather than filtering it is not a style choice. An
  /// ancestor `filter` — the obvious way to merge two blobs on the Web —
  /// establishes a new backdrop root, so a glass panel inside it samples
  /// the filtered ancestor instead of the page and renders opaque. That was
  /// measured. `clip-path` leaves the backdrop alone.
  ///
  /// Coordinates are rounded to hundredths. At 96 grid cells the walk emits
  /// a few hundred points, and full `double` precision would put ~17
  /// characters into each of ~600 numbers — a string large enough to matter
  /// when it is rewritten every frame, describing sub-nanometre differences
  /// no display can show.
  ///
  /// Empty when the walk found no crossing, and the caller must then omit
  /// the declaration rather than emit `path("")`: an empty path clips
  /// everything away, so a shape that failed to trace would render as a
  /// missing panel rather than an unclipped one.
  String toInlineCss() {
    if (isEmpty) return '';

    // One subpath per loop. `path()` unions them under its default
    // non-zero fill rule, which is what the field says is there: for part
    // of the flight the silhouette genuinely is two bodies, and drawing
    // only the first one carved the panel down to whichever the grid scan
    // reached first.
    final buffer = StringBuffer('path("');
    var first = true;
    for (final contour in contours) {
      if (contour.isEmpty) continue;

      if (!first) buffer.write(' ');
      first = false;
      buffer
        ..write('M ')
        ..write(contour.first.x.toStringAsFixed(2))
        ..write(' ')
        ..write(contour.first.y.toStringAsFixed(2));
      for (final point in contour.skip(1)) {
        buffer
          ..write(' L ')
          ..write(point.x.toStringAsFixed(2))
          ..write(' ')
          ..write(point.y.toStringAsFixed(2));
      }
      buffer.write(' Z');
    }
    if (first) return '';

    return (buffer..write('")')).toString();
  }
}

/// A control row's height (logical px) as a CSS length.
///
/// A rung of the control ladder (`CoreControlSize.isRung`) becomes
/// `var(--coui-control-height-N)`, the variable a density re-points; any
/// other value is a literal `rem` the density cannot reach — the same
/// split `radiusCss` makes for corners, for the same reason.
String controlHeightCss(double px) {
  if (CoreControlSize.isRung(px)) {
    return 'var(--coui-control-height-${px.toInt()})';
  }

  return _rem(px);
}
