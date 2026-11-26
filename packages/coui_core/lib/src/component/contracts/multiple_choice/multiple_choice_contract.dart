/// Platform-independent contract for unified multiple-choice components.
///
/// Defines the interface that all `MultipleChoice` implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/chip/core_chip_color.dart';
import 'package:coui_core/src/component/contracts/chip/core_chip_emphasis.dart';
import 'package:coui_core/src/component/contracts/multiple_choice/multiple_choice_style.dart';

/// A single selectable option in a `MultipleChoice`.
///
/// Carries the option `value` (of type [T]) and the visible `label`.
typedef CoreMultipleChoiceOption<T> = ({T value, String label});

/// Contract for a unified multiple-choice (single-select) component.
///
/// `MultipleChoice` renders a row of selectable options where exactly
/// one option may be active at a time. When [allowUnselect] is true the
/// active option may be cleared by tapping it again.
///
/// Per Epic #1302 chrome / dimensional overrides flow through the single
/// [multipleChoiceStyle] slot. Behavioural / semantic fields (`options`,
/// `value`, `enabled`, `allowUnselect`, `onChanged`) stay flat.
///
/// The change callback is derived directly as `void Function(T?)?` — no
/// phantom `Cb` type parameter (per `cautions.md` "Contract callback
/// 타입").
///
/// Type parameter:
/// - [T] — option value type.
abstract interface class CoreMultipleChoiceContract<T> {
  /// Default for whether a selected option can be cleared by tapping it
  /// again. Single source of truth for the widget default on both
  /// platforms (`allowUnselect` is behaviour, not theme chrome).
  static const bool defaultAllowUnselect = false;

  /// Colour of the composed `Chip` for the **selected** option
  /// (primary · outlined · selected · low). Semantic enum, not chrome — both
  /// platforms pass it to the `Chip` unchanged.
  static const CoreChipColor defaultSelectedChipColor = CoreChipColor.primary;

  /// Emphasis of the composed `Chip` for the **selected** option. Low rather
  /// than the chip's own high default so a multi-select row does not turn
  /// solid primary for every pick.
  static const CoreChipEmphasis defaultSelectedChipEmphasis =
      CoreChipEmphasis.low;

  /// Colour of the composed `Chip` for an **unselected** option
  /// (neutral · outlined · low).
  static const CoreChipColor defaultUnselectedChipColor = CoreChipColor.neutral;

  /// Emphasis of the composed `Chip` for an **unselected** option — the same
  /// low as the selected one, so the row differs by colour and selection
  /// only.
  static const CoreChipEmphasis defaultUnselectedChipEmphasis =
      CoreChipEmphasis.low;

  /// The selectable options.
  List<CoreMultipleChoiceOption<T>> get options;

  /// Currently selected option value. `null` → no selection.
  T? get value;

  /// Whether the choice group is interactive.
  bool get enabled;

  /// Whether the selected option can be cleared by tapping it again.
  bool get allowUnselect;

  /// Called when the selection changes.
  void Function(T?)? get onChanged;

  /// Per-instance chrome / dimensional style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreMultipleChoiceTheme.style
  ///   → parent component slot override
  ///   → widget.multipleChoiceStyle
  /// ```
  CoreMultipleChoiceStyle? get multipleChoiceStyle;
}
