import 'package:coui_flutter/coui_flutter.dart';

/// Resolved styling values for [Scrollbar].
///
/// Output of [resolveScrollbar] — the merge chain has been applied
/// plus static-const default fallback and token conversion:
///
/// ```text
/// CoreScrollbarStyle.defaultX
///   → CoreScrollbarTheme.style
///   → widget.scrollbarStyle
/// ```
class ResolvedScrollbar {
  /// Creates a [ResolvedScrollbar].
  const ResolvedScrollbar({
    required this.thumbColor,
    required this.hoverThumbColor,
    required this.thumbRadius,
    required this.thickness,
    required this.hoverThickness,
    required this.thumbInset,
    required this.hoverThumbInset,
    required this.hoverDuration,
    required this.minThumbLength,
    required this.trackColor,
  });

  /// Thumb colour at rest.
  final Color thumbColor;

  /// Thumb colour while hovered or dragged.
  final Color hoverThumbColor;

  /// Thumb corner radius.
  final Radius thumbRadius;

  /// Thumb thickness at rest (logical px, scaling applied).
  final double thickness;

  /// Thumb thickness while hovered or dragged (logical px, scaling applied)
  /// — already held inside the bar's footprint.
  final double hoverThickness;

  /// Gap between the thumb and the edge it hugs at rest (logical px,
  /// scaling applied).
  final double thumbInset;

  /// Gap between the thumb and the edge while it is hovered or dragged:
  /// what the grown thumb leaves of the footprint, so the bar occupies the
  /// same space either way (logical px, scaling applied).
  final double hoverThumbInset;

  /// How long the thumb takes to change between its resting and hovered
  /// look — zero under reduced motion.
  final Duration hoverDuration;

  /// Minimum thumb length (logical px, scaling applied).
  final double minThumbLength;

  /// Track colour (transparent default — no visible gutter).
  final Color trackColor;
}

/// Resolves [ResolvedScrollbar] for the given [context].
///
/// Single entry point for the scrollbar Style slot — applies the
/// merge chain (`CoreScrollbarTheme.style` → `scrollbarStyle`), the
/// `CoreScrollbarStyle.defaultX` fallbacks, the per-visibility
/// thickness adjustment, and `theme.scaling`.
ResolvedScrollbar resolveScrollbar(
  BuildContext context, {
  required CoreScrollbarVisibility visibility,
  CoreScrollbarStyle? scrollbarStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final scrollbarTheme = theme.coreComponentTheme?.scrollbar;

  // Merge chain: theme.style → scrollbarStyle.
  final merged = resolveStyleChain(const CoreScrollbarStyle(), [
    scrollbarTheme?.style,
    scrollbarStyle,
  ]);

  final thumbColorCore =
      merged.thumbColor ?? CoreScrollbarStyle.defaultThumbColor;
  final hoverThumbColorCore =
      merged.hoverThumbColor ?? CoreScrollbarStyle.defaultHoverThumbColor;
  final thumbRadiusCore = theme.geometry.borderRadius(
    merged.thumbRadius ?? CoreScrollbarStyle.defaultThumbRadius,
  );

  // `thin` visibility halves a thickness so the thumb reads as a hairline;
  // `hidden` collapses it to zero (still scrollable). The same rule applies
  // to the resting and the hovered thickness, so a thin thumb stays thinner
  // than a regular one in both looks.
  double thicknessFor(double base) => switch (visibility) {
    .thin => base * CoreScrollbarStyle.thinThicknessFactor,
    .hidden => 0.0,
    .auto || .always => base,
  };
  final thickness =
      thicknessFor(merged.thickness ?? CoreScrollbarStyle.defaultThickness) *
      scaling;
  final requestedHoverThickness =
      thicknessFor(
        merged.hoverThickness ?? CoreScrollbarStyle.defaultHoverThickness,
      ) *
      scaling;
  final thumbInset =
      (merged.thumbInset ?? CoreScrollbarStyle.defaultThumbInset) * scaling;

  // The bar occupies the thumb plus its inset on both sides, and hovering
  // must not change that. The shared geometry holds the hovered thumb inside
  // that footprint and hands back what is left as the hovered inset — the
  // same arithmetic the Web twin runs.
  final geometry = CoreScrollbarThumbGeometry(
    thickness: thickness,
    hoverThickness: requestedHoverThickness,
    inset: thumbInset,
  );
  final hoverThickness = geometry.activeThickness;
  final hoverThumbInset = geometry.activeInset;

  final minThumbLength =
      (merged.minThumbLength ?? CoreScrollbarStyle.defaultMinThumbLength) *
      scaling;
  final hoverDuration = resolveMotionDuration(
    context,
    const Duration(milliseconds: CoreScrollbarContract.hoverTransitionMs),
  );
  final thumbColor = scheme.resolve(thumbColorCore).toValue();
  final hoverThumbColor = scheme.resolve(hoverThumbColorCore).toValue();
  final trackColor = scheme
      .resolve(merged.trackColor ?? CoreScrollbarStyle.defaultTrackColor)
      .toValue();

  return ResolvedScrollbar(
    thumbColor: thumbColor,
    hoverThumbColor: hoverThumbColor,
    thumbRadius: .circular(thumbRadiusCore.topLeft),
    thickness: thickness,
    hoverThickness: hoverThickness,
    thumbInset: thumbInset,
    hoverThumbInset: hoverThumbInset,
    hoverDuration: hoverDuration,
    minThumbLength: minThumbLength,
    trackColor: trackColor,
  );
}
