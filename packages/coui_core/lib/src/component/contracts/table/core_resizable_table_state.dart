/// Platform-independent resizable table state interface.
library;

import 'package:coui_core/src/component/contracts/table/core_table_size.dart';

/// Shared state contract for resizable-table controllers.
///
/// Both Flutter and Web controllers implement this so the resizable table
/// contract's `controller` field can be queried uniformly. Listener /
/// subscription APIs are platform-specific and declared on each platform's
/// concrete controller.
abstract interface class CoreResizableTableState {
  /// Returns the current width of [column] in pixels.
  double getColumnWidth(int column);

  /// Returns the current height of [row] in pixels.
  double getRowHeight(int row);

  /// Returns the minimum allowed width for [column], if constrained.
  double? getColumnMinWidth(int column);

  /// Returns the maximum allowed width for [column], if constrained.
  double? getColumnMaxWidth(int column);

  /// Returns the minimum allowed height for [row], if constrained.
  double? getRowMinHeight(int row);

  /// Returns the maximum allowed height for [row], if constrained.
  double? getRowMaxHeight(int row);

  /// Attempts to resize [column] to [width] pixels.
  ///
  /// Returns `true` if the size changed.
  bool resizeColumn(int column, double width);

  /// Attempts to resize [row] to [height] pixels.
  ///
  /// Returns `true` if the size changed.
  bool resizeRow(int row, double height);

  /// Default column width applied when no explicit override is set.
  double get defaultColumnWidth;

  /// Default row height applied when no explicit override is set.
  double get defaultRowHeight;

  /// Default width constraint (applies to columns without an explicit entry).
  CoreConstrainedTableSize? get defaultWidthConstraint;

  /// Default height constraint (applies to rows without an explicit entry).
  CoreConstrainedTableSize? get defaultHeightConstraint;
}
