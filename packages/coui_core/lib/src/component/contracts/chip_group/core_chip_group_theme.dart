/// Platform-independent theme for `ChipGroup`.
library;

import 'package:coui_core/src/component/contracts/chip_group/chip_group_style.dart';
import 'package:coui_core/src/component/contracts/chip_group/core_chip_group_layout.dart';
import 'package:coui_core/src/component/contracts/chip_group/core_chip_group_selection_mode.dart';
import 'package:meta/meta.dart';

/// `ChipGroup` component theme.
///
/// Carries only:
/// - the project-wide [style] slot (all 시각 chrome — gaps, fade,
///   text styles — lives inside `CoreChipGroupStyle`),
/// - semantic enum defaults ([layout] / [selectionMode]).
///
/// Per-instance overrides flow through `widget.chipGroupStyle` →
/// `CoreChipGroupTheme.style` (Epic #1302 / #1370).
@immutable
class CoreChipGroupTheme {
  /// Creates a [CoreChipGroupTheme].
  const CoreChipGroupTheme({
    this.style,
    this.layout,
    this.selectionMode,
  });

  /// Project-wide style override.
  final CoreChipGroupStyle? style;

  /// Default layout mode override.
  final CoreChipGroupLayout? layout;

  /// Default selection mode override.
  final CoreChipGroupSelectionMode? selectionMode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoreChipGroupTheme &&
          other.style == style &&
          other.layout == layout &&
          other.selectionMode == selectionMode);

  @override
  int get hashCode => Object.hash(style, layout, selectionMode);
}
