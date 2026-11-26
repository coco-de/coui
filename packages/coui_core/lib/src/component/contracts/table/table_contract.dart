/// Platform-independent contract for unified table components.
library;

import 'package:coui_core/src/component/contracts/table/core_frozen_table_data.dart';
import 'package:coui_core/src/component/contracts/table/core_resizable_table_state.dart';
import 'package:coui_core/src/component/contracts/table/core_table_cell_resize_mode.dart';
import 'package:coui_core/src/component/contracts/table/core_table_row_data.dart';
import 'package:coui_core/src/component/contracts/table/core_table_size.dart';
import 'package:coui_core/src/component/contracts/table/table_style.dart';
import 'package:coui_core/src/shape/clip_mode.dart';

/// Contract for a unified table component (non-resizable).
///
/// Per Epic #1302 every chrome / dimensional override flows through
/// the single [tableStyle] field — see [CoreTableStyle].
///
/// Type parameter:
/// - [W] — platform widget type (`Widget` on Flutter, `Component` on Web).
abstract interface class CoreTableContract<W> {
  /// Rows (body / header / footer) in rendering order.
  List<CoreTableRowData<W>> get rows;

  /// Default column sizing strategy (fallback when [columnWidths] is null).
  CoreTableSize get defaultColumnWidth;

  /// Default row sizing strategy (fallback when [rowHeights] is null).
  CoreTableSize get defaultRowHeight;

  /// Per-column size overrides by column index.
  Map<int, CoreTableSize>? get columnWidths;

  /// Per-row size overrides by row index.
  Map<int, CoreTableSize>? get rowHeights;

  /// Frozen rows/columns that remain visible during scroll.
  CoreFrozenTableData? get frozenCells;

  /// Horizontal scroll offset (pixels). `null` disables horizontal scroll.
  double? get horizontalOffset;

  /// Vertical scroll offset (pixels). `null` disables vertical scroll.
  double? get verticalOffset;

  /// Clip behavior on overflow.
  ///
  /// Platform-neutral [CoreClipMode]; each implementation converts to
  /// its native representation (Flutter `Clip`, Web `overflow`).
  CoreClipMode get clipBehavior;

  /// Per-instance table chrome / dimensional / slot style.
  CoreTableStyle? get tableStyle;
}

/// Contract for a unified resizable table component.
///
/// Extends [CoreTableContract] with column/row resize state and behavior
/// exposed via the platform-neutral [CoreResizableTableState] controller.
///
/// Type parameter:
/// - [W] — platform widget type (`Widget` on Flutter, `Component` on Web).
abstract interface class CoreResizableTableContract<W> {
  /// Rows to render.
  List<CoreTableRowData<W>> get rows;

  /// Resize controller managing column widths / row heights.
  CoreResizableTableState get controller;

  /// Column resize mode.
  CoreTableCellResizeMode get columnResizeMode;

  /// Row resize mode.
  CoreTableCellResizeMode get rowResizeMode;

  /// Frozen rows/columns.
  CoreFrozenTableData? get frozenCells;

  /// Horizontal scroll offset (pixels).
  double? get horizontalOffset;

  /// Vertical scroll offset (pixels).
  double? get verticalOffset;

  /// Clip behavior on overflow.
  ///
  /// Platform-neutral [CoreClipMode]; each implementation converts to
  /// its native representation (Flutter `Clip`, Web `overflow`).
  CoreClipMode get clipBehavior;

  /// Per-instance table chrome / dimensional / slot style.
  CoreTableStyle? get tableStyle;
}
