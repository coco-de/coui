import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Maximum number of columns supported by the bit-field occupancy
/// grid. Chosen as 63 so that each row fits in a signed 64-bit `int`
/// mask on both 64-bit and Dart-JS targets. Not a design token — a
/// technical sentinel tied to Dart int semantics.
const _kCssMaxSupportedColumns = 63;

/// ParentData carrying the grid-span info each child gives its
/// [RenderGrid] parent.
class GridParentData extends ContainerBoxParentData<RenderBox> {
  /// Number of columns this cell should span (>=1).
  int colSpan = 1;

  /// Number of rows this cell should span (>=1).
  int rowSpan = 1;
}

/// `ParentDataWidget` used by `GridItem` to hand `colSpan`/`rowSpan`
/// to its enclosing `RenderGrid`.
class GridItemParentData extends ParentDataWidget<GridParentData> {
  /// Creates a [GridItemParentData].
  const GridItemParentData({
    required super.child,
    this.colSpan = 1,
    this.rowSpan = 1,
    super.key,
  }) : assert(colSpan >= 1, 'colSpan must be >= 1'),
       assert(rowSpan >= 1, 'rowSpan must be >= 1');

  /// Column span.
  final int colSpan;

  /// Row span.
  final int rowSpan;

  @override
  void applyParentData(RenderObject renderObject) {
    assert(
      renderObject.parentData is GridParentData,
      'GridItem must be a descendant of ResponsiveGrid',
    );
    final parentData = renderObject.parentData! as GridParentData;
    var needsLayout = false;
    if (parentData.colSpan != colSpan) {
      parentData.colSpan = colSpan;
      needsLayout = true;
    }
    if (parentData.rowSpan != rowSpan) {
      parentData.rowSpan = rowSpan;
      needsLayout = true;
    }
    if (needsLayout) {
      final targetParent = renderObject.parent;
      if (targetParent is RenderObject) targetParent.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => _GridMultiChild;
}

/// Private marker type — points [GridItemParentData] to the
/// expected ancestor in debug messages.
abstract class _GridMultiChild {}

/// Multi-child layout widget backing `ResponsiveGrid`.
///
/// Lays out children in `columns` equal-width cells per row with
/// uniform `cellSpacing` along both axes. Honours `colSpan`/`rowSpan`
/// on each child via [GridParentData] so `GridItem` wrappers can
/// request extra cells.
///
/// Items are placed with a simple row-major packing algorithm: for
/// each child we scan the occupancy grid from top-left until we find
/// the first `colSpan × rowSpan` region that is completely empty,
/// reserve it, and lay out the child to fit that rectangle.
class GridMultiChild extends MultiChildRenderObjectWidget {
  /// Creates a [GridMultiChild].
  const GridMultiChild({
    required this.columns,
    required this.cellSpacing,
    required super.children,
    super.key,
  }) : assert(columns >= 1, 'columns must be >= 1'),
       assert(
         columns <= _kCssMaxSupportedColumns,
         'columns must be <= $_kCssMaxSupportedColumns',
       ),
       assert(cellSpacing >= 0, 'cellSpacing must be >= 0');

  /// Number of columns.
  final int columns;

  /// Inter-cell spacing applied uniformly between every column and
  /// every row (logical px). N-sibling distribution along both axes.
  final double cellSpacing;

  @override
  RenderGrid createRenderObject(BuildContext context) {
    return RenderGrid(columns: columns, cellSpacing: cellSpacing);
  }

  @override
  void updateRenderObject(BuildContext context, RenderGrid renderObject) {
    renderObject
      ..columns = columns
      ..cellSpacing = cellSpacing;
  }
}

/// `RenderBox` implementing the grid layout for `ResponsiveGrid`.
///
/// Uses a bit-field occupancy grid: each row is a single `int` whose
/// bit `c` is set when column `c` is taken. That lets row allocation
/// run with plain `|=` / `&` operations instead of mutating a nested
/// `List<List<bool>>`.
class RenderGrid extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, GridParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, GridParentData> {
  /// Creates a [RenderGrid].
  RenderGrid({required int columns, required double cellSpacing})
    : _columns = columns,
      _cellSpacing = cellSpacing;

  int _columns;

  /// Number of columns.
  int get columns => _columns;
  set columns(int value) {
    if (_columns == value) return;
    _columns = value;
    markNeedsLayout();
  }

  double _cellSpacing;

  /// Inter-cell spacing applied uniformly between every column and
  /// every row (logical px). N-sibling distribution.
  double get cellSpacing => _cellSpacing;
  set cellSpacing(double value) {
    if (_cellSpacing == value) return;
    _cellSpacing = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! GridParentData) {
      child.parentData = GridParentData();
    }
  }

  @override
  void performLayout() {
    final constraints = this.constraints;
    final maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0;
    final totalSpacing = _cellSpacing * (_columns - 1);
    final cellWidth = _columns <= 0
        ? 0.0
        : math.max(0.0, (maxWidth - totalSpacing) / _columns);

    // Compute placements and row-occupancy masks.
    final placements = _placeChildren();
    final rowCount = placements.isEmpty
        ? 0
        : placements.map((p) => p.row + p.rowSpan).reduce(math.max);
    final rowHeights = List<double>.filled(rowCount, 0);

    // Lay out children with LOOSE width (0 .. span width) — a child takes
    // its content size up to the spanned cells and does NOT stretch to
    // fill the track. Web mirrors this by not emitting any cell-stretch
    // rule; grid parity is loose on both platforms.
    for (final placement in placements) {
      final child = placement.child;
      final width =
          cellWidth * placement.colSpan +
          _cellSpacing * (placement.colSpan - 1);
      child.layout(
        BoxConstraints(minWidth: 0, maxWidth: math.max(0, width)),
        parentUsesSize: true,
      );
    }

    // Pass 1: single-row cells raise their row's height.
    for (final placement in placements) {
      if (placement.rowSpan != 1) continue;
      final childHeight = placement.child.size.height;
      if (childHeight > rowHeights[placement.row]) {
        rowHeights[placement.row] = childHeight;
      }
    }

    // Pass 2: multi-row cells grow the last row they span if needed.
    for (final placement in placements) {
      if (placement.rowSpan == 1) continue;
      final allocated = _sumRowRange(
        rowHeights,
        placement.row,
        placement.rowSpan,
      );
      final spacingBetween = _cellSpacing * (placement.rowSpan - 1);
      final needed = placement.child.size.height - spacingBetween;
      if (needed > allocated) {
        final lastRow = placement.row + placement.rowSpan - 1;
        rowHeights[lastRow] += needed - allocated;
      }
    }

    // Compute row top offsets.
    final rowTops = List<double>.filled(rowCount, 0);
    for (var i = 1; i < rowCount; i += 1) {
      rowTops[i] = rowTops[i - 1] + rowHeights[i - 1] + _cellSpacing;
    }

    for (final placement in placements) {
      final parentData = placement.child.parentData! as GridParentData;
      final x = placement.col * (cellWidth + _cellSpacing);
      final y = rowTops[placement.row];
      parentData.offset = Offset(x, y);
    }

    final totalHeight = rowCount == 0
        ? 0.0
        : rowTops[rowCount - 1] + rowHeights[rowCount - 1];
    size = constraints.constrain(Size(maxWidth, totalHeight));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  /// Scans the children once, reserving a rectangle in the occupancy
  /// grid for each. Pre-allocates enough rows in a bit-mask list so
  /// the allocator never has to grow the list in place.
  List<_Placement> _placeChildren() {
    // Upper bound on how many rows the algorithm can need. The worst
    // case is every child having `rowSpan` of the tallest child, so
    // `Σ rowSpan` rows is always enough.
    var rowBudget = 0;
    for (
      RenderBox? child = firstChild;
      child != null;
      child = childAfter(child)
    ) {
      final data = child.parentData! as GridParentData;
      rowBudget += math.max(1, data.rowSpan);
    }
    if (rowBudget == 0) return const [];

    // Immutable fold: each iteration snapshots the children list as
    // we go and threads an occupancy-mask list forward, so the tuple
    // (placements, masks) is recomputed per child rather than edited
    // in place.
    var masks = List.filled(rowBudget, 0);
    final placements = <_Placement>[];
    for (
      RenderBox? child = firstChild;
      child != null;
      child = childAfter(child)
    ) {
      final result = _placeSingle(child, masks);
      masks = result.masks;
      placements.add(result.placement);
    }
    return List.unmodifiable(placements);
  }

  _PlaceResult _placeSingle(RenderBox child, List<int> masks) {
    final data = child.parentData! as GridParentData;
    final colSpan = data.colSpan.clamp(1, _columns);
    final rowSpan = math.max(1, data.rowSpan);
    final colMask = _maskForSpan(colSpan);
    for (var row = 0; row <= masks.length - rowSpan; row += 1) {
      for (var col = 0; col + colSpan <= _columns; col += 1) {
        final shifted = colMask << col;
        if (_isFreeRange(masks, row, rowSpan, shifted)) {
          return _PlaceResult(
            placement: _Placement(
              row: row,
              col: col,
              colSpan: colSpan,
              rowSpan: rowSpan,
              child: child,
            ),
            masks: _withOccupied(masks, row, rowSpan, shifted),
          );
        }
      }
    }
    // Defensive fallback: row budget is the sum of row-spans, so a
    // spot always exists in practice. If the grid somehow overflows
    // we anchor at (0,0) without marking the masks so the caller at
    // least gets stable geometry instead of an infinite loop.
    return _PlaceResult(
      placement: _Placement(
        row: 0,
        col: 0,
        colSpan: colSpan,
        rowSpan: rowSpan,
        child: child,
      ),
      masks: masks,
    );
  }

  int _maskForSpan(int span) => (1 << span) - 1;

  bool _isFreeRange(List<int> masks, int startRow, int rowSpan, int mask) {
    for (var r = startRow; r < startRow + rowSpan; r += 1) {
      if ((masks[r] & mask) != 0) return false;
    }
    return true;
  }

  List<int> _withOccupied(
    List<int> masks,
    int startRow,
    int rowSpan,
    int mask,
  ) {
    return [
      for (var i = 0; i < masks.length; i += 1)
        if (i >= startRow && i < startRow + rowSpan)
          masks[i] | mask
        else
          masks[i],
    ];
  }

  double _sumRowRange(List<double> rowHeights, int start, int count) {
    var total = 0.0;
    for (var i = start; i < start + count; i += 1) {
      total += rowHeights[i];
    }
    total += _cellSpacing * (count - 1);
    return total;
  }
}

class _Placement {
  const _Placement({
    required this.child,
    required this.row,
    required this.col,
    required this.colSpan,
    required this.rowSpan,
  });

  final RenderBox child;
  final int row;
  final int col;
  final int colSpan;
  final int rowSpan;
}

class _PlaceResult {
  const _PlaceResult({required this.placement, required this.masks});

  final _Placement placement;
  final List<int> masks;
}
