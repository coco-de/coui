import 'package:coui_flutter/coui_flutter.dart';

/// Resolved styling values for [FocusOutline].
class ResolvedFocusOutline {
  /// Creates the paint-ready outline values.
  const ResolvedFocusOutline({
    required this.align,
    required this.borderColor,
    required this.borderWidth,
    required this.circleBorderRadius,
    required this.duration,
    this.borderStyle = BorderStyle.solid,
    this.borderRadius,
    this.offsetColor,
  });

  /// Distance between child edge and ring outer edge (px).
  final double align;

  /// Optional border-radius override.
  final BorderRadiusGeometry? borderRadius;

  /// Ring color.
  final Color borderColor;

  /// Ring width (px).
  final double borderWidth;

  /// No stroke for zero width.
  ///
  /// Flutter otherwise paints a device-pixel hairline.
  final BorderStyle borderStyle;

  /// Border radius applied when [FocusOutline.shape] is circle —
  /// any radius ≥ half the longest edge produces a circle. Flows from
  /// the design-system default (all-9999) via the merge chain so
  /// designer overrides apply.
  final BorderRadiusGeometry circleBorderRadius;

  /// Gap band colour — stroked in the gap between the child's edge and
  /// the ring's inner edge, never behind the child. `null` draws no band
  /// layer at all; a transparent colour (the design-system default) keeps
  /// the layer but lets whatever is behind the control show through the
  /// gap. Components whose background is unknown state an opaque band.
  final Color? offsetColor;

  /// Animation duration.
  final Duration duration;
}

/// Resolves [ResolvedFocusOutline] for [FocusOutline].
///
/// Priority (per-field):
/// `widgetStyle` (CoreFocusOutlineStyle) >
/// `CoreFocusOutlineTheme.style` >
/// design-system default. Animation timing flows through
/// `CoreFocusOutlineStyle.duration` — Epic #1370 Phase 4 removed
/// the legacy `CoreFocusOutlineTheme.duration` flat field.
ResolvedFocusOutline resolveFocusOutline(
  BuildContext context, {
  CoreFocusOutlineStyle? widgetStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final coreTheme = theme.coreComponentTheme?.focusOutline;

  // Merge chain: theme.style → widgetStyle.
  final merged = resolveStyleChain(const CoreFocusOutlineStyle(), [
    coreTheme?.style,
    widgetStyle,
  ]);

  // `ringOpacity` is a multiplier applied on top of whichever
  // `borderColor` is in effect (default or per-instance override) — the
  // single place this happens, so it is applied exactly once regardless
  // of colour source (#2128 platform parity; see
  // `CoreFocusOutlineStyle.defaultRingOpacity`).
  //
  // Stage1 RESOLVE + Stage2 EMIT (incl. `* scaling`) all happen in
  // locals; the return literal below is a bare mapping (canonical
  // chaining position — resolver-pattern.md).
  final align = (merged.align ?? CoreFocusOutlineStyle.defaultAlign) * scaling;
  final borderWidth = theme.geometry.stroke(
    merged.borderWidth ?? CoreFocusOutlineStyle.defaultBorderWidth,
    scaling: scaling,
  );
  // `* scaling` here is deliberate and stays: it is the same treatment
  // `borderRadius` two lines down gets, and the same `align` /
  // `borderWidth` above get. Web carries no `* scaling` on either radius
  // field because its transport is a CSS variable that already reacts to
  // the root font size — a logical-px value has to be pre-scaled, a
  // `var(--coui-radius-N)` must not be (`resolver/scaling-and-gap.md`).
  // Dropping it to "match Web" numerically would leave this resolver
  // internally split, with the circle radius unscaled next to a scaled
  // rectangle radius on the same ring.
  final rawCircleBorderRadius =
      (merged.circleBorderRadius ??
              CoreFocusOutlineStyle.defaultCircleBorderRadius)
          .toValue(geometry: theme.geometry);
  // `theme.geometry.radius()` preserves a raw `CoreRadius.radius9999`
  // input unchanged (the pill-preservation branch Range/Badge rely on
  // to stay fully round under a non-zero cap) — but this field's
  // default is the *same* 9999 sentinel used purely as "make this ring
  // circular", not a pill shape stating its own roundness. A capping
  // preset should cap this one too ("a preset that squares corners
  // keeps the circle ring square"), so the cap is re-applied here,
  // once, rather than teaching the shared `radius()` function a
  // purpose it does not otherwise know about.
  final circleCap = theme.geometry.radiusCap;
  final circleBorderRadius =
      (circleCap == null
          ? rawCircleBorderRadius
          : BorderRadius.only(
              topLeft: Radius.circular(
                rawCircleBorderRadius.topLeft.x > circleCap
                    ? circleCap
                    : rawCircleBorderRadius.topLeft.x,
              ),
              topRight: Radius.circular(
                rawCircleBorderRadius.topRight.x > circleCap
                    ? circleCap
                    : rawCircleBorderRadius.topRight.x,
              ),
              bottomLeft: Radius.circular(
                rawCircleBorderRadius.bottomLeft.x > circleCap
                    ? circleCap
                    : rawCircleBorderRadius.bottomLeft.x,
              ),
              bottomRight: Radius.circular(
                rawCircleBorderRadius.bottomRight.x > circleCap
                    ? circleCap
                    : rawCircleBorderRadius.bottomRight.x,
              ),
            )) *
      scaling;
  // Rectangle radius override — null keeps the focus ring square.
  final mergedBorderRadius = merged.borderRadius?.toValue(
    geometry: theme.geometry,
  );
  final borderRadius = mergedBorderRadius == null
      ? null
      : mergedBorderRadius * scaling;
  final ringOpacity =
      merged.ringOpacity ?? CoreFocusOutlineStyle.defaultRingOpacity;
  final borderColor = scheme
      .resolve(
        (merged.borderColor ?? CoreFocusOutlineStyle.defaultBorderColor)
            .scaleAlpha(ringOpacity),
      )
      .toValue();
  final duration = resolveMotionDuration(
    context,
    merged.duration ?? CoreFocusOutlineStyle.defaultDuration,
  );
  // Gap band — null draws no band layer. The default slots carry the
  // transparent design-system default, so the gap is a real gap unless a
  // component states an opaque band.
  final offsetColor = merged.offsetColor == null
      ? null
      : scheme.resolve(merged.offsetColor!).toValue();

  return ResolvedFocusOutline(
    align: align,
    borderColor: borderColor,
    borderWidth: borderWidth,
    borderStyle: borderWidth == 0 ? BorderStyle.none : BorderStyle.solid,
    circleBorderRadius: circleBorderRadius,
    duration: duration,
    borderRadius: borderRadius,
    offsetColor: offsetColor,
  );
}
