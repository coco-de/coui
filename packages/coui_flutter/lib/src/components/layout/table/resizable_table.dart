import 'package:coui_flutter/coui_flutter.dart';

/// Unified resizable table for Flutter.
///
/// Extends [Table] semantics with drag-based column/row resizing via a
/// [ResizableTableController]. Resize modes ([columnResizeMode],
/// [rowResizeMode]) control whether neighboring cells shrink to compensate.
///
/// surface:content — same face as [Table], which shares its resolver.
class ResizableTable extends StatefulWidget
    implements CoreResizableTableContract<Widget> {
  /// Creates a [ResizableTable].
  const ResizableTable({
    required this.rows,
    required this.controller,
    this.columnResizeMode = CoreTableCellResizeMode.reallocate,
    this.rowResizeMode = CoreTableCellResizeMode.expand,
    this.frozenCells,
    this.horizontalOffset,
    this.verticalOffset,
    this.theme,
    this.clipBehavior = CoreClipMode.hardEdge,
    super.key,
    this.tableStyle,
  });

  @override
  final List<CoreTableRowData<Widget>> rows;

  @override
  final ResizableTableController controller;

  @override
  final CoreTableCellResizeMode columnResizeMode;

  @override
  final CoreTableCellResizeMode rowResizeMode;

  @override
  final CoreFrozenTableData? frozenCells;

  @override
  final double? horizontalOffset;

  @override
  final double? verticalOffset;

  /// Widget-level theme override.
  final CoreTableTheme? theme;

  @override
  final CoreClipMode clipBehavior;

  /// Per-instance composite style — chrome flat fields plus nested
  /// `headerTextStyle` / `cellTextStyle` slots. See [CoreTableStyle]
  /// for the merge chain.
  @override
  final CoreTableStyle? tableStyle;

  /// Returns a copy of this [ResizableTable] with the given fields
  /// replaced. All fields default to this instance's current value when
  /// omitted.
  ResizableTable copyWith({
    Key? key,
    List<CoreTableRowData<Widget>>? rows,
    ResizableTableController? controller,
    CoreTableCellResizeMode? columnResizeMode,
    CoreTableCellResizeMode? rowResizeMode,
    CoreFrozenTableData? frozenCells,
    double? horizontalOffset,
    double? verticalOffset,
    CoreTableTheme? theme,
    CoreClipMode? clipBehavior,
    CoreTableStyle? tableStyle,
  }) {
    return ResizableTable(
      key: key ?? this.key,
      rows: rows ?? this.rows,
      controller: controller ?? this.controller,
      columnResizeMode: columnResizeMode ?? this.columnResizeMode,
      rowResizeMode: rowResizeMode ?? this.rowResizeMode,
      frozenCells: frozenCells ?? this.frozenCells,
      horizontalOffset: horizontalOffset ?? this.horizontalOffset,
      verticalOffset: verticalOffset ?? this.verticalOffset,
      theme: theme ?? this.theme,
      clipBehavior: clipBehavior ?? this.clipBehavior,
      tableStyle: tableStyle ?? this.tableStyle,
    );
  }

  @override
  State<ResizableTable> createState() => _ResizableTableState();
}

class _ResizableTableState extends State<ResizableTable> {
  final _hoveredCellNotifier = ValueNotifier<_HoveredCell?>(null);
  final _hoveredColumnTargetNotifier = ValueNotifier<int?>(null);
  final _hoveredRowTargetNotifier = ValueNotifier<int?>(null);
  final _draggingColumnTargetNotifier = ValueNotifier<int?>(null);
  final _draggingRowTargetNotifier = ValueNotifier<int?>(null);

  // Drag snapshots captured on drag start so reallocate mode applies the
  // accumulated delta against the original sizes on every frame
  // (shadcn_flutter Resizer / Web parity). Mutating the controller each
  // frame and recomputing from the current state loses reversibility —
  // once a neighbour shrinks, dragging the handle back doesn't restore it.
  List<double>? _columnDragSnapshot;
  List<double>? _columnDragMinSnapshot;
  List<double?>? _columnDragMaxSnapshot;
  double? _columnDragStartValue;
  List<double>? _rowDragSnapshot;
  List<double>? _rowDragMinSnapshot;
  List<double?>? _rowDragMaxSnapshot;
  double? _rowDragStartValue;

  void _handleColumnDragStart(int totalColumns, int target) {
    _columnDragSnapshot = List.generate(
      totalColumns,
      widget.controller.getColumnWidth,
    );
    _columnDragMinSnapshot = List.generate(
      totalColumns,
      (i) => widget.controller.getColumnMinWidth(i) ?? 0.0,
    );
    _columnDragMaxSnapshot = List.generate(
      totalColumns,
      widget.controller.getColumnMaxWidth,
    );
    _columnDragStartValue = widget.controller.getColumnWidth(target);
    _draggingColumnTargetNotifier.value = target;
  }

  void _handleColumnDragUpdate(int target, double accumulatedDelta) {
    final snapshot = _columnDragSnapshot;
    if (snapshot == null) return;
    if (widget.columnResizeMode == .expand) {
      final start = _columnDragStartValue ?? snapshot[target];
      widget.controller.resizeColumn(target, start + accumulatedDelta);
      return;
    }
    final resizer = CoreTrackResizer(
      sizes: snapshot,
      minSizes: _columnDragMinSnapshot!,
      maxSizes: _columnDragMaxSnapshot!,
    );
    if (!resizer.dragDivider(target, accumulatedDelta)) return;
    for (var i = 0; i < snapshot.length; i++) {
      widget.controller.resizeColumn(i, resizer.sizeAt(i));
    }
  }

  void _handleColumnDragEnd() {
    _columnDragSnapshot = null;
    _columnDragMinSnapshot = null;
    _columnDragMaxSnapshot = null;
    _columnDragStartValue = null;
    _draggingColumnTargetNotifier.value = null;
  }

  void _handleRowDragStart(int totalRows, int target) {
    _rowDragSnapshot = List.generate(
      totalRows,
      widget.controller.getRowHeight,
    );
    _rowDragMinSnapshot = List.generate(
      totalRows,
      (i) => widget.controller.getRowMinHeight(i) ?? 0.0,
    );
    _rowDragMaxSnapshot = List.generate(
      totalRows,
      widget.controller.getRowMaxHeight,
    );
    _rowDragStartValue = widget.controller.getRowHeight(target);
    _draggingRowTargetNotifier.value = target;
  }

  void _handleRowDragUpdate(int target, double accumulatedDelta) {
    final snapshot = _rowDragSnapshot;
    if (snapshot == null) return;
    if (widget.rowResizeMode == .expand) {
      final start = _rowDragStartValue ?? snapshot[target];
      widget.controller.resizeRow(target, start + accumulatedDelta);
      return;
    }
    final resizer = CoreTrackResizer(
      sizes: snapshot,
      minSizes: _rowDragMinSnapshot!,
      maxSizes: _rowDragMaxSnapshot!,
    );
    if (!resizer.dragDivider(target, accumulatedDelta)) return;
    for (var i = 0; i < snapshot.length; i++) {
      widget.controller.resizeRow(i, resizer.sizeAt(i));
    }
  }

  void _handleRowDragEnd() {
    _rowDragSnapshot = null;
    _rowDragMinSnapshot = null;
    _rowDragMaxSnapshot = null;
    _rowDragStartValue = null;
    _draggingRowTargetNotifier.value = null;
  }

  @override
  void dispose() {
    _hoveredCellNotifier.dispose();
    _hoveredColumnTargetNotifier.dispose();
    _hoveredRowTargetNotifier.dispose();
    _draggingColumnTargetNotifier.dispose();
    _draggingRowTargetNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveTable(
      context,
      widgetTheme: widget.theme,
      tableStyle: widget.tableStyle,
    );
    final clip = widget.clipBehavior.toValue();

    final viewportSize =
        resolved.viewportWidth != null && resolved.viewportHeight != null
        ? Size(resolved.viewportWidth!, resolved.viewportHeight!)
        : null;

    // Compute the grid's total column count (max column span sum across
    // rows) so resizer overlays know whether they are the last track.
    var totalColumns = 0;
    for (final row in widget.rows) {
      var c = 0;
      for (final cell in row.cells) {
        c += cell.columnSpan;
      }
      if (c > totalColumns) totalColumns = c;
    }
    final totalRows = widget.rows.length;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final children = <Widget>[];
        // Body-row parity counter for zebra-stripe
        // (`rowAlternateBackgroundColor`) — counts body rows only.
        var bodyRowCursor = 0;
        for (var r = 0; r < widget.rows.length; r++) {
          final row = widget.rows[r];
          final bodyRowEven = row.kind == .body && bodyRowCursor.isEven;
          if (row.kind == .body) bodyRowCursor++;
          var columnCursor = 0;
          for (final cell in row.cells) {
            final columnIndex = columnCursor;
            final rowIndex = r;
            // Mirrors `Table`'s per-cell frozen detection (table.dart) —
            // a cell is frozen when either its row or its column is
            // pinned.
            final isFrozen =
                (widget.frozenCells?.testColumn(
                      columnIndex,
                      cell.columnSpan,
                    ) ??
                    false) ||
                (widget.frozenCells?.testRow(rowIndex, cell.rowSpan) ?? false);
            children.add(
              TableLayoutCell(
                column: columnIndex,
                row: rowIndex,
                columnSpan: cell.columnSpan,
                rowSpan: cell.rowSpan,
                // `container: true` forces a distinct semantics-tree
                // boundary per cell (regardless of what `cell.child`
                // itself does), which
                // `RenderTableLayoutBox.assembleSemanticsNode` then
                // groups by row — see table_layout_render.dart. The
                // resizer overlay is a drag handle with no accessible
                // name, so it stays outside this boundary and is
                // exposed to nothing (Flutter drops semantics-less
                // subtrees automatically).
                child: Semantics(
                  container: true,
                  role: row.kind == .header ? .columnHeader : .cell,
                  child: Stacks(
                    fit: .passthrough,
                    children: [
                      _TableCellContent(
                        row: rowIndex,
                        column: columnIndex,
                        cell: cell,
                        rowKind: row.kind,
                        rowSelected: row.selected,
                        bodyRowEven: bodyRowEven,
                        isFrozen: isFrozen,
                        isLastRow: rowIndex == widget.rows.length - 1,
                        style: resolved,
                        hoveredCellNotifier: _hoveredCellNotifier,
                      ),
                      if (widget.columnResizeMode != .none ||
                          widget.rowResizeMode != .none)
                        Position.fill(
                          child: _CellResizerOverlay(
                            column: columnIndex,
                            row: rowIndex,
                            columnSpan: cell.columnSpan,
                            rowSpan: cell.rowSpan,
                            totalColumns: totalColumns,
                            totalRows: totalRows,
                            columnResizeMode: widget.columnResizeMode,
                            rowResizeMode: widget.rowResizeMode,
                            hoveredColumnNotifier: _hoveredColumnTargetNotifier,
                            hoveredRowNotifier: _hoveredRowTargetNotifier,
                            draggingColumnNotifier:
                                _draggingColumnTargetNotifier,
                            draggingRowNotifier: _draggingRowTargetNotifier,
                            style: resolved,
                            onColumnDragStart: _handleColumnDragStart,
                            onColumnDragUpdate: _handleColumnDragUpdate,
                            onColumnDragEnd: _handleColumnDragEnd,
                            onRowDragStart: _handleRowDragStart,
                            onRowDragUpdate: _handleRowDragUpdate,
                            onRowDragEnd: _handleRowDragEnd,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
            columnCursor += cell.columnSpan;
          }
        }

        final layout = TableLayoutWidget(
          width: (index) =>
              CoreFixedTableSize(widget.controller.getColumnWidth(index)),
          height: (index) =>
              CoreFixedTableSize(widget.controller.getRowHeight(index)),
          clipBehavior: clip,
          frozenColumn: widget.frozenCells?.testColumn,
          frozenRow: widget.frozenCells?.testRow,
          horizontalOffset: widget.horizontalOffset,
          verticalOffset: widget.verticalOffset,
          viewportSize: viewportSize,
          children: children,
        );

        // Inner clip radius insets every corner by the outer border width,
        // preserving any per-corner asymmetry (no single-corner reach-in).
        final innerRadius =
            resolved.borderRadius - .circular(resolved.outerBorderWidth);

        // No internal Scrollable: shadcn_flutter's ResizableTable keeps the
        // scroll concern outside the widget so horizontal/vertical drag
        // gestures on resizers never compete with an inner ScrollView.
        // Callers wrap with their own Scrollable (or pass horizontalOffset/
        // verticalOffset + viewportSize) when they need scrolling.
        // Same surface as its sibling `Table`, which shares this
        // resolver — the cast was resolved for both and read by only
        // one, so a resizable table went flat next to a plain one. And
        // painted outside the box for the same reason `Table` does: this
        // surface states no fill, so a cast drawn behind it has nothing
        // painting over it.
        final decoratedBody = DecoratedBox(
          decoration: BoxDecoration(
            color: resolved.backgroundColor,
            // `Border.all(width: 0)` paints a hairline, so a table with no
            // outer box states no border at all.
            border: resolved.outerBorderWidth > 0
                ? Border.all(
                    color: resolved.borderColor,
                    width: resolved.outerBorderWidth,
                  )
                : null,
            borderRadius: resolved.borderRadius,
          ),
          child: Padding(
            padding: .all(resolved.outerBorderWidth),
            child: ClipRRect(
              borderRadius: innerRadius,
              clipBehavior: clip,
              child: layout,
            ),
          ),
        );

        // Same gate as `Table`: only wrapped once the resolver actually
        // handed over a fill to blur behind.
        final blur = resolved.surfaceBlur;
        final sheen = resolved.surfaceSheen;
        final body = (blur == null || blur <= 0) && sheen == null
            ? decoratedBody
            : SurfaceBlur(
                borderRadius: resolved.borderRadius,
                surfaceBlur: blur,
                surfaceSaturation: resolved.surfaceSaturation,
                surfaceBackdropBrightness: resolved.surfaceBackdropBrightness,
                surfaceSheen: sheen,
                refraction: Theme.of(context).surfaceRefraction,
                child: decoratedBody,
              );

        return InjectedCast(
          shadows: resolved.boxShadow,
          borderRadius: resolved.borderRadius,
          child: body,
        );
      },
    );
  }
}

/// Cell content used by [ResizableTable] rows (same rendering as
/// [Table] but without the cell-level gesture wrapping).
class _TableCellContent extends StatelessWidget {
  const _TableCellContent({
    required this.row,
    required this.column,
    required this.cell,
    required this.rowKind,
    required this.rowSelected,
    required this.bodyRowEven,
    required this.isFrozen,
    required this.isLastRow,
    required this.style,
    required this.hoveredCellNotifier,
  });

  final int row;
  final int column;
  final CoreTableCellData<Widget> cell;
  final CoreTableRowKind rowKind;
  final bool rowSelected;
  final bool bodyRowEven;
  final bool isFrozen;
  final bool isLastRow;
  final ResolvedTable style;
  final ValueNotifier<_HoveredCell?> hoveredCellNotifier;

  @override
  Widget build(BuildContext context) {
    final currentCell = _HoveredCell(
      column: column,
      row: row,
      columnSpan: cell.columnSpan,
      rowSpan: cell.rowSpan,
    );
    final selected = rowSelected || cell.selected;

    final rowBaseColor = switch (rowKind) {
      .header =>
        isFrozen
            ? style.frozenHeaderBackgroundColor
            : style.headerBackgroundColor,
      .footer => style.footerBackgroundColor,
      // Even body rows pick up the zebra-stripe override (when set) as
      // their base background; else a frozen cell picks up the explicit
      // frozen tint (when set); hover / selection layer on top below —
      // mirrors `Table`'s `rowBaseColor` chain (table.dart) 1:1.
      .body =>
        (bodyRowEven ? style.rowAlternateBackgroundColor : null) ??
            (isFrozen ? style.frozenCellBackgroundColor : null) ??
            style.rowBackgroundColor ??
            style.backgroundColor ??
            Colors.transparent,
    };

    return MouseRegion(
      onEnter: (_) {
        if (cell.enabled) hoveredCellNotifier.value = currentCell;
      },
      onExit: (_) {
        if (hoveredCellNotifier.value == currentCell) {
          hoveredCellNotifier.value = null;
        }
      },
      cursor: cell.onPressed != null && cell.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: ValueListenableBuilder<_HoveredCell?>(
        valueListenable: hoveredCellNotifier,
        builder: (context, hovered, _) {
          final isHovered =
              hovered != null &&
              cell.enabled &&
              hovered.intersects(
                currentCell,
                columnHover: cell.columnHover,
                rowHover: cell.rowHover,
              );

          final background = selected
              ? style.rowSelectedColor
              : isHovered
              ? style.rowHoverColor
              : rowBaseColor;

          // Paint-ready cell text style — header / body branch already
          // folds the `labelMedium` (header) / `labelLarge` (body) typography
          // role and any per-instance slot override in the resolver. The
          // widget only binds the state-resolved foreground colour; it is
          // render-only (no typography or `CoreColor → Color` resolution
          // here).
          final textStyle = rowKind == .header
              ? style.headerTextStyle
              : style.cellTextStyle;

          // Per-cell padding branch — header vs body / footer.
          final effectivePadding = rowKind == .header
              ? style.headerCellPadding
              : style.bodyCellPadding;

          // Row min-height — header reads `headerHeight`, body / footer
          // read `rowHeight`. `null` lets the fixed track sizing drive the
          // height (no constraint applied).
          final minRowHeight = rowKind == .header
              ? style.headerHeight
              : style.rowHeight;

          Widget content = Container(
            alignment: Alignment.centerLeft,
            padding: effectivePadding,
            decoration: BoxDecoration(
              color: background,
              border: isLastRow
                  ? null
                  : Border(
                      bottom: .new(
                        color: style.borderColor,
                        width: style.borderWidth,
                      ),
                    ),
            ),
            constraints: minRowHeight != null
                ? BoxConstraints(minHeight: minRowHeight)
                : null,
            child: DefaultTextStyle.merge(
              style: textStyle.copyWith(
                color: rowKind == .header
                    ? (cell.enabled
                          ? style.headerForegroundColor
                          : style.headerDisabledForegroundColor)
                    : (cell.enabled
                          ? style.cellForegroundColor
                          : style.cellDisabledForegroundColor),
              ),
              child: cell.child,
            ),
          );

          if (cell.onPressed != null && cell.enabled) {
            content = GestureDetector(
              onTap: cell.onPressed,
              behavior: .opaque,
              child: content,
            );
          }
          return content;
        },
      ),
    );
  }
}

/// Drag-resize overlays on right/bottom edges of each cell.
///
/// Stateful so each drag can remember its start position
/// (`globalPosition.dx/dy`). The parent state owns the snapshot of track
/// sizes captured at drag start; every `onUpdate` emits an accumulated delta
/// (current global pos − start pos) so reallocate mode always reallocates
/// against the original sizes. This keeps the drag reversible — shrunk
/// neighbours grow back when you drag the handle the other way.
class _CellResizerOverlay extends StatefulWidget {
  const _CellResizerOverlay({
    required this.column,
    required this.row,
    required this.columnSpan,
    required this.rowSpan,
    required this.totalColumns,
    required this.totalRows,
    required this.columnResizeMode,
    required this.rowResizeMode,
    required this.hoveredColumnNotifier,
    required this.hoveredRowNotifier,
    required this.draggingColumnNotifier,
    required this.draggingRowNotifier,
    required this.style,
    required this.onColumnDragStart,
    required this.onColumnDragUpdate,
    required this.onColumnDragEnd,
    required this.onRowDragStart,
    required this.onRowDragUpdate,
    required this.onRowDragEnd,
  });

  final int column;
  final int row;
  final int columnSpan;
  final int rowSpan;
  final int totalColumns;
  final int totalRows;
  final CoreTableCellResizeMode columnResizeMode;
  final CoreTableCellResizeMode rowResizeMode;
  final ValueNotifier<int?> hoveredColumnNotifier;
  final ValueNotifier<int?> hoveredRowNotifier;
  final ValueNotifier<int?> draggingColumnNotifier;
  final ValueNotifier<int?> draggingRowNotifier;
  final ResolvedTable style;
  final void Function(int totalColumns, int target) onColumnDragStart;
  final void Function(int target, double accumulatedDelta) onColumnDragUpdate;
  final void Function() onColumnDragEnd;
  final void Function(int totalRows, int target) onRowDragStart;
  final void Function(int target, double accumulatedDelta) onRowDragUpdate;
  final void Function() onRowDragEnd;

  @override
  State<_CellResizerOverlay> createState() => _CellResizerOverlayState();
}

class _CellResizerOverlayState extends State<_CellResizerOverlay> {
  double? _columnDragOriginX;
  double? _rowDragOriginY;

  int get _columnTarget => widget.column + widget.columnSpan - 1;
  int get _rowTarget => widget.row + widget.rowSpan - 1;

  /// Column resizer exists when reallocate-mode has a right neighbour to
  /// reallocate with, or when expand-mode is active (including the last
  /// column, since expanding grows the container).
  bool get _showColumn {
    if (widget.columnResizeMode == .none) return false;
    if (widget.columnResizeMode == .reallocate) {
      return _columnTarget < widget.totalColumns - 1;
    }
    return true;
  }

  bool get _showRow {
    if (widget.rowResizeMode == .none) return false;
    if (widget.rowResizeMode == .reallocate) {
      return _rowTarget < widget.totalRows - 1;
    }
    return true;
  }

  Widget _resizerVisual({required bool hovered, required bool dragging}) {
    final color = dragging
        ? widget.style.resizerDragColor
        : hovered
        ? widget.style.resizerHoverColor
        : Colors.transparent;
    return Container(color: color);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveThickness = widget.style.resizerThickness;
    final halfThickness = effectiveThickness / 2;

    return Stacks(
      clipBehavior: .none,
      children: [
        if (_showColumn)
          Position(
            top: 0,
            right: -halfThickness,
            bottom: 0,
            width: effectiveThickness,
            child: MouseRegion(
              onEnter: (_) =>
                  widget.hoveredColumnNotifier.value = _columnTarget,
              onExit: (_) {
                if (widget.hoveredColumnNotifier.value == _columnTarget) {
                  widget.hoveredColumnNotifier.value = null;
                }
              },
              cursor: SystemMouseCursors.resizeColumn,
              child: GestureDetector(
                onHorizontalDragStart: (details) {
                  _columnDragOriginX = details.globalPosition.dx;
                  widget.onColumnDragStart(
                    widget.totalColumns,
                    _columnTarget,
                  );
                },
                onHorizontalDragUpdate: (details) {
                  final origin = _columnDragOriginX;
                  if (origin == null) return;
                  final accumulated = details.globalPosition.dx - origin;
                  widget.onColumnDragUpdate(_columnTarget, accumulated);
                },
                onHorizontalDragEnd: (_) {
                  _columnDragOriginX = null;
                  widget.onColumnDragEnd();
                },
                onHorizontalDragCancel: () {
                  _columnDragOriginX = null;
                  widget.onColumnDragEnd();
                },
                behavior: .opaque,
                child: ListenableBuilder(
                  listenable: Listenable.merge([
                    widget.hoveredColumnNotifier,
                    widget.draggingColumnNotifier,
                  ]),
                  builder: (context, _) {
                    final visual = _resizerVisual(
                      hovered:
                          widget.hoveredColumnNotifier.value == _columnTarget,
                      dragging:
                          widget.draggingColumnNotifier.value == _columnTarget,
                    );
                    return visual;
                  },
                ),
              ),
            ),
          ),
        if (_showRow)
          Position(
            right: 0,
            bottom: -halfThickness,
            left: 0,
            height: effectiveThickness,
            child: MouseRegion(
              onEnter: (_) => widget.hoveredRowNotifier.value = _rowTarget,
              onExit: (_) {
                if (widget.hoveredRowNotifier.value == _rowTarget) {
                  widget.hoveredRowNotifier.value = null;
                }
              },
              cursor: SystemMouseCursors.resizeRow,
              child: GestureDetector(
                onVerticalDragStart: (details) {
                  _rowDragOriginY = details.globalPosition.dy;
                  widget.onRowDragStart(widget.totalRows, _rowTarget);
                },
                onVerticalDragUpdate: (details) {
                  final origin = _rowDragOriginY;
                  if (origin == null) return;
                  final accumulated = details.globalPosition.dy - origin;
                  widget.onRowDragUpdate(_rowTarget, accumulated);
                },
                onVerticalDragEnd: (_) {
                  _rowDragOriginY = null;
                  widget.onRowDragEnd();
                },
                onVerticalDragCancel: () {
                  _rowDragOriginY = null;
                  widget.onRowDragEnd();
                },
                behavior: .opaque,
                child: ListenableBuilder(
                  listenable: Listenable.merge([
                    widget.hoveredRowNotifier,
                    widget.draggingRowNotifier,
                  ]),
                  builder: (context, _) {
                    final visual = _resizerVisual(
                      hovered: widget.hoveredRowNotifier.value == _rowTarget,
                      dragging: widget.draggingRowNotifier.value == _rowTarget,
                    );
                    return visual;
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HoveredCell {
  const _HoveredCell({
    required this.column,
    required this.row,
    required this.columnSpan,
    required this.rowSpan,
  });

  final int column;
  final int row;
  final int columnSpan;
  final int rowSpan;

  bool intersects(
    _HoveredCell other, {
    required bool columnHover,
    required bool rowHover,
  }) {
    if (rowHover && _overlapsRow(other)) return true;
    if (columnHover && _overlapsColumn(other)) return true;
    return _equals(other);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _HoveredCell && _equals(other);

  bool _overlapsRow(_HoveredCell other) =>
      row < other.row + other.rowSpan && other.row < row + rowSpan;

  bool _overlapsColumn(_HoveredCell other) =>
      column < other.column + other.columnSpan &&
      other.column < column + columnSpan;

  bool _equals(_HoveredCell other) =>
      column == other.column &&
      row == other.row &&
      columnSpan == other.columnSpan &&
      rowSpan == other.rowSpan;

  @override
  int get hashCode => Object.hash(column, row, columnSpan, rowSpan);
}

/// Chain sugar for merging a [CoreTableStyle] patch into
/// [ResizableTable.tableStyle] without hand-reconstructing every field.
/// Mirrors the Web `ResizableTable.withStyle` extension so both
/// platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreTableStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` / `CoreColors`
/// primitive — the getter *name* is the token name, so `.radius4`
/// always means `CoreRadius.radius4` and `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreTableStyle.borderRadius] and `.primary` sets
/// [CoreTableStyle.backgroundColor]. A semantic layer that names these
/// after component-specific intent (decided together with design) is
/// a follow-up once more components adopt this pattern.
///
/// ```dart
/// ResizableTable(rows: rows, controller: controller).radius4.surface
/// ```
extension ResizableTableStyleChain on ResizableTable {
  /// Sets the border color.
  ResizableTable borderColor(CoreColor value) =>
      withStyle(CoreTableStyle(borderColor: value));

  /// Sets the border width in logical pixels.
  ResizableTable borderWidth(double value) =>
      withStyle(CoreTableStyle(borderWidth: value));

  /// Sets the content foreground color.
  ResizableTable foregroundColor(CoreColor value) =>
      withStyle(CoreTableStyle(foregroundColor: value));

  /// Sets the background paint and preserves the other style fields.
  ResizableTable backgroundColor(CoreColor value) =>
      withStyle(CoreTableStyle(backgroundColor: value));

  /// Returns a copy of this [ResizableTable] with [patch] merged into
  /// [tableStyle] (patch fields win on conflict).
  ResizableTable withStyle(CoreTableStyle patch) => copyWith(
    tableStyle: (tableStyle ?? const CoreTableStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  ResizableTable get radius0 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  ResizableTable get radius2 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  ResizableTable get radius4 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  ResizableTable get radius6 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  ResizableTable get radius8 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  ResizableTable get radius10 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  ResizableTable get radius12 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  ResizableTable get radius14 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  ResizableTable get radius16 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  ResizableTable get radius20 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  ResizableTable get radius24 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  ResizableTable get radius28 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  ResizableTable get radius32 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  ResizableTable get radius36 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  ResizableTable get radius40 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  ResizableTable get radius48 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  ResizableTable get radius56 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  ResizableTable get radius64 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  ResizableTable get radius9999 => withStyle(
    const CoreTableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  ResizableTable get primary => withStyle(
    const CoreTableStyle(backgroundColor: CoreColor.token(CoreColors.primary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  ResizableTable get secondary => withStyle(
    const CoreTableStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  ResizableTable get tertiary => withStyle(
    const CoreTableStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  ResizableTable get surface => withStyle(
    const CoreTableStyle(backgroundColor: CoreColor.token(CoreColors.surface)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  ResizableTable get surfaceContainer => withStyle(
    const CoreTableStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  ResizableTable get error => withStyle(
    const CoreTableStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  ResizableTable get success => withStyle(
    const CoreTableStyle(backgroundColor: CoreColor.token(CoreColors.success)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  ResizableTable get warning => withStyle(
    const CoreTableStyle(backgroundColor: CoreColor.token(CoreColors.warning)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  ResizableTable get info => withStyle(
    const CoreTableStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  ResizableTable get outline => withStyle(
    const CoreTableStyle(backgroundColor: CoreColor.token(CoreColors.outline)),
  );

  /// `backgroundColor: CoreColor.transparent`.
  ResizableTable get transparent => withStyle(
    const CoreTableStyle(backgroundColor: .transparent),
  );
}
