import 'package:coui_core/coui_core.dart';
import 'package:flutter/services.dart';

/// A Flutter [TextInputFormatter] that delegates to a [CoreInputFormatter].
///
/// `InputFormatter` adapts CoUI's platform-neutral [CoreInputFormatter]
/// transformation to Flutter's `TextEditingValue`-based formatter API,
/// preserving the caret position after the string is rewritten. Web's
/// `TextFormatters` consumes the very same [CoreInputFormatter] logic,
/// so a mask behaves identically on both platforms.
///
/// Example:
/// ```dart
/// TextField(
///   inputFormatters: [
///     InputFormatter(CoreInputFormatters.integerOnly(min: 0, max: 100)),
///   ],
/// )
/// ```
class InputFormatter extends TextInputFormatter {
  /// Creates a [InputFormatter] wrapping [formatter].
  const InputFormatter(this.formatter);

  /// The platform-neutral transformation applied to the input text.
  final CoreInputFormatter formatter;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = formatter.format(oldValue.text, newValue.text);
    if (newText == newValue.text) {
      return newValue;
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: newValue.selection.baseOffset.clamp(0, newText.length),
        extentOffset: newValue.selection.extentOffset.clamp(0, newText.length),
      ),
    );
  }
}

/// Unified text input formatter factory collection for Flutter.
///
/// Every factory returns a Flutter [TextInputFormatter] backed by the
/// shared [CoreInputFormatters] logic. The factory surface —
/// `integerOnly`, `decimalOnly`, `toUpperCase`, `toLowerCase`, `time`
/// and `mathExpression` — is identical to Web's `TextFormatters`.
abstract final class TextInputFormatters {
  const TextInputFormatters._();

  /// Creates a formatter that only allows integer values.
  static TextInputFormatter integerOnly({int? max, int? min}) {
    return InputFormatter(
      CoreInputFormatters.integerOnly(max: max, min: min),
    );
  }

  /// Creates a formatter that keeps only characters matching [pattern]
  /// (a regular-expression source). Shared [CoreInputFormatters.allow]
  /// logic — the parity of Flutter's `FilteringTextInputFormatter.allow`.
  static TextInputFormatter allow(String pattern) {
    return InputFormatter(CoreInputFormatters.allow(pattern));
  }

  /// Creates a formatter for phone entry: digits, plus one leading `+`.
  /// Shared [CoreInputFormatters.phoneText] logic.
  static TextInputFormatter phoneText() {
    return InputFormatter(CoreInputFormatters.phoneText());
  }

  /// Creates a formatter that only allows decimal values.
  static TextInputFormatter decimalOnly({
    int? decimalDigits,
    double? max,
    double? min,
  }) {
    return InputFormatter(
      CoreInputFormatters.decimalOnly(
        decimalDigits: decimalDigits,
        max: max,
        min: min,
      ),
    );
  }

  /// Creates a formatter that converts text to uppercase.
  static TextInputFormatter toUpperCase() {
    return const InputFormatter(CoreUpperCaseFormatter());
  }

  /// Creates a formatter that converts text to lowercase.
  static TextInputFormatter toLowerCase() {
    return const InputFormatter(CoreLowerCaseFormatter());
  }

  /// Creates a time formatter that pads input with leading zeros.
  static TextInputFormatter time({required int length}) {
    return InputFormatter(CoreInputFormatters.time(length: length));
  }

  /// Creates a formatter that evaluates the input as a math expression.
  static TextInputFormatter mathExpression({Map<String, Object?>? context}) {
    return InputFormatter(
      CoreInputFormatters.mathExpression(context: context),
    );
  }
}
