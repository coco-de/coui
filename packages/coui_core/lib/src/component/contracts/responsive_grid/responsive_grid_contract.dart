/// Platform-agnostic contract for `ResponsiveGrid`.
///
/// A grid layout that arranges its children in a fixed number of
/// equal-width columns with consistent inter-cell spacing. When
/// `responsive` is `true`, the column count adjusts at
/// `CoreBreakpoint`s (defaults: 1 col below `md`, 2 cols below `lg`,
/// full `columns` at `lg` and above). Consumers may override the
/// breakpoint-to-column mapping via `breakpoints`.
///
/// All chrome / dimensional overrides flow through the single
/// `responsiveGridStyle` (a `CoreResponsiveGridStyle`). The ergonomic
/// per-instance fields (`columns`, `cellSpacing`, `responsive`,
/// `breakpoints`) remain on the widget API and win over the style
/// chain — same pattern as button's `variant` / `size` / `shape`
/// versus `buttonStyle`.
///
/// Type parameters:
///   - `W` — `Widget` on Flutter, `Component` on Web (child type).
library;

import 'package:coui_core/src/component/contracts/media_query_visibility/core_breakpoint.dart';
import 'package:coui_core/src/component/contracts/responsive_grid/responsive_grid_style.dart';

/// Contract for the unified `ResponsiveGrid` layout primitive.
abstract interface class CoreResponsiveGridContract<W> {
  /// Grid items laid out across `columns` columns.
  List<W> get children;

  /// Number of columns at the widest breakpoint. `null` falls back
  /// through the resolve chain (`responsiveGridStyle.columns` →
  /// `theme.style.columns` → `CoreResponsiveGridStyle.defaultColumns`).
  int? get columns;

  /// Inter-cell spacing applied uniformly between every column and
  /// every row (logical px). `null` falls back through the resolve
  /// chain (`responsiveGridStyle.cellSpacing` →
  /// `theme.style.cellSpacing` →
  /// `CoreResponsiveGridStyle.defaultCellSpacing`). N-sibling
  /// distribution — paint-ready `double` fed straight to
  /// `RenderGrid` on Flutter and to CSS grid `gap` on Web.
  double? get cellSpacing;

  /// Whether the column count should adapt to the viewport width.
  /// `null` falls back through the resolve chain
  /// (`responsiveGridStyle.responsive` → `theme.style.responsive` →
  /// `CoreResponsiveGridStyle.defaultResponsive`).
  bool? get responsive;

  /// Optional explicit mapping from `CoreBreakpoint` to column count.
  /// When provided, overrides the default responsive curve.
  ///
  /// Example:
  ///   `{CoreBreakpoint.xs: 1, CoreBreakpoint.md: 2, CoreBreakpoint.lg: 4}`
  /// lays out 1 column below `md`, 2 columns below `lg`, 4 columns at
  /// `lg` and above.
  Map<CoreBreakpoint, int>? get breakpoints;

  /// Per-instance style chain entry. Merged on top of
  /// `theme.responsiveGrid.style`; per-instance widget params
  /// ([columns] / [cellSpacing] / [responsive] / [breakpoints]) still
  /// win over the resolved style. Named [responsiveGridStyle] (not
  /// `style`) so the Web base class `super.style` (jaspr inline CSS)
  /// stays unambiguous.
  CoreResponsiveGridStyle? get responsiveGridStyle;
}
