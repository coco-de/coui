/// Platform-independent contract for unified formatted input components.
library;

import 'package:coui_core/src/component/contracts/formatted_input/formatted_input_part.dart';
import 'package:coui_core/src/component/contracts/formatted_input/formatted_input_style.dart';

/// Contract for a unified formatted / masked input component.
///
/// `FormattedInput` renders a segmented input — a mix of static
/// separators and editable fields — for structured data entry such as
/// phone numbers, credit cards, and dates. The structure is defined by
/// the [parts] list.
///
/// Per Epic #1302 chrome / dimensional overrides flow through the single
/// [formattedInputStyle] slot. Behavioural / semantic fields (`parts`,
/// `value`, `enabled`, `onChanged`, `leading`, `trailing`) stay flat.
///
/// Type parameters:
/// - [Cb] — change callback type derived as `void Function(String)?`.
/// - [W] — widget type of the `leading` / `trailing` composition slots.
abstract interface class CoreFormattedInputContract<Cb, W> {
  /// The mask segments defining the structure of the input.
  List<CoreFormattedInputPart> get parts;

  /// Current concatenated value of all editable segments.
  String? get value;

  /// Whether the input is interactive.
  bool get enabled;

  /// Called whenever the concatenated value changes.
  Cb get onChanged;

  /// Optional widget displayed before the segments.
  W? get leading;

  /// Optional widget displayed after the segments.
  W? get trailing;

  /// Per-instance chrome / dimensional style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreFormattedInputTheme.style
  ///   → parent component slot override
  ///   → widget.formattedInputStyle
  /// ```
  CoreFormattedInputStyle? get formattedInputStyle;
}
