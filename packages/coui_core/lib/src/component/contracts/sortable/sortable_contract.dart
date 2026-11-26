/// Platform-independent contract for sortable list components.
///
/// Defines the interface that all sortable implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/sortable/sortable_style.dart';
import 'package:coui_core/src/drag/core_sortable.dart';

/// Callback for reorder events with source and target indices.
typedef CoreSortableReorderCallback =
    void Function(
      int oldIndex,
      int newIndex,
    );

/// Callback for item removal events.
typedef CoreSortableRemoveCallback = void Function(int index);

/// Contract for a sortable list component.
///
/// Type parameters:
/// - [W] - platform widget type
///   (Flutter `Widget`, Web `Component`).
/// - [ItemBuilder] - builder function for sortable items.
///
/// Implementations should render a reorderable list
/// with drag handles and optional remove buttons.
abstract interface class CoreSortableContract<W, ItemBuilder> {
  /// The axis a sortable list runs along unless told otherwise.
  static const CoreSortableAxis defaultAxis = .vertical;

  /// The number of items in the sortable list.
  int get itemCount;

  /// Which way the list runs.
  ///
  /// A grid resolves landing by 2D proximity instead of by one coordinate,
  /// because the cell to the right and the cell below are both "next".
  ///
  /// Item width follows the axis: `.vertical` items stretch to the list's
  /// width (there is only one item per row, so "the row" and "the item"
  /// are the same width). `.horizontal` and `.grid` items size to their
  /// own content — they do not divide the container's width equally,
  /// mirroring `Row`/`Wrap`'s un-stretched children.
  CoreSortableAxis get axis;

  /// Builder function that creates each sortable item.
  ItemBuilder get itemBuilder;

  /// Callback when items are reordered.
  CoreSortableReorderCallback? get onReorder;

  /// Callback when an item is removed.
  CoreSortableRemoveCallback? get onRemove;

  /// Whether drag-and-drop reordering is enabled.
  bool get enabled;

  /// Whether items can be removed.
  bool get removable;

  /// Per-instance composite chrome / slot style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreSortableTheme (legacy flat fields)
  ///   → CoreSortableTheme.style
  ///   → parent component slot override
  ///   → widget.sortableStyle
  /// ```
  CoreSortableStyle? get sortableStyle;
}
