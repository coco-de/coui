import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Single-entry-point resolver
// ═══════════════════════════════════════════════════

/// Resolves the status dot colour for [variant] from the active core
/// color scheme.
///
/// File-private helper (Epic #1603 C1 — single public `resolveStatus`
/// entry point). The per-variant source map lives in
/// [CoreStatusStyle.defaultsByColor] (shared with Web); Flutter resolves
/// the matching [CoreColor] through the scheme.
Color _resolveStatusColor(
  CoreColorScheme scheme,
  CoreStatusColor color,
  CoreStatusVariant? variant,
) {
  final core = variant != null
      ? CoreStatusStyle.defaultsByVariant[variant]!.color!
      : CoreStatusStyle.defaultsByColor[color]!.color!;
  return scheme.resolve(core).toValue();
}

/// Resolver output for `Status`.
///
/// Single struct that the widget reads — every chrome / dimensional
/// override has been merged through:
///
/// ```text
/// design system default (variant enums)
///   → theme.coreComponentTheme.status.style
///   → widget.statusStyle
/// ```
class ResolvedStatus {
  /// Creates a [ResolvedStatus].
  const ResolvedStatus({
    required this.size,
    required this.color,
    required this.borderRadius,
    required this.hollow,
    required this.ringWidth,
    required this.hasBar,
    required this.barLength,
    required this.barWidth,
    required this.barColor,
    required this.barBorderRadius,
    required this.labelTextStyle,
    required this.labelSpacing,
  });

  /// Status dot diameter (already scaled).
  final double size;

  /// Status dot colour.
  final Color color;

  /// Status dot border radius (paint-ready). The dot is a square box,
  /// so the full radius renders a perfect circle.
  final BorderRadius borderRadius;

  /// Whether the dot is a ring (stroke only) rather than a fill.
  final bool hollow;

  /// Stroke of a ring dot (already scaled).
  final double ringWidth;

  /// Whether a bar is drawn across the dot.
  final bool hasBar;

  /// Length of the bar (already scaled).
  final double barLength;

  /// Thickness of the bar (already scaled).
  final double barWidth;

  /// Colour of the bar.
  final Color barColor;

  /// Corners of the bar — round ends by default (half its thickness).
  final BorderRadius barBorderRadius;

  /// Text style of the visible label (paint-ready).
  final TextStyle labelTextStyle;

  /// Space between the dot and the label (already scaled).
  final double labelSpacing;
}

// ═══════════════════════════════════════════════════
// Resolver
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedStatus] for the given [context].
ResolvedStatus resolveStatus(
  BuildContext context, {
  required CoreStatusColor color,
  required CoreStatusSize size,
  CoreStatusVariant? variant,
  CoreStatusStyle? statusStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final stTheme = theme.coreComponentTheme?.status;

  final merged = resolveStyleChain(const CoreStatusStyle(), [
    stTheme?.style,
    statusStyle,
  ]);

  final sizeStyle = CoreStatusStyle.defaultsBySize[size]!;
  final variantSize = sizeStyle.size!;

  // Dot diameter — Stage1 RESOLVE (`merged.size ?? variant default`) and
  // Stage2 EMIT (`* scaling`) both finish in this local var so the return
  // literal stays a bare mapping (no synthesis / arithmetic in the
  // `ResolvedStatus(...)` block).
  final resolvedSize = (merged.size ?? variantSize) * scaling;

  // Per-instance colour override wins, else the per-variant default.
  // Both flow through `scheme.resolve(x).toValue()` (Epic #1603 C7 —
  // no standalone `.toValue()` colour path).
  final resolvedColor = merged.color != null
      ? scheme.resolve(merged.color!).toValue()
      : _resolveStatusColor(scheme, color, variant);

  final resolvedBorderRadius =
      (merged.borderRadius ?? CoreStatusStyle.defaultBorderRadius).toValue(
        geometry: theme.geometry,
      );

  final variantStyle = variant != null
      ? CoreStatusStyle.defaultsByVariant[variant]
      : null;
  final hollow = variant?.hollow ?? false;
  final hasBar = variant?.hasBar ?? false;
  final ringWidth =
      (merged.ringWidth ?? CoreStatusStyle.defaultRingWidth) * scaling;
  final barLength = (merged.barLength ?? sizeStyle.barLength!) * scaling;
  final barWidth =
      (merged.barWidth ?? CoreStatusStyle.defaultBarWidth) * scaling;
  final barColor = scheme
      .resolve(merged.barColor ?? CoreStatusStyle.defaultBarColor)
      .toValue();
  final barBorderRadius =
      (merged.barBorderRadius ?? CoreStatusStyle.defaultBarBorderRadius)
          .toValue(geometry: theme.geometry);
  final labelTextStyle = sizeStyle.labelStyle!
      .merge(variantStyle?.labelStyle)
      .merge(merged.labelStyle)
      .toValue(theme: theme);
  final labelSpacing =
      theme.geometry.space(merged.labelSpacing ?? sizeStyle.labelSpacing!) *
      scaling;

  return ResolvedStatus(
    size: resolvedSize,
    color: resolvedColor,
    borderRadius: resolvedBorderRadius,
    hollow: hollow,
    ringWidth: ringWidth,
    hasBar: hasBar,
    barLength: barLength,
    barWidth: barWidth,
    barColor: barColor,
    barBorderRadius: barBorderRadius,
    labelTextStyle: labelTextStyle,
    labelSpacing: labelSpacing,
  );
}
