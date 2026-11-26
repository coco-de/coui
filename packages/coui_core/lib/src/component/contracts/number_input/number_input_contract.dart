/// Cross-platform contract for `NumberInput`.
library;

import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/button/button_shape.dart';
import 'package:coui_core/src/component/contracts/button/button_variant.dart';
import 'package:coui_core/src/component/contracts/number_input/number_input_size.dart';
import 'package:coui_core/src/component/contracts/number_input/number_input_style.dart';
import 'package:coui_core/src/component/contracts/number_input/number_input_variant.dart';

/// A one-line field that raises and lowers a number — `[ − ] value [ + ]`.
///
/// The field is a composed `TextField` (border, fill, hover, focus, error,
/// label and description come from it) with a `Button` at each end. The
/// value can be typed; the buttons and the arrow / page keys move it by
/// [step], and it always stays within [min] .. [max].
abstract interface class CoreNumberInputContract {
  /// How much a button press or an arrow key moves the value.
  static const double defaultStep = 1;

  /// The `Button` variant of the two step buttons.
  static const CoreButtonVariant stepButtonVariant = CoreButtonVariant.plain;

  /// The `Button` shape of the two step buttons.
  static const CoreButtonShape stepButtonShape = CoreButtonShape.square;

  /// The multiple of [step] a Page Up / Page Down key moves the value by.
  static const int pageStepMultiple = 10;

  /// The current value (controlled). `null` → uncontrolled, starting at
  /// [initialValue].
  double? get value;

  /// The starting value when [value] is `null`. `null` → [min] when stated,
  /// else `0`.
  double? get initialValue;

  /// Called whenever the value changes — a button, a key, or a typed number
  /// that parses.
  CoreValueChanged<double>? get onChanged;

  /// The lowest value. `null` → no lower bound. At the bound the decrement
  /// button is disabled.
  double? get min;

  /// The highest value. `null` → no upper bound. At the bound the increment
  /// button is disabled.
  double? get max;

  /// The amount one press moves the value by. Must be positive.
  double get step;

  /// How the field is drawn.
  CoreNumberInputVariant get variant;

  /// The height step of the field and its buttons.
  CoreNumberInputSize get size;

  /// Whether the field and its buttons take input. `null` → enabled.
  bool? get enabled;

  /// A name shown above the field. `null` draws none.
  String? get label;

  /// Helper text shown below the field. `null` draws none.
  String? get description;

  /// Validation message replacing [description]. The composed field owns
  /// error styling and accessible invalid state. Null preserves the default.
  String? get errorText;

  /// Per-instance chrome.
  ///
  /// ```text
  /// design system default
  ///   → CoreNumberInputTheme.style
  ///   → CoreNumberInputTheme.variantStyles[variant]
  ///   → widget.numberInputStyle
  /// ```
  CoreNumberInputStyle? get numberInputStyle;
}
