/// Platform-independent contract for unified category breakdown
/// components.
///
/// Defines the interface that all CategoryBreakdown implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/component/contracts/category_breakdown/category_breakdown_style.dart';
import 'package:coui_core/src/component/contracts/category_breakdown/category_breakdown_variant.dart';
import 'package:meta/meta.dart';

/// One category of a `CategoryBreakdown`.
///
/// [label] and [valueLabel] are display strings the caller already
/// formatted for its locale. The share (percentage) is computed by
/// `CoreCategoryBreakdownGeometry` so both platforms print the same
/// number.
@immutable
class CoreCategoryBreakdownItem {
  /// Creates a [CoreCategoryBreakdownItem].
  const CoreCategoryBreakdownItem({
    required this.label,
    required this.value,
    this.valueLabel,
    this.color,
  });

  /// Category name (e.g. `'결제 문의'`).
  final String label;

  /// The category's amount. Negative values count as zero.
  final double value;

  /// Caller-formatted amount (e.g. `'128건'`). `null` falls back to a
  /// locale-neutral number.
  final String? valueLabel;

  /// Overrides this category's colour. `null` takes the next colour of
  /// `CoreCategoryBreakdownStyle.seriesColors`.
  final CoreColor? color;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCategoryBreakdownItem &&
          label == other.label &&
          value == other.value &&
          valueLabel == other.valueLabel &&
          color == other.color;

  @override
  int get hashCode => Object.hash(label, value, valueLabel, color);
}

/// Contract for a unified category breakdown — each category's share of
/// a total, drawn as horizontal bars or a donut with a legend.
///
/// Type parameters:
/// - [W] - platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreCategoryBreakdownContract<W> {
  /// How the shares are drawn.
  CoreCategoryBreakdownVariant get variant;

  /// The categories, in display order.
  List<CoreCategoryBreakdownItem> get items;

  /// Rendered at the centre of the donut (e.g. the total). Ignored by
  /// the bar variant.
  W? get center;

  /// Rendered instead of the chart when there are no items or the total
  /// is zero.
  W? get empty;

  /// Accessible name of the breakdown (e.g. `'문의 유형별 분포'`).
  String? get semanticLabel;

  /// Per-instance chrome / dimensional style.
  ///
  /// ```text
  /// CoreCategoryBreakdownStyle.default*
  ///   → CoreCategoryBreakdownTheme.style
  ///   → CoreCategoryBreakdownTheme.variantStyles[variant]
  ///   → widget.categoryBreakdownStyle
  /// ```
  CoreCategoryBreakdownStyle? get categoryBreakdownStyle;
}
