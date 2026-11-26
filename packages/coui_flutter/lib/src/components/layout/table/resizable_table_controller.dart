import 'package:coui_flutter/coui_flutter.dart';

/// Controller for [ResizableTable].
///
/// Holds column widths, row heights, and optional constraints. Notifies
/// listeners when any size changes (via drag-resize or programmatic update).
class ResizableTableController extends ChangeNotifier
    implements CoreResizableTableState {
  /// Creates a [ResizableTableController].
  ResizableTableController({
    required double defaultColumnWidth,
    required double defaultRowHeight,
    Map<int, double>? columnWidths,
    Map<int, double>? rowHeights,
    CoreConstrainedTableSize? defaultWidthConstraint,
    CoreConstrainedTableSize? defaultHeightConstraint,
    Map<int, CoreConstrainedTableSize>? widthConstraints,
    Map<int, CoreConstrainedTableSize>? heightConstraints,
  }) : _defaultColumnWidth = defaultColumnWidth,
       _defaultRowHeight = defaultRowHeight,
       _columnWidths = columnWidths,
       _rowHeights = rowHeights,
       _defaultWidthConstraint = defaultWidthConstraint,
       _defaultHeightConstraint = defaultHeightConstraint,
       _widthConstraints = widthConstraints,
       _heightConstraints = heightConstraints;

  final double _defaultColumnWidth;
  final double _defaultRowHeight;
  Map<int, double>? _columnWidths;
  Map<int, double>? _rowHeights;
  final CoreConstrainedTableSize? _defaultWidthConstraint;
  final CoreConstrainedTableSize? _defaultHeightConstraint;
  final Map<int, CoreConstrainedTableSize>? _widthConstraints;
  final Map<int, CoreConstrainedTableSize>? _heightConstraints;

  @override
  double get defaultColumnWidth => _defaultColumnWidth;

  @override
  double get defaultRowHeight => _defaultRowHeight;

  @override
  CoreConstrainedTableSize? get defaultWidthConstraint =>
      _defaultWidthConstraint;

  @override
  CoreConstrainedTableSize? get defaultHeightConstraint =>
      _defaultHeightConstraint;

  @override
  double getColumnWidth(int column) =>
      _columnWidths?[column] ?? _defaultColumnWidth;

  @override
  double getRowHeight(int row) => _rowHeights?[row] ?? _defaultRowHeight;

  /// Whether [column] has an explicit width set via [resizeColumn].
  bool hasCustomColumnWidth(int column) =>
      _columnWidths?.containsKey(column) ?? false;

  /// Whether [row] has an explicit height set via [resizeRow].
  bool hasCustomRowHeight(int row) => _rowHeights?.containsKey(row) ?? false;

  @override
  double? getColumnMinWidth(int column) =>
      _widthConstraints?[column]?.min ?? _defaultWidthConstraint?.min;

  @override
  double? getColumnMaxWidth(int column) =>
      _widthConstraints?[column]?.max ?? _defaultWidthConstraint?.max;

  @override
  double? getRowMinHeight(int row) =>
      _heightConstraints?[row]?.min ?? _defaultHeightConstraint?.min;

  @override
  double? getRowMaxHeight(int row) =>
      _heightConstraints?[row]?.max ?? _defaultHeightConstraint?.max;

  @override
  bool resizeColumn(int column, double width) {
    if (column < 0 || width < 0) return false;
    final minW = getColumnMinWidth(column) ?? 0.0;
    final maxW = getColumnMaxWidth(column) ?? .infinity;
    final clamped = width.clamp(minW, maxW).toDouble();
    if (_columnWidths?[column] == clamped) return false;
    _columnWidths = {...?_columnWidths, column: clamped};
    notifyListeners();
    return true;
  }

  @override
  bool resizeRow(int row, double height) {
    if (row < 0 || height < 0) return false;
    final minH = getRowMinHeight(row) ?? 0.0;
    final maxH = getRowMaxHeight(row) ?? .infinity;
    final clamped = height.clamp(minH, maxH).toDouble();
    if (_rowHeights?[row] == clamped) return false;
    _rowHeights = {...?_rowHeights, row: clamped};
    notifyListeners();
    return true;
  }
}
