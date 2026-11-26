import 'package:coui_flutter/coui_flutter.dart';

/// Resolver output for [Skeleton].
///
/// Single struct that the widget reads — every field has had the nested
/// merge chain applied plus `CoreSkeletonStyle.defaultX` /
/// `defaultsByVariant[variant]` fallback and type conversion.
class ResolvedSkeleton {
  /// Creates a [ResolvedSkeleton].
  const ResolvedSkeleton({
    required this.backgroundColor,
    required this.pulseFromColor,
    required this.pulseToColor,
    required this.borderRadius,
    required this.duration,
    required this.curve,
    required this.pulses,
    required this.fromOpacity,
    required this.toOpacity,
    required this.lineSpacing,
    required this.lineHeight,
    required this.scaledWidth,
    required this.scaledHeight,
    required this.lastLineWidth,
    required this.lines,
    required this.border,
  });

  /// Skeleton fill colour at full strength — the colour the two pulse
  /// ends scale. The widget paints [pulseFromColor] / [pulseToColor], not
  /// this.
  final Color backgroundColor;

  /// The fill at the resting end of the pulse: the fill's own alpha
  /// multiplied by [fromOpacity] (`CoreColor.scaleAlpha`) — Web's
  /// `--pulse-from`.
  final Color pulseFromColor;

  /// The fill at the peak of the pulse: the fill's own alpha multiplied by
  /// [toOpacity] (`CoreColor.scaleAlpha`) — Web's `--pulse-to`.
  final Color pulseToColor;

  /// Resolved border radius (already scaling-multiplied).
  final BorderRadius borderRadius;

  /// Length of one full pulse — rest → peak → rest. The widget runs it as
  /// one controller period split into those two halves, the way Web runs
  /// it as one keyframe cycle.
  final Duration duration;

  /// Easing of each half of the pulse, applied forward to both — the way a
  /// CSS timing function applies per keyframe interval.
  final Curve curve;

  /// Whether the pulse runs. `false` under reduced motion
  /// (`CoreReducedMotion.runsPlaceholderPulse`): the widget then holds
  /// [pulseFromColor], the resting end, instead of cycling.
  final bool pulses;

  /// The factor multiplied into the fill's alpha at the resting end of the
  /// pulse (0.0 – 1.0). Already applied in [pulseFromColor], which is what
  /// the widget paints.
  final double fromOpacity;

  /// The factor multiplied into the fill's alpha at the peak of the pulse
  /// (0.0 – 1.0). Already applied in [pulseToColor], which is what the
  /// widget paints.
  final double toOpacity;

  /// Gap between text-variant lines (logical px, scaling pre-applied)
  /// — consumed by `Column.spacing` directly. Epic #1659 D-cat —
  /// N-sibling uniform distribution pattern.
  final double lineSpacing;

  /// Per-line height for the text variant (logical px, scaling
  /// pre-applied). Paint-ready value the widget hands straight to
  /// `Container.height`.
  final double lineHeight;

  /// User-supplied [Skeleton.width] with scaling pre-applied, or
  /// `null` when the user did not supply a width.
  final double? scaledWidth;

  /// User-supplied [Skeleton.height] with scaling pre-applied, or
  /// `null` when the user did not supply a height.
  final double? scaledHeight;

  /// Width fraction of the last line in text variant (0.0 – 1.0).
  final double lastLineWidth;

  /// Number of lines for text variant.
  final int lines;

  /// The boundary the active surface style contributes, or `null` under
  /// every style that contributes none.
  ///
  /// A skeleton authors no border of its own, so the style's stroke floor
  /// has nothing to lift and this is the only route by which a boxed
  /// style reaches it.
  final Border? border;
}

/// Resolves [ResolvedSkeleton] for the given [context].
///
/// Single entry point — `co_skeleton.dart` must not call
/// `theme.coreComponentTheme.skeleton` directly nor invoke
/// `CoreSkeletonStyle.merge(...)` outside this function.
///
/// The flat user-supplied [width] / [height] sizing knobs are passed
/// in so the resolver applies scaling once here and the widget reads
/// paint-ready [ResolvedSkeleton.scaledWidth] /
/// [ResolvedSkeleton.scaledHeight] directly (no widget-side
/// `* scaling` multiply).
ResolvedSkeleton resolveSkeleton(
  BuildContext context, {
  required CoreSkeletonVariant variant,
  CoreSkeletonStyle? skeletonStyle,
  double? width,
  double? height,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final compTheme = theme.coreComponentTheme?.skeleton;

  final chrome = CoreSkeletonStyle.defaultsByVariant[variant]!;
  final chromeBg = scheme.resolve(chrome.backgroundColor);

  // Merge chain — theme.style → theme.variantStyles[variant] →
  // widget.skeletonStyle. Semantic `variant` is widget-only; the theme
  // cannot override it (render-only.md (c)). Web wires the same chain
  // so the two platforms stay 1:1.
  final merged = resolveStyleChain(const CoreSkeletonStyle(), [
    compTheme?.style,
    compTheme?.variantStyles?[variant],
    skeletonStyle,
  ]);

  // Color — widget override > variant default.
  final mergedBg = merged.backgroundColor;
  final resolvedBg = mergedBg != null
      ? scheme.resolve(mergedBg).toValue()
      : chromeBg.toValue();

  // Border radius — widget override > variant default. Scaling
  // applied at use-site (multiply each corner).
  final radiusCore = theme.geometry.borderRadius(
    merged.borderRadius ?? chrome.borderRadius,
  );
  final resolvedRadius = BorderRadius.only(
    topLeft: .circular(radiusCore.topLeft * scaling),
    topRight: .circular(radiusCore.topRight * scaling),
    bottomLeft: .circular(radiusCore.bottomLeft * scaling),
    bottomRight: .circular(radiusCore.bottomRight * scaling),
  );

  // The period is NOT routed through `resolveMotionDuration`: a short
  // override (<= 500ms) would collapse to `Duration.zero`, which
  // `AnimationController.repeat()` asserts against (`_RepeatingSimulation`'s
  // `_periodInSeconds > 0.0`) — reduced motion crashed the skeleton outright
  // instead of stopping it. Reduced motion stops the pulse through `pulses`
  // instead, and the period keeps whatever value it was given.
  final border = resolveInjectedBorder(theme);

  final resolvedDuration = merged.duration ?? CoreSkeletonStyle.defaultDuration;
  final resolvedCurve = (merged.curve ?? CoreSkeletonStyle.defaultCurve)
      .toValue();
  final pulses = resolvePlaceholderPulse(context);
  final resolvedFromOpacity =
      merged.fromOpacity ?? CoreSkeletonStyle.defaultFromOpacity;
  final resolvedToOpacity =
      merged.toOpacity ?? CoreSkeletonStyle.defaultToOpacity;

  // The two ends of the pulse, composed the way Web composes `--pulse-from`
  // / `--pulse-to` and the Figma builder composes its still: the pulse
  // opacity is MULTIPLIED into the fill's own alpha through
  // `CoreColor.scaleAlpha`, never written over it. Overwriting turned a
  // transparent fill (`.transparent`, raw ARGB 0x00000000) into black
  // pulsing rest → peak here while the other two surfaces stayed clear, and
  // lifted a translucent fill to the pulse opacities themselves.
  //
  // `scaleAlpha` runs before `scheme.resolve`, not after: on a token it only
  // moves the opacity modifier and hands back an unresolved token, so
  // scaling an already-resolved colour would send it through `toValue()`'s
  // light-palette fallback and freeze dark mode.
  final pulseBase = merged.backgroundColor ?? chrome.backgroundColor;
  final pulseFromColor = scheme
      .resolve(pulseBase.scaleAlpha(resolvedFromOpacity))
      .toValue();
  final pulseToColor = scheme
      .resolve(pulseBase.scaleAlpha(resolvedToOpacity))
      .toValue();

  // Native-spacing `lineSpacing` consumed by `Column.spacing` directly
  // — scaling applied in the return so the widget reads ready-to-paint
  // pixels (Epic #1659 D-cat — N-sibling uniform distribution pattern).
  final resolvedLineSpacing =
      theme.geometry.space(
        merged.lineSpacing ?? CoreSkeletonStyle.defaultLineSpacing,
      ) *
      scaling;
  final resolvedLastLineWidth =
      merged.lastLineWidth ?? CoreSkeletonStyle.defaultLastLineWidth;
  final resolvedLines = merged.lines ?? CoreSkeletonStyle.defaultLines;

  // User-supplied flat sizing knobs — pre-scale once so the widget
  // reads paint-ready logical pixels (synthesis lives in a local var,
  // the return literal stays a bare mapping).
  final resolvedWidth = width == null ? null : width * scaling;
  final resolvedHeight = height == null ? null : height * scaling;

  // Text-variant line height — scaling pre-applied so the widget hands the
  // value straight to `Container.height`.
  final textLineHeight =
      (merged.lineHeight ?? CoreSkeletonStyle.defaultLineHeight) * scaling;

  return ResolvedSkeleton(
    backgroundColor: resolvedBg,
    pulseFromColor: pulseFromColor,
    pulseToColor: pulseToColor,
    borderRadius: resolvedRadius,
    duration: resolvedDuration,
    curve: resolvedCurve,
    pulses: pulses,
    fromOpacity: resolvedFromOpacity,
    toOpacity: resolvedToOpacity,
    lineSpacing: resolvedLineSpacing,
    lineHeight: textLineHeight,
    scaledWidth: resolvedWidth,
    scaledHeight: resolvedHeight,
    lastLineWidth: resolvedLastLineWidth,
    lines: resolvedLines,
    border: border,
  );
}
