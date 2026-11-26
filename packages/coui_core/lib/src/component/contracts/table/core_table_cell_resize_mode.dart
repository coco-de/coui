/// Cell resize behavior for resizable tables.
library;

/// How a cell behaves when its column/row is resized.
enum CoreTableCellResizeMode {
  /// The cell expands when resized; other cells are unaffected.
  expand,

  /// Resizing is disabled for this axis.
  none,

  /// The cell expands while neighboring cells shrink to compensate.
  reallocate,
}
