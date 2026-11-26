import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/src/components/layout/responsive_grid/render_grid.dart';
import 'package:coui_flutter/src/components/layout/responsive_grid/responsive_grid_style.dart';
import 'package:flutter/widgets.dart';

/// A responsive grid layout.
///
/// Arranges [children] in an `N × columns` matrix with uniform
/// [cellSpacing] on both axes. Children that want to claim multiple
/// cells should be wrapped in `GridItem` with `colSpan`/`rowSpan`.
///
/// When [responsive] is `true`, the column count drops at narrower
/// breakpoints (defaults: 1 col below `md`, 2 cols below `lg`, full
/// [columns] at `lg` and above). Override with [breakpoints].
///
/// Per Epic #1603 (옵션 B 최종) all chrome / dimensional overrides
/// flow through [responsiveGridStyle]; the ergonomic per-instance
/// fields ([columns] / [cellSpacing] / [responsive] / [breakpoints])
/// still win over the resolved style chain.
///
/// Example:
/// ```dart
/// ResponsiveGrid(
///   columns: 4,
///   cellSpacing: CoreSpace.space16,
///   children: [
///     GridItem(colSpan: 2, child: Card(child: Text('Wide'))),
///     Card(child: Text('Small')),
///     Card(child: Text('Small')),
///     Card(child: Text('Small')),
///   ],
/// )
/// ```
class ResponsiveGrid extends StatelessWidget
    implements CoreResponsiveGridContract<Widget> {
  /// Creates a [ResponsiveGrid].
  const ResponsiveGrid({
    required this.children,
    this.columns,
    this.cellSpacing,
    this.responsive,
    this.breakpoints,
    this.responsiveGridStyle,
    super.key,
  }) : assert(
         columns == null || columns >= 1,
         'columns must be >= 1 when provided',
       ),
       assert(
         cellSpacing == null || cellSpacing >= 0,
         'cellSpacing must be >= 0 when provided',
       );

  @override
  final List<Widget> children;

  @override
  final int? columns;

  @override
  final double? cellSpacing;

  @override
  final bool? responsive;

  @override
  final Map<CoreBreakpoint, int>? breakpoints;

  @override
  final CoreResponsiveGridStyle? responsiveGridStyle;

  /// Returns a copy of this [ResponsiveGrid] with the given fields
  /// replaced. All fields default to this instance's current value
  /// when omitted.
  ResponsiveGrid copyWith({
    Key? key,
    List<Widget>? children,
    int? columns,
    double? cellSpacing,
    bool? responsive,
    Map<CoreBreakpoint, int>? breakpoints,
    CoreResponsiveGridStyle? responsiveGridStyle,
  }) {
    return ResponsiveGrid(
      key: key ?? this.key,
      columns: columns ?? this.columns,
      cellSpacing: cellSpacing ?? this.cellSpacing,
      responsive: responsive ?? this.responsive,
      breakpoints: breakpoints ?? this.breakpoints,
      responsiveGridStyle: responsiveGridStyle ?? this.responsiveGridStyle,
      children: children ?? this.children,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveResponsiveGrid(
      context,
      columns: columns,
      cellSpacing: cellSpacing,
      responsive: responsive,
      breakpoints: breakpoints,
      responsiveGridStyle: responsiveGridStyle,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final effectiveColumns = resolved.responsive
            ? _resolveColumnsForWidth(
                maxWidth,
                resolved.breakpoints,
                resolved.columns,
              )
            : resolved.columns;
        return GridMultiChild(
          columns: effectiveColumns,
          cellSpacing: resolved.cellSpacing,
          children: children,
        );
      },
    );
  }
}

/// Returns the column count that should be rendered at the given
/// `width`, consulting the breakpoint map. Picks the largest
/// `CoreBreakpoint` whose `minWidth` is ≤ `width`.
///
/// Render-time concern owned by the widget: `resolveResponsiveGrid`
/// produces the breakpoint-to-column map; `ResponsiveGrid` picks the
/// active column count inside `LayoutBuilder` once the available width
/// is known (Epic #1603 C13 — semantic breakpoint selection is a
/// widget-layer decision, not a style resolution).
int _resolveColumnsForWidth(
  double width,
  Map<CoreBreakpoint, int> breakpoints,
  int fallback,
) {
  final sorted = breakpoints.entries.toList()
    ..sort((a, b) => a.key.minWidth.compareTo(b.key.minWidth));
  var result = fallback;
  for (final entry in sorted) {
    if (width >= entry.key.minWidth) {
      result = entry.value;
    } else {
      break;
    }
  }
  return result;
}

/// Chain sugar for merging a [CoreResponsiveGridStyle] patch into
/// [ResponsiveGrid.responsiveGridStyle] without hand-reconstructing
/// every field. Mirrors the Web `ResponsiveGrid.withStyle` extension so
/// both platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreResponsiveGridStyle.merge` right-side-wins semantics).
extension ResponsiveGridStyleChain on ResponsiveGrid {
  /// Returns a copy of this [ResponsiveGrid] with [patch] merged into
  /// [responsiveGridStyle] (patch fields win on conflict).
  ResponsiveGrid withStyle(CoreResponsiveGridStyle patch) => copyWith(
    responsiveGridStyle:
        (responsiveGridStyle ?? const CoreResponsiveGridStyle()).merge(patch),
  );
}
