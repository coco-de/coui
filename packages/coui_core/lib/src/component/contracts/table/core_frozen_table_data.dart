/// Platform-independent frozen-cell data for table components.
library;

import 'package:meta/meta.dart';

/// References a contiguous range of rows or columns, optionally spanning
/// multiple indices.
///
/// Used by [CoreFrozenTableData] to describe rows/columns that should
/// remain visible (frozen) during scroll.
@immutable
class CoreTableRef {
  /// Creates a [CoreTableRef] starting at [index] with the given [span].
  const CoreTableRef(this.index, [this.span = 1]);

  /// Start index (0-based).
  final int index;

  /// Number of rows/columns occupied by this reference.
  final int span;

  /// Returns `true` when [target] falls anywhere within this reference range.
  bool test(int target, int targetSpan) {
    return index <= target && index + span > target;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTableRef && other.index == index && other.span == span;

  @override
  int get hashCode => Object.hash(index, span);
}

/// Row/column freezing configuration shared by all unified table
/// implementations.
///
/// When set, the referenced rows/columns remain in place while the
/// remaining content scrolls.
@immutable
class CoreFrozenTableData {
  /// Creates a [CoreFrozenTableData].
  const CoreFrozenTableData({
    this.frozenRows = const [],
    this.frozenColumns = const [],
  });

  /// Row references that should remain visible during vertical scroll.
  final List<CoreTableRef> frozenRows;

  /// Column references that should remain visible during horizontal scroll.
  final List<CoreTableRef> frozenColumns;

  /// Returns `true` when the row at [index] with [span] is frozen.
  bool testRow(int index, int span) {
    for (final ref in frozenRows) {
      if (ref.test(index, span)) return true;
    }
    return false;
  }

  /// Returns `true` when the column at [index] with [span] is frozen.
  bool testColumn(int index, int span) {
    for (final ref in frozenColumns) {
      if (ref.test(index, span)) return true;
    }
    return false;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CoreFrozenTableData) return false;
    if (frozenRows.length != other.frozenRows.length) return false;
    if (frozenColumns.length != other.frozenColumns.length) return false;
    for (var i = 0; i < frozenRows.length; i++) {
      if (frozenRows[i] != other.frozenRows[i]) return false;
    }
    for (var i = 0; i < frozenColumns.length; i++) {
      if (frozenColumns[i] != other.frozenColumns[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(frozenRows),
    Object.hashAll(frozenColumns),
  );
}
