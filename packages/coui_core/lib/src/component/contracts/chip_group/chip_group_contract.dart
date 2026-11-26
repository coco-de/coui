/// Platform-independent contract for unified `ChipGroup` components.
///
/// Defines the interface that all `ChipGroup` implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/chip_group/chip_group_style.dart';
import 'package:coui_core/src/component/contracts/chip_group/core_chip_group_layout.dart';
import 'package:coui_core/src/component/contracts/chip_group/core_chip_group_max_behavior.dart';
import 'package:coui_core/src/component/contracts/chip_group/core_chip_group_selection_mode.dart';

/// Builder signature for individual chip widgets.
///
/// `onTap` is the selection handler `ChipGroup` provides — wire it
/// to the chip's own `onTap`.
typedef CoreChipGroupItemBuilder<T, W> =
    W Function(
      T item, {
      required bool selected,
      required bool enabled,
      required void Function() onTap,
    });

/// Contract for a unified chip group component.
///
/// Type parameters:
/// - [T] — item value type.
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreChipGroupContract<T, W> {
  /// Items rendered as chips.
  List<T> get items;

  /// Builder for each chip item.
  CoreChipGroupItemBuilder<T, W> get chipBuilder;

  /// Selection mode (single / multi).
  CoreChipGroupSelectionMode? get selectionMode;

  /// Layout mode (wrap / scroll).
  CoreChipGroupLayout? get layout;

  /// Initial selected items.
  Set<T>? get initialValue;

  /// Selection change callback.
  void Function(Set<T>)? get onChanged;

  /// Whether single-mode chips can be deselected.
  bool get allowDeselect;

  /// Maximum selectable count.
  int? get maxSelection;

  /// Behavior when [maxSelection] is reached.
  CoreChipGroupMaxBehavior? get maxSelectionBehavior;

  /// Minimum selectable count (deselect is blocked below this).
  int? get minSelection;

  /// Title widget rendered above the chips.
  W? get title;

  /// Selection hint widget rendered next to title.
  W? get selectionHint;

  /// Whether to render edge fade in scroll layout.
  bool get showFade;

  /// Per-instance composite style.
  ///
  /// All chrome (gaps / fade chrome / nested text styles) lives inside
  /// this slot — there are no flat chrome getters on the contract.
  ///
  /// ```text
  /// design system default (CoreChipGroupStyle.defaultX)
  ///   → CoreChipGroupTheme.style
  ///   → widget.chipGroupStyle
  /// ```
  CoreChipGroupStyle? get chipGroupStyle;
}
