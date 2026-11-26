// Theme is effectively immutable (const constructor, final fields), but we
// don't depend on `meta` for the @immutable annotation.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:coui_core/src/component/contracts/sortable/sortable_style.dart';

/// Project-level theme overrides for sortable components.
///
/// All chrome / dimensional overrides flow through the single [style]
/// slot ([CoreSortableStyle]). When [style] is null the component uses
/// design system defaults.
///
/// Example:
/// ```dart
/// CoreComponentTheme(
///   sortable: CoreSortableTheme(
///     style: CoreSortableStyle(
///       itemBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
///       handleColor: CoreColor(0xFF888888),
///     ),
///   ),
/// )
/// ```
class CoreSortableTheme {
  /// Creates a [CoreSortableTheme].
  const CoreSortableTheme({this.style});

  /// Project-wide composite style applied to every `Sortable`.
  ///
  /// Resolved before any per-instance `widget.sortableStyle`.
  final CoreSortableStyle? style;

  @override
  bool operator ==(Object other) {
    return other is CoreSortableTheme && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
