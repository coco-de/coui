library;

import 'package:coui_flutter/coui_flutter.dart';

/// Default breakpoint-to-column mapping used when
/// `responsive == true` and the caller hasn't supplied an explicit
/// `breakpoints` map. Mirrors the legacy Web `grid-cols-1 md:grid-cols-2
/// lg:grid-cols-N` rule with `N = columns`.
Map<CoreBreakpoint, int> defaultResponsiveBreakpoints(int columns) {
  const mobileCols = 1;
  const tabletCols = 2;
  return {
    CoreBreakpoint.xs: mobileCols,
    CoreBreakpoint.sm: mobileCols,
    CoreBreakpoint.md: tabletCols,
    CoreBreakpoint.lg: columns,
    CoreBreakpoint.xl: columns,
    CoreBreakpoint.xxl: columns,
  };
}

/// Resolved styling values for `ResponsiveGrid`.
class ResolvedResponsiveGrid {
  /// Creates a [ResolvedResponsiveGrid].
  const ResolvedResponsiveGrid({
    required this.columns,
    required this.cellSpacing,
    required this.responsive,
    required this.breakpoints,
  });

  /// Effective column count at the widest breakpoint.
  final int columns;

  /// Effective inter-cell spacing between every column and every row
  /// (logical px, scaling applied). Fed straight to `RenderGrid` —
  /// N-sibling uniform distribution along both axes.
  final double cellSpacing;

  /// Whether responsive breakpoints are enabled.
  final bool responsive;

  /// Resolved breakpoint-to-column mapping. Always non-null; falls
  /// back to [defaultResponsiveBreakpoints] when neither caller nor
  /// theme provided one.
  final Map<CoreBreakpoint, int> breakpoints;
}

/// Resolves [ResolvedResponsiveGrid] for `ResponsiveGrid`.
///
/// Merge chain (mirrors Web):
///
/// ```text
/// design-system default (CoreResponsiveGridStyle.defaultX)
///   → theme.coreComponentTheme.responsiveGrid.style
///   → widget.responsiveGridStyle
///   → widget per-instance params ([columns] / [cellSpacing] / [responsive] / [breakpoints])
/// ```
ResolvedResponsiveGrid resolveResponsiveGrid(
  BuildContext context, {
  int? columns,
  double? cellSpacing,
  bool? responsive,
  Map<CoreBreakpoint, int>? breakpoints,
  CoreResponsiveGridStyle? responsiveGridStyle,
}) {
  final theme = Theme.of(context);
  final gridTheme = theme.coreComponentTheme?.responsiveGrid;
  final scaling = theme.scaling;

  // Widget per-instance params win — packaged last so
  // `resolveStyleChain` folds them on top of the theme + slot.
  final widgetParamStyle = CoreResponsiveGridStyle(
    columns: columns,
    cellSpacing: cellSpacing,
    responsive: responsive,
    breakpoints: breakpoints,
  );
  final merged = resolveStyleChain(const CoreResponsiveGridStyle(), [
    gridTheme?.style,
    responsiveGridStyle,
    widgetParamStyle,
  ]);

  final effectiveColumns =
      merged.columns ?? CoreResponsiveGridStyle.defaultColumns;
  final effectiveCellSpacing =
      theme.geometry.space(
        merged.cellSpacing ?? CoreResponsiveGridStyle.defaultCellSpacing,
      ) *
      scaling;
  final effectiveResponsive =
      merged.responsive ?? CoreResponsiveGridStyle.defaultResponsive;
  final effectiveBreakpoints =
      merged.breakpoints ?? defaultResponsiveBreakpoints(effectiveColumns);
  return ResolvedResponsiveGrid(
    columns: effectiveColumns,
    cellSpacing: effectiveCellSpacing,
    responsive: effectiveResponsive,
    breakpoints: effectiveBreakpoints,
  );
}
