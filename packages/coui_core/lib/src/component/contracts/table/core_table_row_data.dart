/// Platform-independent table cell/row data classes for unified tables.
library;

import 'package:coui_core/src/component/contracts/table/core_table_row_kind.dart';
import 'package:meta/meta.dart';

/// A single cell in a unified table.
///
/// Generic over platform widget type [W] (`Widget`/`Component`).
@immutable
class CoreTableCellData<W> {
  /// Creates a [CoreTableCellData].
  const CoreTableCellData({
    required this.child,
    this.columnSpan = 1,
    this.rowSpan = 1,
    this.enabled = true,
    this.selected = false,
    this.columnHover = false,
    this.rowHover = true,
    this.onPressed,
  });

  /// Cell content.
  final W child;

  /// Number of columns this cell spans (default `1`).
  final int columnSpan;

  /// Number of rows this cell spans (default `1`).
  final int rowSpan;

  /// Whether the cell responds to hover/selection/pointer events.
  final bool enabled;

  /// Whether the cell is rendered in selected state.
  final bool selected;

  /// Whether hovering this cell highlights its column.
  final bool columnHover;

  /// Whether hovering this cell highlights its row (default `true`).
  final bool rowHover;

  /// Optional tap/click callback.
  final void Function()? onPressed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTableCellData<W> &&
          other.child == child &&
          other.columnSpan == columnSpan &&
          other.rowSpan == rowSpan &&
          other.enabled == enabled &&
          other.selected == selected &&
          other.columnHover == columnHover &&
          other.rowHover == rowHover &&
          other.onPressed == onPressed;

  @override
  int get hashCode => Object.hash(
    child,
    columnSpan,
    rowSpan,
    enabled,
    selected,
    columnHover,
    rowHover,
    onPressed,
  );
}

/// A row of cells with optional [selected] state and [kind] (body/header/footer).
///
/// Generic over platform widget type [W].
@immutable
class CoreTableRowData<W> {
  /// Creates a [CoreTableRowData].
  const CoreTableRowData({
    required this.cells,
    this.kind = CoreTableRowKind.body,
    this.selected = false,
  });

  /// Convenience constructor for header rows.
  const CoreTableRowData.header({required this.cells, this.selected = false})
    : kind = CoreTableRowKind.header;

  /// Convenience constructor for footer rows.
  const CoreTableRowData.footer({required this.cells, this.selected = false})
    : kind = CoreTableRowKind.footer;

  /// Row cells.
  final List<CoreTableCellData<W>> cells;

  /// Semantic row kind (body / header / footer).
  final CoreTableRowKind kind;

  /// Whether the entire row is rendered in selected state.
  final bool selected;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CoreTableRowData<W>) return false;
    if (other.kind != kind || other.selected != selected) return false;
    if (other.cells.length != cells.length) return false;
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] != other.cells[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(kind, selected, Object.hashAll(cells));
}
