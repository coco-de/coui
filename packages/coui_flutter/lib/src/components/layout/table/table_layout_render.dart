/// Shared table layout engine (RenderBox-based) used by both legacy
/// [Table]/[ResizableTable] and the unified `Table`/`ResizableTable`.
///
/// Accepts `CoreTableSize` (sealed) directly so callers do not depend on
/// legacy `TableSize` hierarchy.
library;

import 'dart:math';

import 'package:coui_core/coui_core.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

const _kDefaultColumnSpan = 1;
const _kDefaultRowSpan = 1;

/// Supplies a [CoreTableSize] for a given column or row index.
typedef TableLayoutSizeSupplier = CoreTableSize Function(int index);

/// Returns whether a `(index, span)` cell is frozen along an axis.
typedef TableLayoutCellPredicate = bool Function(int index, int span);

/// Computes an intrinsic extent for [child] given available [extent].
typedef TableLayoutIntrinsicComputer =
    double Function(
      RenderBox child,
      double extent,
    );

/// Result of running the table layout algorithm.
class TableLayoutResult {
  /// Creates a [TableLayoutResult].
  const TableLayoutResult({
    required this.columnWidths,
    required this.rowHeights,
    required this.remainingWidth,
    required this.remainingHeight,
    required this.remainingLooseWidth,
    required this.remainingLooseHeight,
    required this.hasTightFlexWidth,
    required this.hasTightFlexHeight,
  });

  /// Resolved column widths in pixels, indexed by column.
  final List<double> columnWidths;

  /// Resolved row heights in pixels, indexed by row.
  final List<double> rowHeights;

  /// Remaining width (tight flex share pool).
  final double remainingWidth;

  /// Remaining height (tight flex share pool).
  final double remainingHeight;

  /// Remaining loose width (loose flex share pool).
  final double remainingLooseWidth;

  /// Remaining loose height (loose flex share pool).
  final double remainingLooseHeight;

  /// Whether any column flex uses [FlexFit.tight] semantics.
  final bool hasTightFlexWidth;

  /// Whether any row flex uses [FlexFit.tight] semantics.
  final bool hasTightFlexHeight;

  /// Cell offset in pixels for the given [column] and [row].
  Offset getOffset(int column, int row) {
    var x = 0.0;
    for (var i = 0; i < column; i++) {
      x += columnWidths[i];
    }
    var y = 0.0;
    for (var i = 0; i < row; i++) {
      y += rowHeights[i];
    }
    return Offset(x, y);
  }

  /// Total layout size (sum of all column widths × sum of all row heights).
  Size get size => .new(width, height);

  /// Total width in pixels.
  double get width => columnWidths.fold(0, (acc, v) => acc + v);

  /// Total height in pixels.
  double get height => rowHeights.fold(0, (acc, v) => acc + v);
}

/// Parent data attached to each cell by [TableLayoutWidget].
class TableLayoutParentData extends ContainerBoxParentData<RenderBox> {
  /// 0-based column index.
  int? column;

  /// 0-based row index.
  int? row;

  /// Number of columns spanned (default 1).
  int? columnSpan;

  /// Number of rows spanned (default 1).
  int? rowSpan;

  /// Whether this cell participates in size computation. Overlays set false.
  bool computeSize = true;

  /// Whether the resolved row is frozen (filled during performLayout).
  bool frozenRow = false;

  /// Whether the resolved column is frozen (filled during performLayout).
  bool frozenColumn = false;
}

/// Wraps a cell child with its table coordinates and span, contributing
/// [TableLayoutParentData] for the layout engine.
class TableLayoutCell extends ParentDataWidget<TableLayoutParentData> {
  /// Creates a [TableLayoutCell].
  const TableLayoutCell({
    required this.column,
    required this.row,
    this.columnSpan = _kDefaultColumnSpan,
    this.rowSpan = _kDefaultRowSpan,
    this.computeSize = true,
    required super.child,
    super.key,
  });

  /// Column index.
  final int column;

  /// Row index.
  final int row;

  /// Columns spanned (default 1).
  final int columnSpan;

  /// Rows spanned (default 1).
  final int rowSpan;

  /// Participates in size computation (overlays set false).
  final bool computeSize;

  @override
  void applyParentData(RenderObject renderObject) {
    final parentData = renderObject.parentData! as TableLayoutParentData;
    var needsLayout = false;
    if (parentData.column != column) {
      parentData.column = column;
      needsLayout = true;
    }
    if (parentData.row != row) {
      parentData.row = row;
      needsLayout = true;
    }
    if (parentData.columnSpan != columnSpan) {
      parentData.columnSpan = columnSpan;
      needsLayout = true;
    }
    if (parentData.rowSpan != rowSpan) {
      parentData.rowSpan = rowSpan;
      needsLayout = true;
    }
    if (parentData.computeSize != computeSize) {
      parentData.computeSize = computeSize;
      needsLayout = true;
    }
    if (needsLayout) {
      final parent = renderObject.parent;
      if (parent is RenderObject) {
        parent.markNeedsLayout();
      }
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => TableLayoutWidget;
}

/// Multi-child widget hosting [TableLayoutCell] children arranged by
/// [RenderTableLayoutBox].
class TableLayoutWidget extends MultiChildRenderObjectWidget {
  /// Creates a [TableLayoutWidget].
  const TableLayoutWidget({
    required this.width,
    required this.height,
    required this.clipBehavior,
    this.frozenColumn,
    this.frozenRow,
    this.horizontalOffset,
    this.verticalOffset,
    this.viewportSize,
    super.children,
    super.key,
  });

  /// Column size supplier.
  final TableLayoutSizeSupplier width;

  /// Row size supplier.
  final TableLayoutSizeSupplier height;

  /// Clip behavior on overflow.
  final Clip clipBehavior;

  /// Optional frozen-column predicate.
  final TableLayoutCellPredicate? frozenColumn;

  /// Optional frozen-row predicate.
  final TableLayoutCellPredicate? frozenRow;

  /// Horizontal scroll offset (pixels).
  final double? horizontalOffset;

  /// Vertical scroll offset (pixels).
  final double? verticalOffset;

  /// Viewport size when scrolling.
  final Size? viewportSize;

  @override
  RenderTableLayoutBox createRenderObject(BuildContext context) {
    return RenderTableLayoutBox(
      width: width,
      height: height,
      clipBehavior: clipBehavior,
      frozenColumn: frozenColumn,
      frozenRow: frozenRow,
      horizontalOffset: horizontalOffset,
      verticalOffset: verticalOffset,
      viewportSize: viewportSize,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderTableLayoutBox renderObject,
  ) {
    var needsRelayout = false;
    if (renderObject._width != width) {
      renderObject._width = width;
      needsRelayout = true;
    }
    if (renderObject._height != height) {
      renderObject._height = height;
      needsRelayout = true;
    }
    if (renderObject._clipBehavior != clipBehavior) {
      renderObject._clipBehavior = clipBehavior;
      needsRelayout = true;
    }
    if (renderObject._frozenColumn != frozenColumn) {
      renderObject._frozenColumn = frozenColumn;
      needsRelayout = true;
    }
    if (renderObject._frozenRow != frozenRow) {
      renderObject._frozenRow = frozenRow;
      needsRelayout = true;
    }
    if (renderObject._horizontalOffset != horizontalOffset) {
      renderObject._horizontalOffset = horizontalOffset;
      needsRelayout = true;
    }
    if (renderObject._verticalOffset != verticalOffset) {
      renderObject._verticalOffset = verticalOffset;
      needsRelayout = true;
    }
    if (renderObject._viewportSize != viewportSize) {
      renderObject._viewportSize = viewportSize;
      needsRelayout = true;
    }
    if (needsRelayout) {
      renderObject.markNeedsLayout();
    }
  }
}

/// RenderBox that performs table layout using [CoreTableSize] suppliers.
class RenderTableLayoutBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, TableLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, TableLayoutParentData> {
  /// Creates a [RenderTableLayoutBox].
  RenderTableLayoutBox({
    required TableLayoutSizeSupplier width,
    required TableLayoutSizeSupplier height,
    required Clip clipBehavior,
    TableLayoutCellPredicate? frozenColumn,
    TableLayoutCellPredicate? frozenRow,
    double? horizontalOffset,
    double? verticalOffset,
    Size? viewportSize,
    List<RenderBox>? children,
  }) : _width = width,
       _height = height,
       _clipBehavior = clipBehavior,
       _frozenColumn = frozenColumn,
       _frozenRow = frozenRow,
       _horizontalOffset = horizontalOffset,
       _verticalOffset = verticalOffset,
       _viewportSize = viewportSize {
    addAll(children);
  }

  TableLayoutSizeSupplier _width;
  TableLayoutSizeSupplier _height;
  Clip _clipBehavior;
  TableLayoutCellPredicate? _frozenColumn;
  TableLayoutCellPredicate? _frozenRow;
  double? _horizontalOffset;
  double? _verticalOffset;
  Size? _viewportSize;

  // Row `SemanticsNode`s, keyed by row index, reused across
  // `assembleSemanticsNode` calls so row identity is stable frame to
  // frame (screen readers key focus/announcement continuity off node
  // identity). Reassigned wholesale each call — see
  // `_buildRowSemanticsNodes` — rather than mutated in place.
  Map<int, SemanticsNode> _cachedRowSemanticsNodes = <int, SemanticsNode>{};

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! TableLayoutParentData) {
      child.parentData = TableLayoutParentData();
    }
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..role = .table
      ..isSemanticBoundary = true
      ..explicitChildNodes = true;
  }

  @override
  void clearSemantics() {
    super.clearSemantics();
    _cachedRowSemanticsNodes = <int, SemanticsNode>{};
  }

  /// Groups the flat per-cell semantics children into per-row
  /// `SemanticsRole.row` nodes.
  ///
  /// Table rows have no render object of their own — cells are direct
  /// render children of this box, positioned individually via
  /// [TableLayoutParentData]. `assembleSemanticsNode` is the mechanism
  /// Flutter's own `RenderTable` uses for the same problem
  /// (rendering/table.dart), except that reference has to infer each
  /// cell's row/column from paint geometry because it doesn't carry an
  /// explicit index. Here [TableLayoutParentData.row] already has it, so
  /// grouping is a single pass zipping the render-child list (which
  /// carries `row`) against the semantics-child list (which carries the
  /// actual node) — both walk the same child-list order.
  @override
  void assembleSemanticsNode(
    SemanticsNode node,
    SemanticsConfiguration config,
    Iterable<SemanticsNode> children,
  ) {
    final semanticsChildren = children.toList(growable: false);
    var walker = firstChild;
    final childRows = List.generate(semanticsChildren.length, (_) {
      final current = walker!;
      walker = childAfter(current);
      return (current.parentData! as TableLayoutParentData).row;
    });

    final cellsByRow = <int, List<SemanticsNode>>{};
    for (var i = 0; i < semanticsChildren.length; i++) {
      final row = childRows[i];
      if (row == null) continue;
      cellsByRow[row] = [...?cellsByRow[row], semanticsChildren[i]];
    }

    final rowEntries = [
      for (final entry in cellsByRow.entries)
        _buildRowSemanticsNode(entry, _cachedRowSemanticsNodes[entry.key]),
    ];
    _cachedRowSemanticsNodes = {
      for (final e in rowEntries) e.rowIndex: e.node,
    };

    node.updateWith(
      config: config,
      childrenInInversePaintOrder: [for (final e in rowEntries) e.node],
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    var child = firstChild;
    while (child != null) {
      final parentData = child.parentData! as TableLayoutParentData;
      final innerChild = child;
      final hit = result.addWithPaintOffset(
        offset: parentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          return innerChild.hitTest(result, position: transformed);
        },
      );
      if (hit) return true;
      child = childAfter(child);
    }
    return false;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return computeTableSize(
      BoxConstraints.loose(Size(.infinity, height)),
      (child, extent) => child.getMinIntrinsicWidth(extent),
    ).width;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return computeTableSize(
      BoxConstraints.loose(Size(.infinity, height)),
      (child, extent) => child.getMaxIntrinsicWidth(extent),
    ).width;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return computeTableSize(
      BoxConstraints.loose(Size(width, .infinity)),
      (child, extent) => child.getMinIntrinsicHeight(extent),
    ).height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return computeTableSize(
      BoxConstraints.loose(Size(width, .infinity)),
      (child, extent) => child.getMaxIntrinsicHeight(extent),
    ).height;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return computeTableSize(constraints).size;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // Paints in three layers (regular, frozen column, frozen row) with the
    // last child painted first so that earlier children stay on top.
    if (_clipBehavior != .none) {
      final _ = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        (context, offset) => _paintRegular(context, offset),
        clipBehavior: _clipBehavior,
      );
      final _ = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        (context, offset) => _paintFrozenColumns(context, offset),
        clipBehavior: _clipBehavior,
      );
      final _ = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        (context, offset) => _paintFrozenRows(context, offset),
        clipBehavior: _clipBehavior,
      );
      return;
    }
    _paintRegular(context, offset);
    _paintFrozenColumns(context, offset);
    _paintFrozenRows(context, offset);
  }

  @override
  void performLayout() {
    final result = computeTableSize(constraints);
    size = constraints.constrain(result.size);

    final frozenRowHeights = <int, double>{};
    final frozenColumnWidths = <int, double>{};

    var child = firstChild;
    while (child != null) {
      final parentData = child.parentData! as TableLayoutParentData;
      final column = parentData.column;
      final row = parentData.row;
      if (column == null || row == null) {
        child = childAfter(child);
        continue;
      }

      final columnSpan = parentData.columnSpan ?? _kDefaultColumnSpan;
      final rowSpan = parentData.rowSpan ?? _kDefaultRowSpan;
      final frozenRow = _frozenRow?.call(row, rowSpan) ?? false;
      final frozenColumn = _frozenColumn?.call(column, columnSpan) ?? false;

      var width = 0.0;
      for (
        var i = 0;
        i < columnSpan && column + i < result.columnWidths.length;
        i++
      ) {
        width += result.columnWidths[column + i];
      }
      var height = 0.0;
      for (var i = 0; i < rowSpan && row + i < result.rowHeights.length; i++) {
        height += result.rowHeights[row + i];
      }

      child.layout(
        BoxConstraints.tightFor(width: width, height: height),
      );

      final baseOffset = result.getOffset(column, row);
      var offsetX = baseOffset.dx;
      var offsetY = baseOffset.dy;

      if (frozenRow) {
        var verticalOffset = _verticalOffset ?? 0;
        verticalOffset = max(0, verticalOffset);
        final viewportSize = _viewportSize;
        if (viewportSize != null) {
          final maxVerticalOffset = size.height - viewportSize.height;
          verticalOffset = min(verticalOffset, maxVerticalOffset);
        }
        final offsetInViewport = offsetY - verticalOffset;
        var minViewport = 0.0;
        final maxViewport = constraints.minHeight;
        for (var i = 0; i < row; i++) {
          minViewport += frozenRowHeights[i] ?? 0;
        }
        var verticalAdjustment = 0.0;
        if (offsetInViewport < minViewport) {
          verticalAdjustment = -offsetInViewport + minViewport;
        } else if (offsetInViewport + height > maxViewport) {
          verticalAdjustment = maxViewport - offsetInViewport - height;
        }
        frozenRowHeights[row] = max(frozenRowHeights[row] ?? 0, height);
        offsetY += verticalAdjustment;
      }

      if (frozenColumn) {
        var horizontalOffset = _horizontalOffset ?? 0;
        horizontalOffset = max(0, horizontalOffset);
        final viewportSize = _viewportSize;
        if (viewportSize != null) {
          final maxHorizontalOffset = size.width - viewportSize.width;
          horizontalOffset = min(horizontalOffset, maxHorizontalOffset);
        }
        final offsetInViewport = offsetX - horizontalOffset;
        var minViewport = 0.0;
        final maxViewport = constraints.minWidth;
        for (var i = 0; i < column; i++) {
          minViewport += frozenColumnWidths[i] ?? 0;
        }
        var horizontalAdjustment = 0.0;
        if (offsetInViewport < minViewport) {
          horizontalAdjustment = -offsetInViewport + minViewport;
        } else if (offsetInViewport + width > maxViewport) {
          horizontalAdjustment = maxViewport - offsetInViewport - width;
        }
        frozenColumnWidths[column] = max(
          frozenColumnWidths[column] ?? 0,
          width,
        );
        offsetX += horizontalAdjustment;
      }

      parentData.frozenRow = frozenRow;
      parentData.frozenColumn = frozenColumn;
      parentData.offset = Offset(offsetX, offsetY);

      child = childAfter(child);
    }
  }

  /// Computes column widths, row heights, and leftover space using the
  /// provided [constraints] and optional [intrinsicComputer].
  TableLayoutResult computeTableSize(
    BoxConstraints constraints, [
    TableLayoutIntrinsicComputer? intrinsicComputer,
  ]) {
    var flexWidth = 0.0;
    var flexHeight = 0.0;
    var fixedWidth = 0.0;
    var fixedHeight = 0.0;

    final columnWidths = <int, double>{};
    final rowHeights = <int, double>{};

    var maxRow = 0;
    var maxColumn = 0;

    // Discover bounds.
    var child = firstChild;
    while (child != null) {
      final parentData = child.parentData! as TableLayoutParentData;
      if (parentData.computeSize) {
        final column = parentData.column;
        final row = parentData.row;
        if (column != null && row != null) {
          final columnSpan = parentData.columnSpan ?? _kDefaultColumnSpan;
          final rowSpan = parentData.rowSpan ?? _kDefaultRowSpan;
          maxColumn = max(maxColumn, column + columnSpan - 1);
          maxRow = max(maxRow, row + rowSpan - 1);
        }
      }
      child = childAfter(child);
    }

    var hasFlexWidth = false;
    var hasFlexHeight = false;
    var hasTightFlexWidth = false;
    var hasTightFlexHeight = false;

    // Collect fixed and flex contributions for columns.
    for (var c = 0; c <= maxColumn; c++) {
      final spec = _width(c);
      if (spec is CoreFlexTableSize && constraints.hasBoundedWidth) {
        flexWidth += spec.flex;
        hasFlexWidth = true;
        // Legacy used FlexFit.tight; Core flex has no fit attribute so it is
        // always tight.
        hasTightFlexWidth = true;
      } else if (spec is CoreFixedTableSize) {
        fixedWidth += spec.value;
        columnWidths[c] = max(columnWidths[c] ?? 0, spec.value);
      }
    }

    // Collect fixed and flex contributions for rows.
    for (var r = 0; r <= maxRow; r++) {
      final spec = _height(r);
      if (spec is CoreFlexTableSize &&
          constraints.hasBoundedHeight &&
          intrinsicComputer == null) {
        flexHeight += spec.flex;
        hasFlexHeight = true;
        hasTightFlexHeight = true;
      } else if (spec is CoreFixedTableSize) {
        fixedHeight += spec.value;
        rowHeights[r] = max(rowHeights[r] ?? 0, spec.value);
      }
    }

    // Seeds for the intrinsic clamps and for any column / row no cell
    // covers. Held apart from the remainders returned below, which are
    // recomputed once each axis has actually been measured.
    final seedWidth = constraints.hasBoundedWidth
        ? constraints.maxWidth - fixedWidth
        : double.infinity;
    final seedHeight = constraints.hasBoundedHeight
        ? constraints.maxHeight - fixedHeight
        : double.infinity;

    var remainingWidth = seedWidth;
    var remainingHeight = seedHeight;

    // Pass intrinsic cell WIDTHS.
    //
    // Widths finish, and flex widths are distributed, before any row height
    // is measured. Measuring both in one walk read `columnWidths[column]`
    // while it was still null for flex columns, so a row was measured
    // against the whole leftover width and then laid out into one column's
    // share of it — content wrapped tighter than the height reserved for
    // it, and the overflow was clipped rather than reported.
    child = lastChild;
    while (child != null) {
      final parentData = child.parentData! as TableLayoutParentData;
      if (parentData.computeSize) {
        final column = parentData.column;
        final row = parentData.row;
        if (column != null && row != null) {
          final widthSpec = _width(column);
          if (widthSpec is CoreIntrinsicTableSize ||
              (widthSpec is CoreFlexTableSize && intrinsicComputer != null)) {
            final extent = rowHeights[row] ?? seedHeight;
            var intrinsicWidth = intrinsicComputer == null
                ? child.getMaxIntrinsicWidth(extent)
                : intrinsicComputer(child, extent);
            // Clamp before distributing across span so the final per-column
            // value cannot exceed the available width.
            intrinsicWidth = min(intrinsicWidth, seedWidth);
            final columnSpan = parentData.columnSpan ?? _kDefaultColumnSpan;
            intrinsicWidth /= columnSpan;
            for (var i = 0; i < columnSpan; i++) {
              columnWidths[column + i] = max(
                columnWidths[column + i] ?? 0,
                intrinsicWidth,
              );
            }
          }
        }
      }
      child = childBefore(child);
    }

    final usedColumnWidth = columnWidths.values.fold<double>(
      0,
      (acc, v) => acc + v,
    );

    var remainingLooseWidth = remainingWidth;

    if (intrinsicComputer == null) {
      remainingWidth = constraints.hasBoundedWidth
          ? constraints.maxWidth - usedColumnWidth
          : .infinity;
      remainingLooseWidth = constraints.hasInfiniteWidth
          ? .infinity
          : max(0, constraints.minWidth - usedColumnWidth);

      final spacePerFlexWidth = (flexWidth > 0 && remainingWidth > 0)
          ? remainingWidth / flexWidth
          : 0;

      if (hasFlexWidth) {
        for (var c = 0; c <= maxColumn; c++) {
          final spec = _width(c);
          if (spec is CoreFlexTableSize) {
            columnWidths[c] = spec.flex * spacePerFlexWidth;
          }
        }
      }
    }

    // Pass intrinsic cell HEIGHTS, against the now-resolved column widths.
    //
    // The extent sums the column span the way `performLayout` does, so the
    // width a row is measured at is the width its cell is laid out at.
    child = lastChild;
    while (child != null) {
      final parentData = child.parentData! as TableLayoutParentData;
      if (parentData.computeSize) {
        final column = parentData.column;
        final row = parentData.row;
        if (column != null && row != null) {
          final heightSpec = _height(row);
          if (heightSpec is CoreIntrinsicTableSize ||
              (heightSpec is CoreFlexTableSize && intrinsicComputer != null)) {
            final columnSpan = parentData.columnSpan ?? _kDefaultColumnSpan;
            var extent = 0.0;
            for (var i = 0; i < columnSpan; i++) {
              extent += columnWidths[column + i] ?? 0;
            }
            if (extent <= 0) {
              // No spec wrote this column (unbounded width, or a column no
              // cell covers) — fall back rather than measure against zero.
              extent = seedWidth;
            }
            var intrinsicHeight = intrinsicComputer == null
                ? child.getMaxIntrinsicHeight(extent)
                : intrinsicComputer(child, extent);
            intrinsicHeight = min(intrinsicHeight, seedHeight);
            final rowSpan = parentData.rowSpan ?? _kDefaultRowSpan;
            intrinsicHeight /= rowSpan;
            for (var i = 0; i < rowSpan; i++) {
              rowHeights[row + i] = max(
                rowHeights[row + i] ?? 0,
                intrinsicHeight,
              );
            }
          }
        }
      }
      child = childBefore(child);
    }

    final usedRowHeight = rowHeights.values.fold<double>(
      0,
      (acc, v) => acc + v,
    );

    var remainingLooseHeight = remainingHeight;

    if (intrinsicComputer == null) {
      remainingHeight = constraints.hasBoundedHeight
          ? constraints.maxHeight - usedRowHeight
          : .infinity;
      remainingLooseHeight = constraints.hasInfiniteHeight
          ? .infinity
          : max(0, constraints.minHeight - usedRowHeight);

      final spacePerFlexHeight = (flexHeight > 0 && remainingHeight > 0)
          ? remainingHeight / flexHeight
          : 0;

      if (hasFlexHeight) {
        for (var r = 0; r <= maxRow; r++) {
          final spec = _height(r);
          if (spec is CoreFlexTableSize) {
            rowHeights[r] = spec.flex * spacePerFlexHeight;
          }
        }
      }
    }

    final columnWidthsList = List.generate(
      maxColumn + 1,
      (index) => columnWidths[index] ?? 0,
    );
    final rowHeightsList = List.generate(
      maxRow + 1,
      (index) => rowHeights[index] ?? 0,
    );

    return TableLayoutResult(
      columnWidths: columnWidthsList,
      rowHeights: rowHeightsList,
      remainingWidth: remainingWidth,
      remainingHeight: remainingHeight,
      remainingLooseWidth: remainingLooseWidth,
      remainingLooseHeight: remainingLooseHeight,
      hasTightFlexWidth: hasTightFlexWidth,
      hasTightFlexHeight: hasTightFlexHeight,
    );
  }

  /// A cell's bounding box in the table's local coordinate space (its
  /// [SemanticsNode.rect] shifted by its own translation). Row nodes built
  /// by [_buildRowSemanticsNode] carry an identity transform, so this is
  /// also the space row rects are computed in — no re-basing needed when
  /// a cell becomes a child of a row instead of the table directly.
  static Rect _childRectInTableSpace(SemanticsNode child) {
    final transform = child.transform;
    final offset =
        (transform == null ? null : MatrixUtils.getAsTranslation(transform)) ??
        .zero;
    return child.rect.shift(offset);
  }

  /// Builds (or reuses, from [cached]) the `SemanticsRole.row` node for
  /// one row's grouped cells, returning it alongside its row index so
  /// [assembleSemanticsNode] can fold the results into both the ordered
  /// child list and the next cache generation with a single non-mutating
  /// pass (no `.add`/`putIfAbsent` on the live cache).
  static ({int rowIndex, SemanticsNode node}) _buildRowSemanticsNode(
    MapEntry<int, List<SemanticsNode>> entry,
    SemanticsNode? cached,
  ) {
    final rowIndex = entry.key;
    final cells = entry.value;
    var rowRect = _childRectInTableSpace(cells.first);
    for (var i = 1; i < cells.length; i++) {
      rowRect = rowRect.expandToInclude(_childRectInTableSpace(cells[i]));
    }
    final rowNode = cached ?? SemanticsNode();
    rowNode
      ..updateWith(
        config: SemanticsConfiguration()
          ..role = .row
          ..indexInParent = rowIndex,
        childrenInInversePaintOrder: cells,
      )
      // Identity transform: cells keep the table-relative transform they
      // already had, so nesting them one level deeper under the row
      // needs no re-basing (contrast `RenderTable`, whose rows have a
      // real painted offset and must shift every cell child).
      ..transform = null
      ..rect = rowRect;
    return (rowIndex: rowIndex, node: rowNode);
  }

  void _paintRegular(PaintingContext context, Offset offset) {
    var child = lastChild;
    while (child != null) {
      final parentData = child.parentData! as TableLayoutParentData;
      if (!parentData.frozenRow && !parentData.frozenColumn) {
        context.paintChild(child, offset + parentData.offset);
      }
      child = childBefore(child);
    }
  }

  void _paintFrozenColumns(PaintingContext context, Offset offset) {
    var child = lastChild;
    while (child != null) {
      final parentData = child.parentData! as TableLayoutParentData;
      if (parentData.frozenColumn) {
        context.paintChild(child, offset + parentData.offset);
      }
      child = childBefore(child);
    }
  }

  void _paintFrozenRows(PaintingContext context, Offset offset) {
    var child = lastChild;
    while (child != null) {
      final parentData = child.parentData! as TableLayoutParentData;
      if (parentData.frozenRow) {
        context.paintChild(child, offset + parentData.offset);
      }
      child = childBefore(child);
    }
  }
}
