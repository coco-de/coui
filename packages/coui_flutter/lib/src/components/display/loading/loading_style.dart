import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';

// Degrees in half a turn, for the degrees → radians conversion of the arc.
const _kHalfTurnDegrees = 180.0;

/// Resolver output for [Loading].
///
/// Single struct that the widget reads — every field has had the
/// nested merge chain applied plus `CoreLoadingStyle.defaultX` /
/// `defaultsByVariant[variant]` fallback and type conversion.
class ResolvedLoading {
  /// Creates a [ResolvedLoading].
  const ResolvedLoading({
    required this.size,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
    required this.arcSweep,
    required this.dotSize,
    required this.dotGap,
    required this.barLength,
    required this.barHeight,
    required this.barFillRatio,
    required this.pulseDotSize,
    required this.pulseHaloAlpha,
    required this.cornerRadius,
    required this.haloCornerRadius,
    required this.duration,
  });

  /// Effective indicator pixel size (logical px).
  final double size;

  /// Effective indicator colour (already resolved against the active
  /// `ColorScheme`).
  final Color color;

  /// Effective track / background ring colour. When the user did not
  /// supply [CoreLoadingStyle.trackColor], this is [color] faded by
  /// [CoreLoadingStyle.trackAlpha] (falling back to
  /// [CoreLoadingStyle.defaultTrackAlpha]).
  final Color trackColor;

  /// Spinner ring stroke width (logical px). Other variants ignore
  /// this value.
  final double strokeWidth;

  /// Spinner arc sweep in radians (a quarter turn).
  final double arcSweep;

  /// `dots` diameter (logical px, scaled).
  final double dotSize;

  /// `dots` gap between neighbouring dots (logical px, scaled) — [dotSize]
  /// times [CoreLoadingStyle.dotGapRatio].
  final double dotGap;

  /// `bar` track length (logical px, scaled) — a multiple of [size].
  final double barLength;

  /// `bar` track thickness (logical px, scaled).
  final double barHeight;

  /// `bar` moving fill as a fraction of [barLength].
  final double barFillRatio;

  /// `pulse` centre dot diameter (logical px, scaled).
  final double pulseDotSize;

  /// `pulse` halo opacity at the start of a beat (`0.0`–`1.0`).
  final double pulseHaloAlpha;

  /// Paint-ready corner radius of the `pulse` halo (the full [size] circle).
  final BorderRadius haloCornerRadius;

  /// Paint-ready corner radius for the `dots` / `pulse` / `bar` shapes.
  ///
  /// The resolver clamps the `cornerRadius` override against the
  /// variant's half-extent (so the design-system default
  /// `radius9999` lands on a perfectly round shape and smaller
  /// overrides flatten the corners) and wraps it in
  /// `BorderRadius.circular(...)`. The `spinner` variant strokes a
  /// circle and ignores this field (it carries `BorderRadius.zero`).
  final BorderRadius cornerRadius;

  /// Effective animation cycle duration for the current variant.
  final Duration duration;
}

/// Resolves [ResolvedLoading] for the given [context].
///
/// Single entry point — `co_loading.dart` must not call
/// `theme.coreComponentTheme.loading` directly nor invoke
/// `CoreLoadingStyle.merge(...)` outside this function. All fallback
/// chains terminate at `coui_core`'s [CoreLoadingStyle] static const
/// defaults / [CoreLoadingStyle.defaultsByVariant].
ResolvedLoading resolveLoading(
  BuildContext context, {
  required CoreLoadingVariant variant,
  CoreLoadingTone tone = CoreLoadingTone.defaultTone,
  CoreComponentSize? componentSize,
  CoreLoadingStyle? loadingStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final compTheme = theme.coreComponentTheme?.loading;

  // Two-stage merge chain (theme.style → theme.variantStyles[variant]
  // → widget.loadingStyle).
  final merged = resolveStyleChain(const CoreLoadingStyle(), [
    compTheme?.style,
    compTheme?.variantStyles?[variant],
    loadingStyle,
  ]);

  // ── size ──
  final double rawSize;
  if (merged.size != null) {
    rawSize = merged.size!;
  } else if (componentSize != null) {
    rawSize = CoreLoadingStyle.defaultsBySize[componentSize]!.size!;
  } else {
    rawSize = CoreLoadingStyle.defaultSize;
  }
  final effectiveSize = rawSize * scaling; // scaled-shared

  // ── color ──
  final toneStyle = CoreLoadingStyle.defaultsByTone[tone]!;
  final effectiveColor = scheme
      .resolve(merged.color ?? toneStyle.color!)
      .toValue();

  // ── trackColor ──
  // A stated track colour, else a stated alpha of the arc colour, else the
  // tone's own track (a neutral token, or the arc colour faded for the
  // inverse tone).
  final mergedTrackColor = merged.trackColor;
  final toneTrackColor = toneStyle.trackColor;
  final effectiveTrackColor = mergedTrackColor != null
      ? scheme.resolve(mergedTrackColor).toValue()
      : merged.trackAlpha == null && toneTrackColor != null
      ? scheme.resolve(toneTrackColor).toValue()
      : effectiveColor.scaleAlpha(
          merged.trackAlpha ??
              toneStyle.trackAlpha ??
              CoreLoadingStyle.defaultTrackAlpha,
        );

  // ── strokeWidth ──
  final strokeWidth = theme.geometry.stroke(
    merged.strokeWidth ??
        (componentSize == null
            ? CoreLoadingStyle.defaultStrokeWidth
            : CoreLoadingStyle.defaultsBySize[componentSize]!.strokeWidth!),
    scaling: scaling,
  );

  // ── spinner arc sweep ──
  const arcSweep =
      CoreLoadingStyle.defaultArcSweepDegrees * math.pi / _kHalfTurnDegrees;

  // ── shape geometry ──
  // A size step states its own dot and track; a stated pixel size with no
  // step keeps the proportions instead (and with neither, the `xs` step's).
  final stepStyle = componentSize != null
      ? CoreLoadingStyle.defaultsBySize[componentSize]!
      : null;
  final sizeStated = merged.size != null;
  final dotSize =
      (merged.dotSize ??
          stepStyle?.dotSize ??
          (sizeStated
              ? rawSize * CoreLoadingStyle.defaultDotSizeRatio
              : CoreLoadingStyle.defaultDotSize)) *
      scaling;
  final dotGap = dotSize * CoreLoadingStyle.dotGapRatio;
  final barHeight =
      (merged.barHeight ??
          stepStyle?.barHeight ??
          (sizeStated
              ? rawSize * CoreLoadingStyle.defaultBarHeightRatio
              : CoreLoadingStyle.defaultBarHeight)) *
      scaling;
  final barLength = effectiveSize * CoreLoadingStyle.defaultBarLengthRatio;
  final pulseDotSize = effectiveSize * CoreLoadingStyle.defaultPulseDotRatio;
  const barFillRatio = CoreLoadingStyle.defaultBarFillRatio;
  const pulseHaloAlpha = CoreLoadingStyle.defaultPulseHaloAlpha;

  // ── cornerRadius ──
  // Resolve the override (else design-system default `radius9999`), then
  // clamp it to each shape's own half-extent so the result is paint-ready:
  // a dot / the pulse's centre dot clamp to their radius, the bar to half its
  // track thickness, the pulse halo to half the indicator. `spinner` strokes a
  // circle and carries no rounded rect.
  final cornerRadiusValue =
      theme.geometry.radius(
        merged.cornerRadius ?? CoreLoadingStyle.defaultCornerRadius,
      ) *
      scaling;
  final effectiveCornerRadius = switch (variant) {
    .spinner => BorderRadius.zero,
    .dots => BorderRadius.circular(math.min(cornerRadiusValue, dotSize / 2)),
    .bar => BorderRadius.circular(math.min(cornerRadiusValue, barHeight / 2)),
    .pulse => BorderRadius.circular(
      math.min(cornerRadiusValue, pulseDotSize / 2),
    ),
  };
  final haloCornerRadius = BorderRadius.circular(
    math.min(cornerRadiusValue, effectiveSize / 2),
  );

  // ── duration ──
  final variantDefaults = CoreLoadingStyle.defaultsByVariant[variant]!;
  final effectiveDuration = resolveMotionDuration(
    context,
    merged.duration ?? variantDefaults.duration,
  );

  return ResolvedLoading(
    size: effectiveSize,
    color: effectiveColor,
    trackColor: effectiveTrackColor,
    strokeWidth: strokeWidth,
    arcSweep: arcSweep,
    dotSize: dotSize,
    dotGap: dotGap,
    barLength: barLength,
    barHeight: barHeight,
    barFillRatio: barFillRatio,
    pulseDotSize: pulseDotSize,
    pulseHaloAlpha: pulseHaloAlpha,
    cornerRadius: effectiveCornerRadius,
    haloCornerRadius: haloCornerRadius,
    duration: effectiveDuration,
  );
}
