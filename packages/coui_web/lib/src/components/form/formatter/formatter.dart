import 'package:coui_core/coui_core.dart';

/// Unified text input formatter factory collection for CoUI Web.
///
/// Every factory returns a [CoreInputFormatter] from the shared
/// [CoreInputFormatters] logic — the same transformation Flutter's
/// `TextInputFormatters` wraps into a `TextInputFormatter`. Web
/// `<input>` widgets apply these directly to plain strings.
///
/// The class name and factory surface — `integerOnly`, `decimalOnly`,
/// `toUpperCase`, `toLowerCase`, `time` and `mathExpression` — are
/// identical to Flutter's `TextInputFormatters` (cross-platform parity).
///
/// Example:
/// ```dart
/// final formatter = TextInputFormatters.integerOnly(min: 0, max: 100);
/// final result = formatter.format('', '42');
/// ```
abstract final class TextInputFormatters {
  const TextInputFormatters._();

  /// Creates a formatter that only allows integer values.
  static CoreInputFormatter integerOnly({int? max, int? min}) {
    return CoreInputFormatters.integerOnly(max: max, min: min);
  }

  /// Creates a formatter that only allows decimal values.
  static CoreInputFormatter decimalOnly({
    int? decimalDigits,
    double? max,
    double? min,
  }) {
    return CoreInputFormatters.decimalOnly(
      decimalDigits: decimalDigits,
      max: max,
      min: min,
    );
  }

  /// Creates a formatter that converts text to uppercase.
  static CoreInputFormatter toUpperCase() {
    return CoreInputFormatters.toUpperCase();
  }

  /// Creates a formatter that converts text to lowercase.
  static CoreInputFormatter toLowerCase() {
    return CoreInputFormatters.toLowerCase();
  }

  /// Creates a time formatter that pads input with leading zeros.
  static CoreInputFormatter time({required int length}) {
    return CoreInputFormatters.time(length: length);
  }

  /// Creates a formatter that evaluates the input as a math expression.
  static CoreInputFormatter mathExpression({Map<String, Object?>? context}) {
    return CoreInputFormatters.mathExpression(context: context);
  }
}
