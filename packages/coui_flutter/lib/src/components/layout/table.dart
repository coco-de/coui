import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/resizer.dart';

/// Theme configuration for [Table] components.
///
/// [TableTheme] provides comprehensive styling options for table components
/// including borders, background colors, corner radius, and cell theming.
/// It integrates with the coui_flutter theming system to ensure consistent
/// table styling throughout an application.
///
/// Used with [ComponentTheme] to apply theme values throughout the widget tree.
///
/// Example:
/// ```dart
/// ComponentTheme<TableTheme>(
///   data: TableTheme(
///     border: Border.all(color: Colors.grey.shade300),
///     borderRadius: BorderRadius.circular(8.0),
///     backgroundColor: Colors.grey.shade50,
///     cellTheme: TableCellTheme(
///       padding: EdgeInsets.all(12.0),
///     ),
///   ),
///   child: MyTableWidget(),
/// );
/// ```
class TableTheme {
  /// Creates a [TableTheme].
  ///
  /// All parameters are optional and will fall back to theme defaults
  /// when not provided.
  ///
  /// Parameters:
  /// - [border] (Border?, optional): Table container border
  /// - [backgroundColor] (Color?, optional): Table background color
  /// - [borderRadius] (BorderRadiusGeometry?, optional): Corner radius
  /// - [cellTheme] (TableCellTheme?, optional): Default cell styling
  ///
  /// Example:
  /// ```dart
  /// TableTheme(
  ///   border: Border.all(color: Colors.grey),
  ///   borderRadius: BorderRadius.circular(4.0),
  ///   backgroundColor: Colors.white,
  /// );
  /// ```
  const TableTheme({
    this.backgroundColor,
    this.border,
    this.borderRadius,
    this.cellTheme,
  });

  /// Border configuration for the entire table.
  ///
  /// Type: `Border?`. Defines the outer border of the table container.
  /// If null, uses the default theme border or no border.
  final Border? border;

  /// Border radius for the table corners.
  ///
  /// Type: `BorderRadiusGeometry?`. Controls corner rounding of the table
  /// container. If null, uses the theme's default radius.
  final BorderRadiusGeometry? borderRadius;

  /// Background color for the table container.
  ///
  /// Type: `Color?`. Used as the background color behind all table content.
  /// If null, uses the theme's default background color.
  final Color? backgroundColor;

  /// Default theme for all table cells.
  ///
  /// Type: `TableCellTheme?`. Provides default styling for table cells
  /// including padding, borders, and text styles. Individual cells can
  /// override this theme.
  final TableCellTheme? cellTheme;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TableTheme &&
        other.border == border &&
        other.backgroundColor == backgroundColor &&
        other.cellTheme == cellTheme;
  }

  @override
  int get hashCode {
    return Object.hash(border, backgroundColor, cellTheme);
  }
}

class ConstrainedTableSize {
  const ConstrainedTableSize({
    this.max = double.infinity,
    this.min = double.negativeInfinity,
  });
  final double min;

  final double max;
}

/// Theme configuration for individual table cells.
///
/// [TableCellTheme] provides state-aware styling options for table cells
/// using [WidgetStateProperty] to handle different interactive states like
/// hover, selected, disabled, etc. This enables rich visual feedback for
/// table interactions.
///
/// ## State-Aware Properties
/// All properties use [WidgetStateProperty] to support different visual
/// states:
/// - [WidgetState.hovered]: Mouse hover state
/// - [WidgetState.selected]: Cell/row selection state
/// - [WidgetState.disabled]: Disabled interaction state
/// - [WidgetState.pressed]: Active press state
///
/// Example:
/// ```dart
/// TableCellTheme(
///   backgroundColor: WidgetStateProperty.resolveWith((states) {
///     if (states.contains(WidgetState.hovered)) {
///       return Colors.blue.shade50;
///     }
///     return null;
///   }),
///   textStyle: WidgetStateProperty.all(
///     TextStyle(fontWeight: FontWeight.w500),
///   ),
/// );
/// ```
class TableCellTheme {
  /// Creates a [TableCellTheme].
  ///
  /// All parameters are optional and use [WidgetStateProperty] for
  /// state-aware styling.
  ///
  /// Parameters:
  /// - [border] (WidgetStateProperty<Border?>?, optional): State-aware borders
  /// - [backgroundColor] (WidgetStateProperty<Color?>?, optional): State-aware background
  /// - [textStyle] (WidgetStateProperty<TextStyle?>?, optional): State-aware text styling
  ///
  /// Example:
  /// ```dart
  /// TableCellTheme(
  ///   border: WidgetStateProperty.all(
  ///     Border.all(color: Colors.grey.shade300),
  ///   ),
  ///   backgroundColor: WidgetStateProperty.resolveWith((states) {
  ///     return states.contains(WidgetState.selected) ? Colors.blue.shade100 : null;
  ///   }),
  /// );
  /// ```
  const TableCellTheme({this.backgroundColor, this.border, this.textStyle});

  /// State-aware border configuration for table cells.
  ///
  /// Type: `WidgetStateProperty<Border?>?`. Defines cell borders that can
  /// change based on interactive states. Useful for highlighting selected
  /// or hovered cells.
  final WidgetStateProperty<Border?>? border;

  /// State-aware background color for table cells.
  ///
  /// Type: `WidgetStateProperty<Color?>?`. Controls cell background colors
  /// that can change based on hover, selection, or other states.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// State-aware text styling for table cell content.
  ///
  /// Type: `WidgetStateProperty<TextStyle?>?`. Controls text appearance
  /// including color, weight, size that can change based on cell states.
  final WidgetStateProperty<TextStyle?>? textStyle;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TableCellTheme &&
        other.border == border &&
        other.backgroundColor == backgroundColor &&
        other.textStyle == textStyle;
  }

  @override
  int get hashCode {
    return Object.hash(border, backgroundColor, textStyle);
  }
}

class ResizableTableTheme {
  const ResizableTableTheme({
    this.resizerColor,
    this.resizerThickness,
    this.tableTheme,
  });

  final TableTheme? tableTheme;
  final double? resizerThickness;

  final Color? resizerColor;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ResizableTableTheme &&
        other.tableTheme == tableTheme &&
        other.resizerThickness == resizerThickness &&
        other.resizerColor == resizerColor;
  }

  @override
  int get hashCode {
    return Object.hash(tableTheme, resizerThickness, resizerColor);
  }
}

class _HoveredLine {
  const _HoveredLine(this.direction, this.index);

  final int index;

  final Axis direction;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is _HoveredLine &&
        other.index == index &&
        other.direction == direction;
  }

  @override
  int get hashCode {
    return Object.hash(index, direction);
  }
}

class ResizableTableController extends ChangeNotifier {
  ResizableTableController({
    Map<int, double>? columnWidths,
    required double defaultColumnWidth,
    ConstrainedTableSize? defaultHeightConstraint,
    required double defaultRowHeight,
    ConstrainedTableSize? defaultWidthConstraint,
    Map<int, ConstrainedTableSize>? heightConstraints,
    Map<int, double>? rowHeights,
    Map<int, ConstrainedTableSize>? widthConstraints,
  }) : _columnWidths = columnWidths,
       _rowHeights = rowHeights,
       _defaultColumnWidth = defaultColumnWidth,
       _defaultRowHeight = defaultRowHeight,
       _widthConstraints = widthConstraints,
       _heightConstraints = heightConstraints,
       _defaultWidthConstraint = defaultWidthConstraint,
       _defaultHeightConstraint = defaultHeightConstraint;

  Map<int, double>? _columnWidths;
  Map<int, double>? _rowHeights;
  final double _defaultColumnWidth;
  final double _defaultRowHeight;
  final ConstrainedTableSize? _defaultWidthConstraint;
  final ConstrainedTableSize? _defaultHeightConstraint;
  final Map<int, ConstrainedTableSize>? _widthConstraints;

  final Map<int, ConstrainedTableSize>? _heightConstraints;

  bool resizeColumn(int column, double width) {
    if (column < 0 || width < 0) {
      return false;
    }
    width = width.clamp(
      _widthConstraints?[column]?.min ?? _defaultWidthConstraint?.min ?? 0,
      _widthConstraints?[column]?.max ??
          _defaultWidthConstraint?.max ??
          double.infinity,
    );
    if (_columnWidths != null && _columnWidths![column] == width) {
      return false;
    }
    _columnWidths ??= {};
    _columnWidths![column] = width;
    notifyListeners();

    return true;
  }

  bool resizeRow(double height, int row) {
    if (row < 0 || height < 0) {
      return false;
    }
    height = height.clamp(
      _heightConstraints?[row]?.min ?? _defaultHeightConstraint?.min ?? 0,
      _heightConstraints?[row]?.max ??
          _defaultHeightConstraint?.max ??
          double.infinity,
    );
    if (_rowHeights != null && _rowHeights![row] == height) {
      return false;
    }
    _rowHeights ??= {};
    _rowHeights![row] = height;
    notifyListeners();

    return true;
  }

  double getColumnWidth(int index) {
    return _columnWidths?[index] ?? _defaultColumnWidth;
  }

  double getRowHeight(int index) {
    return _rowHeights?[index] ?? _defaultRowHeight;
  }

  double? getRowMinHeight(int index) {
    return _heightConstraints?[index]?.min ?? _defaultHeightConstraint?.min;
  }

  double? getRowMaxHeight(int index) {
    return _heightConstraints?[index]?.max ?? _defaultHeightConstraint?.max;
  }

  double? getColumnMinWidth(int index) {
    return _widthConstraints?[index]?.min ?? _defaultWidthConstraint?.min;
  }

  double? getColumnMaxWidth(int index) {
    return _widthConstraints?[index]?.max ?? _defaultWidthConstraint?.max;
  }

  static double _absClosestTo(double a, double b, double target) {
    final absA = (a - target).abs();
    final absB = (b - target).abs();

    return absA < absB ? a : b;
  }
}

enum TableCellResizeMode {
  /// The cell size will expand when resized
  expand,

  /// Disables resizing
  none,

  /// The cell size will expand when resized, but the other cells will shrink
  reallocate,
}

class ResizableTable extends StatefulWidget {
  const ResizableTable({
    this.cellHeightResizeMode = TableCellResizeMode.expand,
    this.cellWidthResizeMode = TableCellResizeMode.reallocate,
    this.clipBehavior = Clip.hardEdge,
    required this.controller,
    this.frozenCells,
    this.horizontalOffset,
    super.key,
    required this.rows,
    this.theme,
    this.verticalOffset,
    this.viewportSize,
  });

  final List<TableRow> rows;
  final ResizableTableController controller;
  final ResizableTableTheme? theme;
  final Clip clipBehavior;
  final TableCellResizeMode cellWidthResizeMode;
  final TableCellResizeMode cellHeightResizeMode;
  final FrozenTableData? frozenCells;
  final double? horizontalOffset;
  final double? verticalOffset;

  final Size? viewportSize;

  @override
  State<ResizableTable> createState() => _ResizableTableState();
}

class _ResizableTableState extends State<ResizableTable> {
  List<_FlattenedTableCell> _cells;
  int _maxColumn;
  int _maxRow;
  final _hoverNotifier = ValueNotifier<_HoveredLine?>(null);
  final _hoveredCellNotifier = ValueNotifier<_HoveredCell?>(null);
  final _dragNotifier = ValueNotifier<_HoveredLine?>(null);

  @override
  void initState() {
    super.initState();
    _initResizerRows();
  }

  void _initResizerRows() {
    _cells = [];
    for (int r = 0; r < widget.rows.length; r += 1) {
      final row = widget.rows[r];
      for (int c = 0; c < row.cells.length; c += 1) {
        final cell = row.cells[c];
        _cells.add(
          _FlattenedTableCell(
            builder: cell.build,
            column: c,
            columnSpan: cell.columnSpan,
            dragNotifier: _dragNotifier,
            enabled: cell.enabled,
            hoveredCellNotifier: _hoveredCellNotifier,
            row: r,
            rowSpan: cell.rowSpan,
            selected: row.selected,
            tableCellThemeBuilder: row.buildDefaultTheme,
          ),
        );
      }
    }
    _cells = _reorganizeCells(_cells);
    _maxColumn = 0;
    _maxRow = 0;
    for (final cell in _cells) {
      _maxColumn = max(_maxColumn, cell.column + cell.columnSpan - 1);
      _maxRow = max(_maxRow, cell.row + cell.rowSpan - 1);
    }
  }

  void _onHover(bool hover, int index, Axis direction) {
    if (hover) {
      _hoverNotifier.value = _HoveredLine(index, direction);
    } else if (_hoverNotifier.value?.index == index &&
        _hoverNotifier.value?.direction == direction) {
      _hoverNotifier.value = null;
    }
  }

  void _onDrag(bool drag, int index, Axis direction) {
    if (drag && _dragNotifier.value == null) {
      _dragNotifier.value = _HoveredLine(index, direction);
    } else if (!drag) {
      _dragNotifier.value = null;
    }
  }

  TableSize _width(int index) {
    return FixedTableSize(widget.controller.getColumnWidth(index));
  }

  TableSize _height(int index) {
    return FixedTableSize(widget.controller.getRowHeight(index));
  }

  @override
  void didUpdateWidget(covariant ResizableTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.rows, oldWidget.rows)) {
      _initResizerRows();
    }
  }

  @override
  Widget build(BuildContext context) {
    final resizableTableTheme =
        widget.theme ?? ComponentTheme.maybeOf<ResizableTableTheme>(context);
    final tableTheme =
        resizableTableTheme?.tableTheme ??
        ComponentTheme.maybeOf<TableTheme>(context);
    final children = _cells.map((cell) {
      return Data.inherit(
        data: cell,
        child: RawCell(
          column: cell.column,
          columnSpan: cell.columnSpan,
          row: cell.row,
          rowSpan: cell.rowSpan,
          child: Builder(
            builder: (context) {
              return cell.builder(context);
            },
          ),
        ),
      );
    }).toList();

    return Data.inherit(
      data: this,
      child: Data.inherit(
        data: _ResizableTableData(
          cellHeightResizeMode: widget.cellHeightResizeMode,
          cellWidthResizeMode: widget.cellWidthResizeMode,
          controller: widget.controller,
          maxColumn: _maxColumn,
          maxRow: _maxRow,
        ),
        child: Container(
          clipBehavior: widget.clipBehavior,
          decoration: BoxDecoration(
            border: tableTheme?.border,
            borderRadius: tableTheme?.borderRadius,
            color: tableTheme?.backgroundColor,
          ),
          child: ListenableBuilder(
            builder: (context, child) {
              return RawTableLayout(
                clipBehavior: widget.clipBehavior,
                frozenColumn: widget.frozenCells?.testColumn,
                frozenRow: widget.frozenCells?.testRow,
                height: _height,
                horizontalOffset: widget.horizontalOffset,
                verticalOffset: widget.verticalOffset,
                viewportSize: widget.viewportSize,
                width: _width,
                children: children,
              );
            },
            listenable: widget.controller,
          ),
        ),
      ),
    );
  }
}

typedef _HoverCallback = void Function(Axis direction, bool hover, int index);

class _ResizableTableData {
  const _ResizableTableData({
    required this.cellHeightResizeMode,
    required this.cellWidthResizeMode,
    required this.controller,
    required this.maxColumn,
    required this.maxRow,
  });

  final ResizableTableController controller;
  final TableCellResizeMode cellWidthResizeMode;
  final TableCellResizeMode cellHeightResizeMode;
  final int maxColumn;

  final int maxRow;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is _ResizableTableData &&
        other.cellWidthResizeMode == cellWidthResizeMode &&
        other.cellHeightResizeMode == cellHeightResizeMode &&
        other.maxColumn == maxColumn &&
        other.maxRow == maxRow;
  }

  @override
  int get hashCode {
    return Object.hash(
      cellWidthResizeMode,
      maxColumn,
      maxRow,
      cellHeightResizeMode,
    );
  }
}

class _CellResizer extends StatefulWidget {
  const _CellResizer({
    required this.controller,
    required this.dragNotifier,
    required this.hoverNotifier,
    required this.maxColumn,
    required this.maxRow,
    required this.onDrag,
    required this.onHover,
    this.theme,
  });

  final ResizableTableController controller;
  final ResizableTableTheme? theme;
  final _HoverCallback onHover;
  final _HoverCallback onDrag;
  final ValueNotifier<_HoveredLine?> hoverNotifier;
  final ValueNotifier<_HoveredLine?> dragNotifier;
  final int maxRow;

  final int maxColumn;

  @override
  State<_CellResizer> createState() => _CellResizerState();
}

class _CellResizerState extends State<_CellResizer> {
  Resizer? _resizer;
  bool? _resizeRow;

  void _onDragStartRow(DragStartDetails details) {
    final items = <ResizableItem>[];
    for (int i = 0; i <= widget.maxRow; i += 1) {
      items.add(
        ResizableItem(
          max: widget.controller.getRowMaxHeight(i) ?? double.infinity,
          min: widget.controller.getRowMinHeight(i) ?? 0,
          value: widget.controller.getRowHeight(i),
        ),
      );
    }
    _resizer = Resizer(items);
    _resizeRow = true;
    widget.onDrag(true, -1, Axis.horizontal);
  }

  void _onDragStartColumn(DragStartDetails details) {
    final items = <ResizableItem>[];
    for (int i = 0; i <= widget.maxColumn; i += 1) {
      items.add(
        ResizableItem(
          max: widget.controller.getColumnMaxWidth(i) ?? double.infinity,
          min: widget.controller.getColumnMinWidth(i) ?? 0,
          value: widget.controller.getColumnWidth(i),
        ),
      );
    }
    _resizer = Resizer(items);
    _resizeRow = false;
    widget.onDrag(true, -1, Axis.vertical);
  }

  void _onDragUpdate(DragUpdateDetails details, int end, int start) {
    // _resizer!.resize(start, end, _delta!);
    _resizer!.dragDivider(end, details.primaryDelta!);
    for (int i = 0; i < _resizer!.items.length; i += 1) {
      // widget.controller.resizeRow(i, _resizer!.items[i].newValue);
      if (_resizeRow!) {
        widget.controller.resizeRow(i, _resizer!.items[i].newValue);
      } else {
        widget.controller.resizeColumn(i, _resizer!.items[i].newValue);
      }
    }
  }

  void _onDragEnd(DragEndDetails details) {
    widget.onDrag(false, -1, Axis.horizontal);
    // _delta = null;
    _resizer = null;
    _resizeRow = null;
  }

  void _onDragCancel() {
    if (_resizer == null) {
      return;
    }
    widget.onDrag(false, -1, Axis.horizontal);
    _resizer!.reset();
    for (int i = 0; i <= widget.maxRow; i += 1) {
      if (_resizeRow ?? false) {
        widget.controller.resizeRow(i, _resizer!.items[i].value);
      } else {
        widget.controller.resizeColumn(i, _resizer!.items[i].value);
      }
    }
    _resizer = null;
    _resizeRow = null;
  }

  @override
  Widget build(BuildContext context) {
    final thickness = widget.theme?.resizerThickness ?? 4;
    final flattenedData = Data.of<_FlattenedTableCell>(context);
    final row = flattenedData.row;
    final column = flattenedData.column;
    final rowSpan = flattenedData.rowSpan;
    final columnSpan = flattenedData.columnSpan;
    final tableData = Data.of<_ResizableTableData>(context);
    final widthMode = tableData.cellWidthResizeMode;
    final heightMode = tableData.cellHeightResizeMode;
    final theme = Theme.of(context);

    return Stack(
      children: [
        // top
        if (row > 0 && heightMode != TableCellResizeMode.none)
          Positioned(
            height: thickness,
            left: 0,
            right: 0,
            top: -thickness / 2,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeRow,
              hitTestBehavior: HitTestBehavior.translucent,
              onEnter: (event) {
                widget.onHover(true, row - 1, Axis.horizontal);
              },
              onExit: (event) {
                widget.onHover(false, row - 1, Axis.horizontal);
              },
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragCancel: _onDragCancel,
                onVerticalDragEnd: _onDragEnd,
                onVerticalDragStart: _onDragStartRow,
                onVerticalDragUpdate: (details) {
                  if (heightMode == TableCellResizeMode.reallocate) {
                    _onDragUpdate(row - 1, row, details);
                  } else {
                    widget.controller.resizeRow(
                      row - 1,
                      widget.controller.getRowHeight(row - 1) +
                          details.primaryDelta!,
                    );
                  }
                },
                child: ListenableBuilder(
                  builder: (context, child) {
                    _HoveredLine? hover = widget.hoverNotifier.value;
                    final drag = widget.dragNotifier.value;
                    if (drag != null) {
                      hover = null;
                    }

                    return Container(
                      color:
                          (hover?.index == row - 1 &&
                                  hover?.direction == Axis.horizontal) ||
                              (drag?.index == row - 1 &&
                                  drag?.direction == Axis.horizontal)
                          ? widget.theme?.resizerColor ??
                                theme.colorScheme.primary
                          : null,
                    );
                  },
                  // valueListenable: widget.hoverNotifier,
                  listenable: Listenable.merge([
                    widget.hoverNotifier,
                    widget.dragNotifier,
                  ]),
                ),
              ),
            ),
          ),
        // bottom
        if ((row + rowSpan <= tableData.maxRow ||
                heightMode == TableCellResizeMode.expand) &&
            heightMode != TableCellResizeMode.none)
          Positioned(
            bottom: -thickness / 2,
            height: thickness,
            left: 0,
            right: 0,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeRow,
              hitTestBehavior: HitTestBehavior.translucent,
              onEnter: (event) {
                widget.onHover(true, row + rowSpan - 1, Axis.horizontal);
              },
              onExit: (event) {
                widget.onHover(false, row + rowSpan - 1, Axis.horizontal);
              },
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragCancel: _onDragCancel,
                onVerticalDragEnd: _onDragEnd,
                onVerticalDragStart: _onDragStartRow,
                onVerticalDragUpdate: (details) {
                  if (heightMode == TableCellResizeMode.reallocate) {
                    _onDragUpdate(row + rowSpan - 1, row + rowSpan, details);
                  } else {
                    widget.controller.resizeRow(
                      row + rowSpan - 1,
                      widget.controller.getRowHeight(row + rowSpan - 1) +
                          details.primaryDelta!,
                    );
                  }
                },
                child: ListenableBuilder(
                  builder: (context, child) {
                    _HoveredLine? hover = widget.hoverNotifier.value;
                    final drag = widget.dragNotifier.value;
                    if (drag != null) {
                      hover = null;
                    }

                    return Container(
                      color:
                          (hover?.index == row + rowSpan - 1 &&
                                  hover?.direction == Axis.horizontal) ||
                              (drag?.index == row + rowSpan - 1 &&
                                  drag?.direction == Axis.horizontal)
                          ? widget.theme?.resizerColor ??
                                theme.colorScheme.primary
                          : null,
                    );
                  },
                  listenable: Listenable.merge([
                    widget.hoverNotifier,
                    widget.dragNotifier,
                  ]),
                ),
              ),
            ),
          ),
        // left
        if (column > 0 && widthMode != TableCellResizeMode.none)
          Positioned(
            bottom: 0,
            left: -thickness / 2,
            top: 0,
            width: thickness,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              hitTestBehavior: HitTestBehavior.translucent,
              onEnter: (event) {
                widget.onHover(true, column - 1, Axis.vertical);
              },
              onExit: (event) {
                widget.onHover(false, column - 1, Axis.vertical);
              },
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragCancel: _onDragCancel,
                onHorizontalDragEnd: _onDragEnd,
                onHorizontalDragStart: _onDragStartColumn,
                onHorizontalDragUpdate: (details) {
                  if (widthMode == TableCellResizeMode.reallocate) {
                    _onDragUpdate(column - 1, column, details);
                  } else {
                    widget.controller.resizeColumn(
                      column - 1,
                      widget.controller.getColumnWidth(column - 1) +
                          details.primaryDelta!,
                    );
                  }
                },
                child: ListenableBuilder(
                  builder: (context, child) {
                    _HoveredLine? hover = widget.hoverNotifier.value;
                    final drag = widget.dragNotifier.value;
                    if (drag != null) {
                      hover = null;
                    }

                    return Container(
                      color:
                          (hover?.index == column - 1 &&
                                  hover?.direction == Axis.vertical) ||
                              (drag?.index == column - 1 &&
                                  drag?.direction == Axis.vertical)
                          ? widget.theme?.resizerColor ??
                                theme.colorScheme.primary
                          : null,
                    );
                  },
                  listenable: Listenable.merge([
                    widget.hoverNotifier,
                    widget.dragNotifier,
                  ]),
                ),
              ),
            ),
          ),
        // right
        if ((column + columnSpan <= tableData.maxColumn ||
                widthMode == TableCellResizeMode.expand) &&
            widthMode != TableCellResizeMode.none)
          Positioned(
            bottom: 0,
            right: -thickness / 2,
            top: 0,
            width: thickness,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              hitTestBehavior: HitTestBehavior.translucent,
              onEnter: (event) {
                widget.onHover(true, column + columnSpan - 1, Axis.vertical);
              },
              onExit: (event) {
                widget.onHover(false, column + columnSpan - 1, Axis.vertical);
              },
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragCancel: _onDragCancel,
                onHorizontalDragEnd: _onDragEnd,
                onHorizontalDragStart: _onDragStartColumn,
                onHorizontalDragUpdate: (details) {
                  if (widthMode == TableCellResizeMode.reallocate) {
                    _onDragUpdate(
                      column + columnSpan - 1,
                      column + columnSpan,
                      details,
                    );
                  } else {
                    widget.controller.resizeColumn(
                      column + columnSpan - 1,
                      widget.controller.getColumnWidth(
                            column + columnSpan - 1,
                          ) +
                          details.primaryDelta!,
                    );
                  }
                },
                child: ListenableBuilder(
                  builder: (context, child) {
                    _HoveredLine? hover = widget.hoverNotifier.value;
                    final drag = widget.dragNotifier.value;
                    if (drag != null) {
                      hover = null;
                    }

                    return Container(
                      color:
                          (hover?.index == column + columnSpan - 1 &&
                                  hover?.direction == Axis.vertical) ||
                              (drag?.index == column + columnSpan - 1 &&
                                  drag?.direction == Axis.vertical)
                          ? widget.theme?.resizerColor ??
                                theme.colorScheme.primary
                          : null,
                    );
                  },
                  listenable: Listenable.merge([
                    widget.hoverNotifier,
                    widget.dragNotifier,
                  ]),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

abstract class _TableCellData {
  const _TableCellData();
  int get column;
  int get row;
  int get columnSpan;
  int get rowSpan;

  _TableCellData shift(int column, int row);
}

/// This will shift cell data if there are any overlapping cells due to column or row spans.
List<T> _reorganizeCells<T extends _TableCellData>(List<T> cells) {
  int maxColumn = 0;
  int maxRow = 0;

  final cellMap = <int, Map<int, _TableCellData>>{}; // column -> row -> cell

  // find the maximum row and column
  for (final cell in cells) {
    maxColumn = max(maxColumn, cell.column + cell.columnSpan - 1);
    maxRow = max(maxRow, cell.row + cell.rowSpan - 1);
    cellMap.putIfAbsent(cell.column, () => {});
    cellMap[cell.column]![cell.row] = cell;
  }

  // shift from bottom right to top left
  for (int c = maxColumn; c >= 0; c -= 1) {
    for (int r = maxRow; r >= 0; r -= 1) {
      final cell = cellMap[c]?[r];
      if (cell != null) {
        // column span
        // shift to the right from end column to the current column + 1 (reverse)
        for (int i = maxColumn; i >= cell.column; i -= 1) {
          final rightCell = cellMap[i]?[r];
          if (rightCell != null) {
            // repeat by rowSpan
            for (int row = r; row < r + cell.rowSpan; row += 1) {
              if (i == cell.column && row == r) {
                continue;
              }
              final rightCell = cellMap[i]?[row];
              if (rightCell != null) {
                // remove the cell from the map
                cellMap[i]!.remove(row);
                // shift the cell to the right (+ columnSpan)
                if (row == r) {
                  cellMap.putIfAbsent(i + cell.columnSpan - 1, () => {});
                  cellMap[i + cell.columnSpan - 1]![row] = rightCell.shift(
                    cell.columnSpan - 1,
                    0,
                  );
                } else {
                  cellMap.putIfAbsent(i + cell.columnSpan, () => {});
                  cellMap[i + cell.columnSpan]![row] = rightCell.shift(
                    cell.columnSpan,
                    0,
                  );
                }
              }
            }
          }
        }
      }
    }
  }

  final result = <T>[];
  for (final column in cellMap.values) {
    result.addAll(column.values.cast());
  }

  return result;
}

class _HoveredCell {
  const _HoveredCell(this.column, this.columnSpan, this.row, this.rowSpan);

  final int column;
  final int row;
  final int columnSpan;

  final int rowSpan;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is _HoveredCell &&
        other.column == column &&
        other.row == row &&
        other.columnSpan == columnSpan &&
        other.rowSpan == rowSpan;
  }

  bool intersects(Axis expected, _HoveredCell other) {
    if (other == this) {
      return true;
    }

    return expected == Axis.vertical
        ? column < other.column + other.columnSpan &&
              column + columnSpan > other.column
        : row < other.row + other.rowSpan && row + rowSpan > other.row;
  }

  @override
  int get hashCode {
    return Object.hash(column, row, columnSpan, rowSpan);
  }
}

class TableCell {
  const TableCell({
    this.backgroundColor,
    required this.child,
    this.columnHover = false,
    this.columnSpan = 1,
    this.enabled = true,
    this.rowHover = true,
    this.rowSpan = 1,
    this.theme,
  });

  final int columnSpan;
  final int rowSpan;
  final Widget child;
  final bool columnHover;
  final bool rowHover;
  final Color? backgroundColor;
  final TableCellTheme? theme;

  final bool enabled;

  Widget build(BuildContext context) {
    final flattenedData = Data.of<_FlattenedTableCell>(context);
    final resizedData = Data.maybeOf<_ResizableTableData>(context);
    final resizedState = Data.maybeOf<_ResizableTableState>(context);
    final currentCell = _HoveredCell(
      flattenedData.column,
      flattenedData.row,
      flattenedData.columnSpan,
      flattenedData.rowSpan,
    );
    final theme = this.theme;
    final defaultTheme = flattenedData.tableCellThemeBuilder(context);
    final appTheme = Theme.of(context);

    return Stack(
      fit: StackFit.passthrough,
      children: [
        ColoredBox(
          color: backgroundColor ?? appTheme.colorScheme.background,
          child: MouseRegion(
            onEnter: (event) {
              if (flattenedData.enabled) {
                flattenedData.hoveredCellNotifier.value = currentCell;
              }
            },
            onExit: (event) {
              if (flattenedData.enabled &&
                  flattenedData.hoveredCellNotifier.value == currentCell) {
                flattenedData.hoveredCellNotifier.value = null;
              }
            },
            child: ListenableBuilder(
              builder: (context, child) {
                _HoveredCell? hoveredCell =
                    flattenedData.hoveredCellNotifier.value;
                final drag = flattenedData.dragNotifier?.value;
                if (drag != null) {
                  hoveredCell = null;
                }
                final resolvedStates = {
                  if (hoveredCell != null &&
                      ((columnHover &&
                              hoveredCell.intersects(
                                currentCell,
                                Axis.vertical,
                              )) ||
                          (rowHover &&
                              hoveredCell.intersects(
                                currentCell,
                                Axis.horizontal,
                              ))))
                    WidgetState.hovered,
                  if (flattenedData.selected) WidgetState.selected,
                  if (!flattenedData.enabled) WidgetState.disabled,
                };

                return Container(
                  decoration: BoxDecoration(
                    border:
                        theme?.border?.resolve(resolvedStates) ??
                        defaultTheme.border?.resolve(resolvedStates),
                    color:
                        theme?.backgroundColor?.resolve(resolvedStates) ??
                        defaultTheme.backgroundColor?.resolve(resolvedStates),
                  ),
                  child: DefaultTextStyle.merge(
                    style:
                        theme?.textStyle?.resolve(resolvedStates) ??
                        defaultTheme.textStyle?.resolve(resolvedStates),
                    child: child!,
                  ),
                );
              },
              // valueListenable: flattenedData.hoveredCellNotifier,
              listenable: Listenable.merge([
                flattenedData.hoveredCellNotifier,
                flattenedData.dragNotifier,
              ]),
              child: child,
            ),
          ),
        ),
        if (resizedData != null && resizedState != null)
          Positioned.fill(
            child: _CellResizer(
              controller: resizedData.controller,
              dragNotifier: resizedState._dragNotifier,
              hoverNotifier: resizedState._hoverNotifier,
              maxColumn: resizedState._maxColumn,
              maxRow: resizedState._maxRow,
              onDrag: resizedState._onDrag,
              onHover: resizedState._onHover,
              theme: resizedState.widget.theme,
            ),
          ),
      ],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TableCell &&
        other.columnSpan == columnSpan &&
        other.rowSpan == rowSpan &&
        other.child == child &&
        other.theme == theme &&
        other.enabled == enabled &&
        other.columnHover == columnHover &&
        other.rowHover == rowHover &&
        other.backgroundColor == backgroundColor;
  }

  @override
  int get hashCode {
    return Object.hash(
      columnSpan,
      rowSpan,
      child,
      theme,
      enabled,
      columnHover,
      rowHover,
      backgroundColor,
    );
  }
}

typedef TableCellThemeBuilder = TableCellTheme Function(BuildContext context);

class TableRow {
  const TableRow({this.cellTheme, required this.cells, this.selected = false});

  final List<TableCell> cells;
  final TableCellTheme? cellTheme;

  final bool selected;

  TableCellTheme buildDefaultTheme(BuildContext context) {
    if (cellTheme != null) {
      return cellTheme!;
    }
    final theme = Theme.of(context);

    return TableCellTheme(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.hovered)
            ? theme.colorScheme.muted.withValues(alpha: 0.5)
            : null;
      }),
      border: WidgetStateProperty.resolveWith((states) {
        return Border(
          bottom: BorderSide(color: theme.colorScheme.border),
        );
      }),
      textStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          color: states.contains(WidgetState.disabled)
              ? theme.colorScheme.muted
              : null,
        );
      }),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TableRow &&
        listEquals(other.cells, cells) &&
        other.cellTheme == cellTheme &&
        other.selected == selected;
  }

  @override
  int get hashCode {
    return Object.hash(cells, cellTheme, selected);
  }
}

class TableFooter extends TableRow {
  const TableFooter({super.cellTheme, required super.cells});

  @override
  TableCellTheme buildDefaultTheme(BuildContext context) {
    if (cellTheme != null) {
      return cellTheme!;
    }
    final theme = Theme.of(context);

    return TableCellTheme(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.hovered)
            ? theme.colorScheme.muted
            : theme.colorScheme.muted.withValues(alpha: 0.5);
      }),
      border: const WidgetStatePropertyAll(null),
      textStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          color: states.contains(WidgetState.disabled)
              ? theme.colorScheme.muted
              : null,
        );
      }),
    );
  }
}

class TableHeader extends TableRow {
  const TableHeader({TableCellTheme? cellTheme, required List<TableCell> cells})
    : super(cells: cells, cellTheme: cellTheme);

  @override
  TableCellTheme buildDefaultTheme(BuildContext context) {
    if (cellTheme != null) {
      return cellTheme!;
    }
    final theme = Theme.of(context);

    return TableCellTheme(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.hovered)
            ? theme.colorScheme.muted
            : theme.colorScheme.muted.withValues(alpha: 0.5);
      }),
      border: WidgetStateProperty.resolveWith((states) {
        return Border(
          bottom: BorderSide(color: theme.colorScheme.border),
        );
      }),
      textStyle: WidgetStateProperty.resolveWith((states) {
        return theme.typography.semiBold.merge(
          TextStyle(
            color: states.contains(WidgetState.disabled)
                ? theme.colorScheme.muted
                : null,
          ),
        );
      }),
    );
  }
}

class _FlattenedTableCell extends _TableCellData {
  const _FlattenedTableCell({
    required this.builder,
    required this.column,
    required this.columnSpan,
    required this.dragNotifier,
    required this.enabled,
    required this.hoveredCellNotifier,
    required this.row,
    required this.rowSpan,
    required this.selected,
    required this.tableCellThemeBuilder,
  });

  @override
  final int column;
  @override
  final int row;
  @override
  final int columnSpan;
  @override
  final int rowSpan;
  final WidgetBuilder builder;
  final bool enabled;
  final ValueNotifier<_HoveredCell?> hoveredCellNotifier;
  final ValueNotifier<_HoveredLine?>? dragNotifier;
  final TableCellThemeBuilder tableCellThemeBuilder;

  final bool selected;

  @override
  _TableCellData shift(int column, int row) {
    return _FlattenedTableCell(
      builder: builder,
      column: this.column + column,
      columnSpan: columnSpan,
      dragNotifier: dragNotifier,
      enabled: enabled,
      hoveredCellNotifier: hoveredCellNotifier,
      row: this.row + row,
      rowSpan: rowSpan,
      selected: selected,
      tableCellThemeBuilder: tableCellThemeBuilder,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is _FlattenedTableCell &&
        other.column == column &&
        other.row == row &&
        other.columnSpan == columnSpan &&
        other.rowSpan == rowSpan &&
        other.builder == builder &&
        other.enabled == enabled &&
        other.hoveredCellNotifier == hoveredCellNotifier &&
        other.dragNotifier == dragNotifier &&
        other.tableCellThemeBuilder == tableCellThemeBuilder &&
        other.selected == selected;
  }

  @override
  int get hashCode {
    return Object.hash(
      column,
      row,
      columnSpan,
      rowSpan,
      builder,
      enabled,
      hoveredCellNotifier,
      dragNotifier,
      tableCellThemeBuilder,
      selected,
    );
  }
}

/// A flexible table widget with support for spanning, scrolling, and interactive features.
///
/// [Table] provides a comprehensive table component with advanced layout capabilities
/// including cell spanning, flexible sizing, frozen cells, scrolling, and rich theming.
/// It supports both simple data tables and complex layouts with header/footer rows.
///
/// ## Key Features
/// - **Cell Spanning**: Support for colspan and rowspan across multiple cells
/// - **Flexible Sizing**: Multiple sizing strategies (fixed, flex, intrinsic) for columns/rows
/// - **Frozen Cells**: Ability to freeze specific cells during scrolling
/// - **Interactive States**: Hover effects and selection states with visual feedback
/// - **Scrolling**: Optional horizontal and vertical scrolling with viewport control
/// - **Theming**: Comprehensive theming system for visual customization
///
/// ## Layout System
/// The table uses a sophisticated layout system that handles:
/// - Variable column widths via [TableSize] strategies
/// - Dynamic row heights based on content
/// - Complex cell spanning calculations
/// - Efficient rendering with viewport culling
///
/// ## Sizing Strategies
/// - [FlexTableSize]: Proportional sizing like CSS flex
/// - [FixedTableSize]: Absolute pixel sizes
/// - [IntrinsicTableSize]: Size based on content
///
/// Example:
/// ```dart
/// Table(
///   rows: [
///     TableHeader(cells: [
///       TableCell(child: Text('Name')),
///       TableCell(child: Text('Age')),
///       TableCell(child: Text('City')),
///     ]),
///     TableRow(cells: [
///       TableCell(child: Text('John Doe')),
///       TableCell(child: Text('25')),
///       TableCell(child: Text('New York')),
///     ]),
///   ],
///   columnWidths: {
///     0: FlexTableSize(flex: 2),
///     1: FixedTableSize(width: 80),
///     2: FlexTableSize(flex: 1),
///   },
/// );
/// ```
class Table extends StatefulWidget {
  /// Creates a [Table] widget.
  ///
  /// The table displays data organized in rows and cells with flexible
  /// sizing and interactive features.
  ///
  /// Parameters:
  /// - [rows] (List<TableRow>, required): Table data organized as rows
  /// - [defaultColumnWidth] (TableSize, default: FlexTableSize()): Default column sizing
  /// - [defaultRowHeight] (TableSize, default: IntrinsicTableSize()): Default row sizing
  /// - [columnWidths] (Map<int, TableSize>?, optional): Column-specific sizes
  /// - [rowHeights] (Map<int, TableSize>?, optional): Row-specific sizes
  /// - [clipBehavior] (Clip, default: Clip.hardEdge): Content clipping behavior
  /// - [theme] (TableTheme?, optional): Visual styling configuration
  /// - [frozenCells] (FrozenTableData?, optional): Frozen cell configuration
  /// - [horizontalOffset] (double?, optional): Horizontal scroll position
  /// - [verticalOffset] (double?, optional): Vertical scroll position
  /// - [viewportSize] (Size?, optional): Viewport size constraints
  ///
  /// Example:
  /// ```dart
  /// Table(
  ///   rows: [
  ///     TableHeader(cells: [TableCell(child: Text('Header'))]),
  ///     TableRow(cells: [TableCell(child: Text('Data'))]),
  ///   ],
  ///   columnWidths: {0: FixedTableSize(width: 200)},
  /// );
  /// ```
  const Table({
    this.clipBehavior = Clip.hardEdge,
    this.columnWidths,
    this.defaultColumnWidth = const FlexTableSize(),
    this.defaultRowHeight = const IntrinsicTableSize(),
    this.frozenCells,
    this.horizontalOffset,
    super.key,
    this.rowHeights,
    required this.rows,
    this.theme,
    this.verticalOffset,
    this.viewportSize,
  });

  /// List of rows to display in the table.
  ///
  /// Type: `List<TableRow>`. Contains the table data organized as rows.
  /// Can include [TableRow], [TableHeader], and [TableFooter] instances.
  /// Each row contains a list of [TableCell] widgets.
  final List<TableRow> rows;

  /// Default sizing strategy for all columns.
  ///
  /// Type: `TableSize`. Used when no specific width is provided in
  /// [columnWidths]. Defaults to [FlexTableSize] for proportional sizing.
  final TableSize defaultColumnWidth;

  /// Default sizing strategy for all rows.
  ///
  /// Type: `TableSize`. Used when no specific height is provided in
  /// [rowHeights]. Defaults to [IntrinsicTableSize] for content-based sizing.
  final TableSize defaultRowHeight;

  /// Specific column width overrides.
  ///
  /// Type: `Map<int, TableSize>?`. Maps column indices to specific sizing
  /// strategies. Overrides [defaultColumnWidth] for specified columns.
  final Map<int, TableSize>? columnWidths;

  /// Specific row height overrides.
  ///
  /// Type: `Map<int, TableSize>?`. Maps row indices to specific sizing
  /// strategies. Overrides [defaultRowHeight] for specified rows.
  final Map<int, TableSize>? rowHeights;

  /// Clipping behavior for the table content.
  ///
  /// Type: `Clip`. Controls how content is clipped at table boundaries.
  /// Defaults to [Clip.hardEdge] for clean boundaries.
  final Clip clipBehavior;

  /// Theme configuration for the table appearance.
  ///
  /// Type: `TableTheme?`. Controls borders, colors, and overall styling.
  /// If null, uses the default theme from [ComponentTheme].
  final TableTheme? theme;

  /// Configuration for frozen cells during scrolling.
  ///
  /// Type: `FrozenTableData?`. Specifies which cells remain visible
  /// during horizontal or vertical scrolling. Useful for headers/footers.
  final FrozenTableData? frozenCells;

  /// Horizontal scroll offset for the table viewport.
  ///
  /// Type: `double?`. Controls horizontal scrolling position. If provided,
  /// the table displays within a scrollable viewport.
  final double? horizontalOffset;

  /// Vertical scroll offset for the table viewport.
  ///
  /// Type: `double?`. Controls vertical scrolling position. If provided,
  /// the table displays within a scrollable viewport.
  final double? verticalOffset;

  /// Size constraints for the table viewport.
  ///
  /// Type: `Size?`. When provided with scroll offsets, constrains the
  /// visible area of the table. Essential for scrolling behavior.
  final Size? viewportSize;

  @override
  State<Table> createState() => _TableState();
}

class _TableState extends State<Table> {
  List<_FlattenedTableCell> _cells;
  final _hoveredCellNotifier = ValueNotifier<_HoveredCell?>(null);

  @override
  void initState() {
    super.initState();
    _initCells();
  }

  void _initCells() {
    _cells = [];
    for (int r = 0; r < widget.rows.length; r += 1) {
      final row = widget.rows[r];
      for (int c = 0; c < row.cells.length; c += 1) {
        final cell = row.cells[c];
        _cells.add(
          _FlattenedTableCell(
            builder: cell.build,
            column: c,
            columnSpan: cell.columnSpan,
            dragNotifier: null,
            enabled: cell.enabled,
            hoveredCellNotifier: _hoveredCellNotifier,
            row: r,
            rowSpan: cell.rowSpan,
            selected: row.selected,
            tableCellThemeBuilder: row.buildDefaultTheme,
          ),
        );
      }
    }
    _cells = _reorganizeCells(_cells);
  }

  @override
  void didUpdateWidget(covariant Table oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.rows, oldWidget.rows)) {
      _initCells();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tableTheme =
        widget.theme ?? ComponentTheme.maybeOf<TableTheme>(context);

    return Container(
      clipBehavior: widget.clipBehavior,
      decoration: BoxDecoration(
        border: tableTheme?.border,
        borderRadius: tableTheme?.borderRadius,
        color: tableTheme?.backgroundColor,
      ),
      child: RawTableLayout(
        clipBehavior: widget.clipBehavior,
        frozenColumn: widget.frozenCells?.testColumn,
        frozenRow: widget.frozenCells?.testRow,
        height: (index) {
          return widget.rowHeights != null
              ? widget.rowHeights![index] ?? widget.defaultRowHeight
              : widget.defaultRowHeight;
        },
        horizontalOffset: widget.horizontalOffset,
        verticalOffset: widget.verticalOffset,
        viewportSize: widget.viewportSize,
        width: (index) {
          return widget.columnWidths != null
              ? widget.columnWidths![index] ?? widget.defaultColumnWidth
              : widget.defaultColumnWidth;
        },
        children: _cells.map((cell) {
          return Data.inherit(
            data: cell,
            child: RawCell(
              column: cell.column,
              columnSpan: cell.columnSpan,
              row: cell.row,
              rowSpan: cell.rowSpan,
              child: Builder(
                builder: (context) {
                  return cell.builder(context);
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class TableRef {
  const TableRef(this.index, [this.span = 1]);

  final int index;

  final int span;

  bool test(int index, int span) {
    return this.index <= index && this.index + this.span > index;
  }
}

class FrozenTableData {
  const FrozenTableData({
    this.frozenColumns = const [],
    this.frozenRows = const [],
  });

  final Iterable<TableRef> frozenRows;

  final Iterable<TableRef> frozenColumns;

  bool testRow(int index, int span) {
    for (final ref in frozenRows) {
      if (ref.test(index, span)) {
        return true;
      }
    }

    return false;
  }

  bool testColumn(int index, int span) {
    for (final ref in frozenColumns) {
      if (ref.test(index, span)) {
        return true;
      }
    }

    return false;
  }
}

class TableParentData extends ContainerBoxParentData<RenderBox> {
  int? column;
  int? row;
  int? columnSpan;
  int? rowSpan;
  bool computeSize = true;
  bool frozenRow = false;
  bool frozenColumn = false;
}

class RawCell extends ParentDataWidget<TableParentData> {
  const RawCell({
    required super.child,
    required this.column,
    this.columnSpan,
    this.computeSize = true,
    super.key,
    required this.row,
    this.rowSpan,
  });

  final int column;
  final int row;
  final int? columnSpan;
  final int? rowSpan;

  final bool computeSize;

  @override
  void applyParentData(RenderObject renderObject) {
    final parentData = renderObject.parentData! as TableParentData;
    bool needsLayout = false;
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
      final table = renderObject.parent! as RenderTableLayout;
      table.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => RawTableLayout;
}

abstract class TableSize {
  const TableSize();
}

class FlexTableSize extends TableSize {
  const FlexTableSize({this.fit = FlexFit.tight, this.flex = 1});
  final double flex;
  final FlexFit fit;
}

class FixedTableSize extends TableSize {
  const FixedTableSize(this.value);
  final double value;
}

class IntrinsicTableSize extends TableSize {
  const IntrinsicTableSize();
}

typedef CellPredicate = bool Function(int index, int span);

class RawTableLayout extends MultiChildRenderObjectWidget {
  const RawTableLayout({
    super.children,
    required this.clipBehavior,
    this.frozenColumn,
    this.frozenRow,
    required this.height,
    this.horizontalOffset,
    super.key,
    this.verticalOffset,
    this.viewportSize,
    required this.width,
  });

  final TableSizeSupplier width;
  final TableSizeSupplier height;
  final Clip clipBehavior;
  final CellPredicate? frozenColumn;
  final CellPredicate? frozenRow;
  final double? verticalOffset;
  final double? horizontalOffset;
  final Size? viewportSize;

  @override
  RenderTableLayout createRenderObject(BuildContext context) {
    return RenderTableLayout(
      clipBehavior: clipBehavior,
      frozenCell: frozenColumn,
      frozenRow: frozenRow,
      height: height,
      horizontalOffset: horizontalOffset,
      verticalOffset: verticalOffset,
      viewportSize: viewportSize,
      width: width,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderTableLayout renderObject,
  ) {
    bool needsRelayout = false;
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
    if (renderObject._verticalOffset != verticalOffset) {
      renderObject._verticalOffset = verticalOffset;
      needsRelayout = true;
    }
    if (renderObject._horizontalOffset != horizontalOffset) {
      renderObject._horizontalOffset = horizontalOffset;
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

typedef TableSizeSupplier = TableSize Function(int index);

class RenderTableLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, TableParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, TableParentData> {
  RenderTableLayout({
    List<RenderBox>? children,
    required Clip clipBehavior,
    CellPredicate? frozenCell,
    CellPredicate? frozenRow,
    required TableSizeSupplier height,
    double? horizontalOffset,
    double? verticalOffset,
    Size? viewportSize,
    required TableSizeSupplier width,
  }) : _clipBehavior = clipBehavior,
       _width = width,
       _height = height,
       _frozenColumn = frozenCell,
       _frozenRow = frozenRow,
       _verticalOffset = verticalOffset,
       _horizontalOffset = horizontalOffset,
       _viewportSize = viewportSize {
    addAll(children);
  }
  TableSizeSupplier _width;
  TableSizeSupplier _height;
  Clip _clipBehavior;
  CellPredicate? _frozenColumn;
  CellPredicate? _frozenRow;
  double? _verticalOffset;
  double? _horizontalOffset;

  Size? _viewportSize;

  TableLayoutResult? _layoutResult;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! TableParentData) {
      child.parentData = TableParentData();
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    RenderBox? child = firstChild;
    while (child != null) {
      final parentData = child.parentData! as TableParentData;
      final hit = result.addWithPaintOffset(
        hitTest: (BoxHitTestResult result, Offset transformed) {
          return child!.hitTest(result, position: transformed);
        },
        offset: parentData.offset,
        position: position,
      );
      if (hit) {
        return true;
      }
      child = childAfter(child);
    }

    return false;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return computeTableSize(
      BoxConstraints.loose(Size(double.infinity, height)),
      (child, extent) {
        return child.getMinIntrinsicWidth(extent);
      },
    ).width;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return computeTableSize(constraints).size;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // reverse paint traversal so that the first child is painted last
    // important for column and row spans
    // (ASSUMPTION: children are already sorted in the correct order)
    if (_clipBehavior != Clip.none) {
      context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        (context, offset) {
          RenderBox? child = lastChild;
          while (child != null) {
            final parentData = child.parentData! as TableParentData;
            if (parentData.computeSize &&
                !parentData.frozenRow &&
                !parentData.frozenColumn) {
              context.paintChild(child, offset + parentData.offset);
            }
            child = childBefore(child);
          }
        },
        clipBehavior: _clipBehavior,
      );
      RenderBox? child = lastChild;
      while (child != null) {
        final parentData = child.parentData! as TableParentData;
        if (!parentData.computeSize &&
            !parentData.frozenRow &&
            !parentData.frozenColumn) {
          context.paintChild(child, offset + parentData.offset);
        }
        child = childBefore(child);
      }
      context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        (context, offset) {
          RenderBox? child = lastChild;
          while (child != null) {
            final parentData = child.parentData! as TableParentData;
            if (parentData.frozenColumn) {
              context.paintChild(child, offset + parentData.offset);
            }
            child = childBefore(child);
          }
        },
        clipBehavior: _clipBehavior,
      );
      context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        (context, offset) {
          RenderBox? child = lastChild;
          while (child != null) {
            final parentData = child.parentData! as TableParentData;
            if (parentData.frozenRow) {
              context.paintChild(child, offset + parentData.offset);
            }
            child = childBefore(child);
          }
        },
        clipBehavior: _clipBehavior,
      );
      child = lastChild;
      while (child != null) {
        final parentData = child.parentData! as TableParentData;
        if (!parentData.computeSize && (parentData.frozenColumn)) {
          context.paintChild(child, offset + parentData.offset);
        }
        child = childBefore(child);
      }
      child = lastChild;
      while (child != null) {
        final parentData = child.parentData! as TableParentData;
        if (!parentData.computeSize && (parentData.frozenRow)) {
          context.paintChild(child, offset + parentData.offset);
        }
        child = childBefore(child);
      }

      return;
    }
    RenderBox? child = lastChild;
    while (child != null) {
      final parentData = child.parentData! as TableParentData;
      if (!parentData.frozenRow && !parentData.frozenColumn) {
        context.paintChild(child, offset + parentData.offset);
      }
      child = childBefore(child);
    }
    child = lastChild;
    while (child != null) {
      final parentData = child.parentData! as TableParentData;
      if (parentData.frozenColumn) {
        context.paintChild(child, offset + parentData.offset);
      }
      child = childBefore(child);
    }
    child = lastChild;
    while (child != null) {
      final parentData = child.parentData! as TableParentData;
      if (parentData.frozenRow) {
        context.paintChild(child, offset + parentData.offset);
      }
      child = childBefore(child);
    }
  }

  @override
  void performLayout() {
    final result = computeTableSize(constraints);
    size = constraints.constrain(result.size);

    final frozenRows = <int, double>{};
    final frozenColumns = <int, double>{};

    RenderBox? child = firstChild;
    while (child != null) {
      final parentData = child.parentData! as TableParentData;
      final column = parentData.column;
      final row = parentData.row;
      if (column != null && row != null) {
        double width = 0;
        double height = 0;
        final columnSpan = parentData.columnSpan ?? 1;
        final rowSpan = parentData.rowSpan ?? 1;
        final frozenRow = _frozenRow?.call(row, rowSpan) ?? false;
        final frozenColumn = _frozenColumn?.call(column, columnSpan) ?? false;
        for (
          int i = 0;
          i < columnSpan && column + i < result.columnWidths.length;
          i += 1
        ) {
          width += result.columnWidths[column + i];
        }
        for (
          int i = 0;
          i < rowSpan && row + i < result.rowHeights.length;
          i += 1
        ) {
          height += result.rowHeights[row + i];
        }
        child.layout(BoxConstraints.tightFor(height: height, width: width));
        final offset = result.getOffset(column, row);
        double offsetX = offset.dx;
        double offsetY = offset.dy;
        if (frozenRow) {
          double verticalOffset = _verticalOffset ?? 0;
          verticalOffset = max(0, verticalOffset);
          if (_viewportSize != null) {
            final maxVerticalOffset = size.height - _viewportSize!.height;
            verticalOffset = min(verticalOffset, maxVerticalOffset);
          }
          final offsetInViewport = offsetY - verticalOffset;
          // make sure its visible on the viewport
          double minViewport = 0;
          final maxViewport = constraints.minHeight;
          for (int i = 0; i < row; i += 1) {
            final rowHeight = frozenRows[i] ?? 0;
            minViewport += rowHeight;
          }
          double verticalAdjustment = 0;
          if (offsetInViewport < minViewport) {
            verticalAdjustment = -offsetInViewport + minViewport;
          } else if (offsetInViewport + height > maxViewport) {
            verticalAdjustment = maxViewport - offsetInViewport - height;
          }
          frozenRows[row] = max(frozenRows[row] ?? 0, height);
          offsetY += verticalAdjustment;
        }
        if (frozenColumn) {
          double horizontalOffset = _horizontalOffset ?? 0;
          horizontalOffset = max(0, horizontalOffset);
          if (_viewportSize != null) {
            final maxHorizontalOffset = size.width - _viewportSize!.width;
            horizontalOffset = min(horizontalOffset, maxHorizontalOffset);
          }
          final offsetInViewport = offsetX - horizontalOffset;
          // make sure its visible on the viewport
          double minViewport = 0;
          final maxViewport = constraints.minWidth;
          for (int i = 0; i < column; i += 1) {
            final columnWidth = frozenColumns[i] ?? 0;
            minViewport += columnWidth;
          }
          double horizontalAdjustment = 0;
          if (offsetInViewport < minViewport) {
            horizontalAdjustment = -offsetInViewport + minViewport;
          } else if (offsetInViewport + width > maxViewport) {
            horizontalAdjustment = maxViewport - offsetInViewport - width;
          }
          frozenColumns[column] = max(frozenColumns[column] ?? 0, width);
          offsetX += horizontalAdjustment;
        }
        parentData.frozenRow = frozenRow;
        parentData.frozenColumn = frozenColumn;
        parentData.offset = Offset(offsetX, offsetY);
        child = childAfter(child);
      }
    }

    _layoutResult = result;
  }

  TableLayoutResult computeTableSize(
    BoxConstraints constraints, [
    IntrinsicComputer? intrinsicComputer,
  ]) {
    double flexWidth = 0;
    double flexHeight = 0;
    double fixedWidth = 0;
    double fixedHeight = 0;

    final columnWidths = <int, double>{};
    final rowHeights = <int, double>{};

    int maxRow = 0;
    int maxColumn = 0;

    bool hasTightFlexWidth = false;
    bool hasTightFlexHeight = false;

    RenderBox? child = firstChild;
    while (child != null) {
      final parentData = child.parentData! as TableParentData;
      if (parentData.computeSize) {
        final column = parentData.column;
        final row = parentData.row;
        if (column != null && row != null) {
          final columnSpan = parentData.columnSpan ?? 1;
          final rowSpan = parentData.rowSpan ?? 1;
          maxColumn = max(maxColumn, column + columnSpan - 1);
          maxRow = max(maxRow, row + rowSpan - 1);
        }
      }
      child = childAfter(child);
    }

    bool hasFlexWidth = false;
    bool hasFlexHeight = false;

    // row
    for (int r = 0; r <= maxRow; r += 1) {
      final heightConstraint = _height(r);
      if (heightConstraint is FlexTableSize &&
          constraints.hasBoundedHeight &&
          intrinsicComputer == null) {
        flexHeight += heightConstraint.flex;
        hasFlexHeight = true;
        if (heightConstraint.fit == FlexFit.tight) {
          hasTightFlexHeight = true;
        }
      } else if (heightConstraint is FixedTableSize) {
        fixedHeight += heightConstraint.value;
        rowHeights[r] = max(rowHeights[r] ?? 0, heightConstraint.value);
      }
    }
    // column
    for (int c = 0; c <= maxColumn; c += 1) {
      final widthConstraint = _width(c);
      if (widthConstraint is FlexTableSize && constraints.hasBoundedWidth) {
        flexWidth += widthConstraint.flex;
        hasFlexWidth = true;
        if (widthConstraint.fit == FlexFit.tight) {
          hasTightFlexWidth = true;
        }
      } else if (widthConstraint is FixedTableSize) {
        fixedWidth += widthConstraint.value;
        columnWidths[c] = max(columnWidths[c] ?? 0, widthConstraint.value);
      }
    }

    double spacePerFlexWidth = 0;
    double spacePerFlexHeight = 0;
    double remainingWidth;
    double remainingHeight;
    remainingWidth = constraints.hasBoundedWidth
        ? constraints.maxWidth - fixedWidth
        : double.infinity;
    remainingHeight = constraints.hasBoundedHeight
        ? constraints.maxHeight - fixedHeight
        : double.infinity; // find the proper intrinsic sizes (if any)
    child = lastChild;
    while (child != null) {
      final parentData = child.parentData! as TableParentData;
      if (parentData.computeSize) {
        final column = parentData.column;
        final row = parentData.row;
        if (column != null && row != null) {
          final widthConstraint = _width(column);
          final heightConstraint = _height(row);
          if (widthConstraint is IntrinsicTableSize ||
              (widthConstraint is FlexTableSize && intrinsicComputer != null)) {
            final extent = rowHeights[row] ?? remainingHeight;
            double maxIntrinsicWidth = intrinsicComputer == null
                ? child.getMaxIntrinsicWidth(extent)
                : intrinsicComputer(child, extent);
            maxIntrinsicWidth = min(maxIntrinsicWidth, remainingWidth);
            final columnSpan = parentData.columnSpan ?? 1;
            // distribute the intrinsic width to all columns
            maxIntrinsicWidth /= columnSpan;
            for (int i = 0; i < columnSpan; i += 1) {
              columnWidths[column + i] = max(
                columnWidths[column + i] ?? 0,
                maxIntrinsicWidth,
              );
            }
          }
          if (heightConstraint is IntrinsicTableSize ||
              (heightConstraint is FlexTableSize &&
                  intrinsicComputer != null)) {
            final extent = columnWidths[column] ?? remainingWidth;
            double maxIntrinsicHeight = intrinsicComputer == null
                ? child.getMaxIntrinsicHeight(extent)
                : intrinsicComputer(child, extent);
            maxIntrinsicHeight = min(maxIntrinsicHeight, remainingHeight);
            final rowSpan = parentData.rowSpan ?? 1;
            // distribute the intrinsic height to all rows
            maxIntrinsicHeight /= rowSpan;
            for (int i = 0; i < rowSpan; i += 1) {
              rowHeights[row + i] = max(
                columnWidths[row + i] ?? 0,
                maxIntrinsicHeight,
              );
            }
          }
        }
      }
      child = childBefore(child);
    }

    final usedColumnWidth = columnWidths.values.fold(0, (a, b) => a + b);
    final usedRowHeight = rowHeights.values.fold(0, (a, b) => a + b);
    double looseRemainingWidth = remainingWidth;
    double looseRemainingHeight = remainingHeight;
    double looseSpacePerFlexWidth = 0;
    const looseSpacePerFlexHeight = 0;

    if (intrinsicComputer == null) {
      remainingWidth = constraints.hasBoundedWidth
          ? constraints.maxWidth - usedColumnWidth
          : double.infinity;
      looseRemainingWidth = constraints.hasInfiniteWidth
          ? double.infinity
          : max(0, constraints.minWidth - usedColumnWidth);
      remainingHeight = constraints.hasBoundedHeight
          ? constraints.maxHeight - usedRowHeight
          : double.infinity;
      looseRemainingHeight = constraints.hasInfiniteHeight
          ? double.infinity
          : max(0, constraints.minHeight - usedRowHeight);
      spacePerFlexWidth = flexWidth > 0 && remainingWidth > 0
          ? remainingWidth / flexWidth
          : 0;
      if (flexWidth > 0 && looseRemainingWidth > 0) {
        looseSpacePerFlexWidth = looseRemainingWidth / flexWidth;
      }
      spacePerFlexHeight = flexHeight > 0 && remainingHeight > 0
          ? remainingHeight / flexHeight
          : 0;
      if (flexHeight > 0 && looseRemainingHeight > 0) {
        spacePerFlexHeight = looseRemainingHeight / flexHeight;
      }

      // calculate space used for flexes
      if (hasFlexWidth) {
        for (int c = 0; c <= maxColumn; c += 1) {
          final widthConstraint = _width(c);
          if (widthConstraint is FlexTableSize) {
            if (widthConstraint.fit == FlexFit.tight || hasTightFlexWidth) {
              columnWidths[c] = widthConstraint.flex * spacePerFlexWidth;
            } else {
              columnWidths[c] = widthConstraint.flex * looseSpacePerFlexWidth;
            }
          }
        }
      }
      if (hasFlexHeight) {
        for (int r = 0; r <= maxRow; r += 1) {
          final heightConstraint = _height(r);
          if (heightConstraint is FlexTableSize) {
            if (heightConstraint.fit == FlexFit.tight || hasTightFlexHeight) {
              rowHeights[r] = heightConstraint.flex * spacePerFlexHeight;
            } else {
              rowHeights[r] = heightConstraint.flex * looseSpacePerFlexHeight;
            }
          }
        }
      }
    }

    // convert the column widths and row heights to a list, where missing values are 0
    final columnWidthsList = List<double>.generate(maxColumn + 1, (index) {
      return columnWidths[index] ?? 0;
    });
    columnWidths.forEach((key, value) {
      columnWidthsList[key] = value;
    });
    final rowHeightsList =
        // List.filled(rowHeights.keys.reduce(max) + 1, 0);
        List<double>.generate(maxRow + 1, (index) {
          return rowHeights[index] ?? 0;
        });
    rowHeights.forEach((key, value) {
      rowHeightsList[key] = value;
    });

    return TableLayoutResult(
      columnWidths: columnWidthsList,
      hasTightFlexHeight: hasTightFlexHeight,
      hasTightFlexWidth: hasTightFlexWidth,
      remainingHeight: remainingHeight,
      remainingLooseHeight: looseRemainingHeight,
      remainingLooseWidth: looseRemainingWidth,
      remainingWidth: remainingWidth,
      rowHeights: rowHeightsList,
    );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return computeTableSize(
      BoxConstraints.loose(Size(double.infinity, height)),
      (child, extent) {
        return child.getMaxIntrinsicWidth(extent);
      },
    ).width;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return computeTableSize(
      BoxConstraints.loose(Size(width, double.infinity)),
      (child, extent) {
        return child.getMinIntrinsicHeight(extent);
      },
    ).height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return computeTableSize(
      BoxConstraints.loose(Size(width, double.infinity)),
      (child, extent) {
        return child.getMaxIntrinsicHeight(extent);
      },
    ).height;
  }
}

typedef IntrinsicComputer = double Function(RenderBox child, double extent);

class TableLayoutResult {
  const TableLayoutResult({
    required this.columnWidths,
    required this.hasTightFlexHeight,
    required this.hasTightFlexWidth,
    required this.remainingHeight,
    required this.remainingLooseHeight,
    required this.remainingLooseWidth,
    required this.remainingWidth,
    required this.rowHeights,
  });

  final List<double> columnWidths;
  final List<double> rowHeights;
  final double remainingWidth;
  final double remainingHeight;
  final double remainingLooseWidth;
  final double remainingLooseHeight;
  final bool hasTightFlexWidth;

  final bool hasTightFlexHeight;

  Offset getOffset(int column, int row) {
    double x = 0;
    for (int i = 0; i < column; i += 1) {
      x += columnWidths[i];
    }
    double y = 0;
    for (int i = 0; i < row; i += 1) {
      y += rowHeights[i];
    }

    return Offset(x, y);
  }

  /// Returns the sum of all column widths and row heights.
  Size get size {
    return Size(width, height);
  }

  double get width {
    return columnWidths.fold(0, (a, b) => a + b);
  }

  double get height {
    return rowHeights.fold(0, (a, b) => a + b);
  }
}
