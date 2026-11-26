/// Platform-independent table sizing strategy.
library;

import 'package:meta/meta.dart';

/// Column/row sizing strategy for unified table components.
///
/// Mirrors Flutter's legacy `TableSize` hierarchy (`FlexTableSize`,
/// `FixedTableSize`, `IntrinsicTableSize`) as a sealed class so both
/// platforms can share identical sizing semantics.
@immutable
sealed class CoreTableSize {
  /// Creates a [CoreTableSize].
  const CoreTableSize();
}

/// Sizes the column/row proportionally to available space.
///
/// All flex columns/rows share the remaining space after fixed and
/// intrinsic columns/rows have been measured. [flex] controls the ratio.
@immutable
class CoreFlexTableSize extends CoreTableSize {
  /// Creates a [CoreFlexTableSize].
  const CoreFlexTableSize({this.flex = 1});

  /// Proportional share (default `1`).
  final double flex;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreFlexTableSize && other.flex == flex;

  @override
  int get hashCode => flex.hashCode;
}

/// Sizes the column/row to a fixed pixel value.
@immutable
class CoreFixedTableSize extends CoreTableSize {
  /// Creates a [CoreFixedTableSize] with the given [value] in pixels.
  const CoreFixedTableSize(this.value);

  /// Size in pixels.
  final double value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreFixedTableSize && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Sizes the column/row to the intrinsic content size.
///
/// The column/row shrinks/grows to fit the largest cell content.
@immutable
class CoreIntrinsicTableSize extends CoreTableSize {
  /// Creates a [CoreIntrinsicTableSize].
  const CoreIntrinsicTableSize();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CoreIntrinsicTableSize;

  @override
  int get hashCode => 0;
}

/// Min/max constraint for resizable table cells.
@immutable
class CoreConstrainedTableSize {
  /// Creates a [CoreConstrainedTableSize].
  const CoreConstrainedTableSize({
    this.min = double.negativeInfinity,
    this.max = double.infinity,
  });

  /// Minimum size in pixels.
  final double min;

  /// Maximum size in pixels.
  final double max;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreConstrainedTableSize && other.min == min && other.max == max;

  @override
  int get hashCode => Object.hash(min, max);
}
