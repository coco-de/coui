import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedIndicator
// ═══════════════════════════════════════════════════

/// Resolver output for `Indicator`.
///
/// Single entry point that merges (in order)
/// `theme.coreComponentTheme?.indicator?.style` → `widget.indicatorStyle`
/// → the `CoreIndicatorStyle.default*` values and returns the final
/// logical-pixel offset and ring already scaled by `Theme.scaling`.
class ResolvedIndicator {
  /// Creates a [ResolvedIndicator].
  const ResolvedIndicator({
    required this.offset,
    required this.ringWidth,
    required this.ringColor,
    required this.ringBorderRadius,
  });

  /// Distance from the chosen edge to the item's own edge (scaled).
  final double offset;

  /// Thickness of the ring around the item (scaled); `0` draws no ring.
  final double ringWidth;

  /// Colour of the ring around the item.
  final Color ringColor;

  /// Corner radius of the ring (scaled).
  final BorderRadius ringBorderRadius;
}

// ═══════════════════════════════════════════════════
// Resolver
// ═══════════════════════════════════════════════════

/// Resolves the paint-ready values of an `Indicator`.
ResolvedIndicator resolveIndicator(
  BuildContext context, {
  CoreIndicatorStyle? indicatorStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final coreTheme = theme.coreComponentTheme?.indicator;

  final merged = resolveStyleChain(const CoreIndicatorStyle(), [
    coreTheme?.style,
    indicatorStyle,
  ]);

  final offset = (merged.offset ?? CoreIndicatorStyle.defaultOffset) * scaling;
  final ringWidth =
      (merged.ringWidth ?? CoreIndicatorStyle.defaultRingWidth) * scaling;
  final ringColor = theme.colorScheme
      .resolve(merged.ringColor ?? CoreIndicatorStyle.defaultRingColor)
      .toValue();

  final ringBorderRadius =
      (merged.ringBorderRadius ?? CoreIndicatorStyle.defaultRingBorderRadius)
          .toValue(geometry: theme.geometry) *
      scaling;

  return ResolvedIndicator(
    offset: offset,
    ringWidth: ringWidth,
    ringColor: ringColor,
    ringBorderRadius: ringBorderRadius,
  );
}
