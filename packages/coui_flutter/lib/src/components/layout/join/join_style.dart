import 'package:coui_flutter/coui_flutter.dart';

/// Resolved styling values for [Join].
class ResolvedJoin {
  /// Creates a [ResolvedJoin].
  const ResolvedJoin({
    required this.borderRadius,
    required this.coreBorderRadius,
    required this.itemOverlap,
  });

  /// Outer border radius of the first/last joined items — paint-ready
  /// (geometry applied, scaled).
  final BorderRadiusGeometry borderRadius;

  /// [borderRadius] before geometry and scaling. Forwarded raw to the
  /// children's self-scaling consumers (their focus rings) through
  /// [JoinItemData.coreBorderRadius], which resolve and scale it once
  /// on their own side.
  final CoreBorderRadius coreBorderRadius;

  /// How far each item overlaps the one before it — paint-ready, through
  /// the theme geometry's stroke so it matches the border width the
  /// children draw.
  final double itemOverlap;
}

/// Resolves [ResolvedJoin] for [Join].
///
/// Priority (per-field):
/// `widget.joinStyle` > `CoreJoinTheme.style` > design-system default.
ResolvedJoin resolveJoin(
  BuildContext context, {
  CoreJoinStyle? joinStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final themeStyle = theme.coreComponentTheme?.join?.style;

  // Merge chain: theme.style → widget.joinStyle.
  final merged = resolveStyleChain(const CoreJoinStyle(), [
    themeStyle,
    joinStyle,
  ]);

  final coreBorderRadius =
      merged.borderRadius ?? CoreJoinStyle.defaultBorderRadius;
  final borderRadius =
      coreBorderRadius.toValue(geometry: theme.geometry) * scaling;

  final itemOverlap = theme.geometry.stroke(
    merged.itemOverlap ?? CoreJoinStyle.defaultItemOverlap,
  );

  return ResolvedJoin(
    borderRadius: borderRadius,
    coreBorderRadius: coreBorderRadius,
    itemOverlap: itemOverlap,
  );
}
