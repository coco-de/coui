/// Platform-independent contract for unified item picker components.
library;

import 'package:coui_core/src/component/contracts/item_picker/item_picker_layout.dart';
import 'package:coui_core/src/component/contracts/item_picker/item_picker_style.dart';

/// Contract for a unified inline item picker component.
///
/// `ItemPicker` renders a searchable, single-select list (or grid) of
/// string items. Typing in the search field filters the items
/// (case-insensitive `contains`); clicking an item selects it.
///
/// Per Epic #1302 chrome / dimensional overrides flow through the single
/// [itemPickerStyle] slot. Behavioural / semantic fields (`items`,
/// `selectedValue`, `showSearch`, `enabled`, `layout`, `gridColumns`,
/// `title`, `searchPlaceholder`, `emptyText`, callbacks) stay flat.
///
/// Type parameter:
/// - [Cb] — change callback type derived as `void Function(String)?`.
abstract interface class CoreItemPickerContract<Cb> {
  /// The full list of selectable item values.
  List<String> get items;

  /// Currently selected item value, or `null` when nothing is selected.
  String? get selectedValue;

  /// Placeholder text for the search field.
  String? get searchPlaceholder;

  /// Whether the search field is shown.
  bool get showSearch;

  /// Whether the picker is interactive.
  bool get enabled;

  /// Layout mode for arranging the items (list or grid).
  CoreItemPickerLayout get layout;

  /// Number of columns when [layout] is `grid`.
  int get gridColumns;

  /// Optional title displayed above the items.
  String? get title;

  /// Text shown when no items match the search query.
  String? get emptyText;

  /// Called when the user selects an item.
  Cb get onChanged;

  /// Per-instance chrome / dimensional style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreItemPickerTheme.style
  ///   → parent component slot override
  ///   → widget.itemPickerStyle
  /// ```
  CoreItemPickerStyle? get itemPickerStyle;
}
