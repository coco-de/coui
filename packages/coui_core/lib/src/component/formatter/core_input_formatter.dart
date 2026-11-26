/// Platform-independent text input formatter primitives for CoUI.
///
/// `CoreInputFormatter` describes a pure string transformation. Flutter
/// (`TextFormatters`) wraps these into `TextInputFormatter` instances
/// that operate on `TextEditingValue`; Web (`TextFormatters`) applies
/// them directly to plain `<input>` strings. Both platforms read the
/// **same** transformation logic so a credit-card / phone / decimal mask
/// behaves identically.
library;

import 'dart:math';

import 'package:expressions/expressions.dart';

/// A pure, platform-neutral text transformation.
///
/// A formatter receives the previous value and the candidate new value
/// and returns the corrected string. It never touches selection /
/// cursor state — that is the platform adapter's responsibility.
abstract class CoreInputFormatter {
  /// Creates a [CoreInputFormatter].
  const CoreInputFormatter();

  /// Transforms [newValue] and returns the corrected string.
  ///
  /// [oldValue] is the value before the edit and may be returned to
  /// reject an invalid edit.
  String format(String oldValue, String newValue);

  /// Applies [format] starting from an empty previous value.
  ///
  /// Convenience for callers that have no prior value to compare against
  /// (e.g. one-shot formatting of an initial string).
  String formatInitial(String value) => format('', value);
}

/// Built-in [CoreInputFormatter] factories shared by Flutter and Web.
///
/// Both platforms expose the identical factory surface — `integerOnly`,
/// `decimalOnly`, `toUpperCase`, `toLowerCase`, `time` and
/// `mathExpression` — so callers write the same code everywhere.
abstract final class CoreInputFormatters {
  const CoreInputFormatters._();

  /// Creates a formatter that only allows integer values.
  ///
  /// - [min]: optional inclusive lower bound.
  /// - [max]: optional inclusive upper bound.
  static CoreInputFormatter integerOnly({int? max, int? min}) {
    return CoreIntegerOnlyFormatter(max: max, min: min);
  }

  /// Creates a formatter that keeps only characters matching [pattern]
  /// (a regular-expression source), dropping the rest. Shared equivalent
  /// of Flutter's `FilteringTextInputFormatter.allow` — used e.g. by
  /// `FormattedInput` to restrict each segment to its digit / char mask.
  static CoreInputFormatter allow(String pattern) {
    return CoreAllowPatternFormatter(pattern);
  }

  /// Creates a formatter for phone entry: digits, plus one leading `+`.
  ///
  /// `allow(r'[\d+]')` cannot stand in — it is per-character, so it accepts a
  /// `+` at any position and any number of them.
  static CoreInputFormatter phoneText() => const CorePhoneTextFormatter();

  /// Creates a formatter that only allows decimal values.
  ///
  /// - [min]: optional inclusive lower bound.
  /// - [max]: optional inclusive upper bound.
  /// - [decimalDigits]: optional maximum decimal digits.
  static CoreInputFormatter decimalOnly({
    int? decimalDigits,
    double? max,
    double? min,
  }) {
    return CoreDecimalOnlyFormatter(
      decimalDigits: decimalDigits,
      max: max,
      min: min,
    );
  }

  /// Creates a formatter that converts text to uppercase.
  static CoreInputFormatter toUpperCase() {
    return const CoreUpperCaseFormatter();
  }

  /// Creates a formatter that converts text to lowercase.
  static CoreInputFormatter toLowerCase() {
    return const CoreLowerCaseFormatter();
  }

  /// Creates a time formatter that pads input with leading zeros.
  ///
  /// - [length]: total length of the formatted time string.
  static CoreInputFormatter time({required int length}) {
    return CoreTimeFormatter(length: length);
  }

  /// Creates a formatter that evaluates the input as a math expression.
  ///
  /// - [context]: optional variable bindings for the expression.
  static CoreInputFormatter mathExpression({Map<String, Object?>? context}) {
    return CoreMathExpressionFormatter(context: context);
  }
}

/// Restricts input to integers, optionally clamped to a range.
/// Keeps only the characters of the new value that match [pattern]
/// (a regular-expression source), dropping the rest. Shared equivalent of
/// Flutter's `FilteringTextInputFormatter.allow`.
class CoreAllowPatternFormatter extends CoreInputFormatter {
  /// Creates a [CoreAllowPatternFormatter] for the regex source [pattern].
  const CoreAllowPatternFormatter(this.pattern);

  /// Regular-expression source — characters that do not match are dropped.
  final String pattern;

  @override
  String format(String oldValue, String newValue) {
    final regExp = RegExp(pattern);
    final buffer = StringBuffer();
    for (final rune in newValue.runes) {
      final char = String.fromCharCode(rune);
      if (regExp.hasMatch(char)) buffer.write(char);
    }
    return buffer.toString();
  }
}

/// Keeps digits, plus a single `+` in the leading position only.
///
/// The shape a phone field needs: `+447911123456` survives, `12+34` loses its
/// `+`, and a second `+` never lands. [CoreAllowPatternFormatter] cannot
/// express this — it tests one character at a time, so `allow(r'[\d+]')`
/// accepts a `+` anywhere and any number of them.
///
/// A lone `+` is kept rather than rejected. It does not parse as a number
/// yet, but erasing it the moment it is typed would make the character
/// unreachable — it can never be followed by digits if it never survives the
/// first keystroke. (The same reasoning [CoreDecimalOnlyFormatter] applies to
/// its sign.)
class CorePhoneTextFormatter extends CoreInputFormatter {
  /// Creates a [CorePhoneTextFormatter].
  const CorePhoneTextFormatter();

  @override
  String format(String oldValue, String newValue) {
    final buffer = StringBuffer();
    for (final rune in newValue.runes) {
      final char = String.fromCharCode(rune);
      // Leading is measured among the characters kept, not among those
      // typed, so `(+82) 10` and `  +82` keep their `+` — the forms people
      // paste. Reading the source index would drop it.
      if (char == '+') {
        if (buffer.isEmpty) buffer.write(char);
        continue;
      }
      if (_kDigit.hasMatch(char)) buffer.write(char);
    }

    return buffer.toString();
  }

  static final RegExp _kDigit = RegExp(r'\d');
}

/// Keeps only integer input, optionally clamped to [min] / [max].
class CoreIntegerOnlyFormatter extends CoreInputFormatter {
  /// Creates a [CoreIntegerOnlyFormatter].
  const CoreIntegerOnlyFormatter({this.max, this.min});

  /// Inclusive lower bound, or `null` for unbounded.
  final int? min;

  /// Inclusive upper bound, or `null` for unbounded.
  final int? max;

  @override
  String format(String oldValue, String newValue) {
    if (newValue.isEmpty) return newValue;

    final lower = min;

    // A lone minus does not parse yet, but rejecting it would make the
    // sign unreachable — the character can never be followed by digits
    // if it is erased the moment it is typed. It is only refused when
    // the range cannot hold a negative number at all.
    if (newValue == '-') {
      return lower != null && lower >= 0 ? oldValue : newValue;
    }

    // Parse the *signed* text. Stripping the sign first and clamping
    // the magnitude let `-5` through a `min: 0` formatter, because the
    // bound was compared against `5`, and the sign was then put back on
    // whatever survived.
    var value = int.tryParse(newValue);
    if (value == null) return oldValue;

    if (lower != null && value < lower) {
      value = lower;
    }
    final upper = max;
    if (upper != null && value > upper) {
      value = upper;
    }

    return value.toString();
  }
}

/// Restricts input to decimals, optionally clamped and digit-limited.
class CoreDecimalOnlyFormatter extends CoreInputFormatter {
  /// Creates a [CoreDecimalOnlyFormatter].
  const CoreDecimalOnlyFormatter({this.decimalDigits, this.max, this.min});

  /// Inclusive lower bound, or `null` for unbounded.
  final double? min;

  /// Inclusive upper bound, or `null` for unbounded.
  final double? max;

  /// Maximum number of decimal digits, or `null` for unlimited.
  final int? decimalDigits;

  @override
  String format(String oldValue, String newValue) {
    if (newValue.isEmpty) return newValue;

    final digits = decimalDigits;
    final lower = min;
    final upper = max;

    // Intermediate states. None of these parse as a number, but each is
    // a character a person has to be able to type on the way to one, so
    // they pass through instead of being erased — refused only when the
    // configuration can never accept them (a non-negative range, or a
    // formatter that allows no decimals at all).
    if (newValue == '-') {
      return lower != null && lower >= 0 ? oldValue : newValue;
    }
    if (newValue == '.') return digits == 0 ? oldValue : newValue;
    if (newValue == '-.') {
      if (digits == 0) return oldValue;
      return lower != null && lower >= 0 ? oldValue : newValue;
    }

    final negate = newValue.startsWith('-');
    var absText = negate ? newValue.substring(1) : newValue;

    if (absText.contains('.')) {
      if (digits == 0) return oldValue;
      final parts = absText.split('.');
      if (parts.length > 2) return oldValue;
      if (digits != null && parts[1].length > digits) {
        absText = '${parts[0]}.${parts[1].substring(0, digits)}';
      }
    }

    final text = negate ? '-$absText' : absText;
    final value = double.tryParse(text);
    if (value == null) return oldValue;

    // Clamp against the *signed* value: comparing the magnitude let
    // `-5` through a `min: 0` formatter.
    if (upper != null && value > upper) return _clamped(upper);
    if (lower != null && value < lower) return _clamped(lower);

    // Within range: hand back exactly what was typed. Round-tripping it
    // through `double.toString()` is what made `0.005` unreachable —
    // `0.00` came back as `0.0`, the trailing-zero trim cut it to `0`,
    // and the digit that was supposed to follow never had a decimal
    // place to land in. It also defeated `decimalDigits`, since
    // `toStringAsFixed` padded to the fixed width and the same trim
    // immediately unpadded it, so `1.50` could not be held on screen.
    return text;
  }

  /// Renders a bound as the text that replaces an out-of-range entry:
  /// fixed-width when [decimalDigits] is set, otherwise trimmed of the
  /// trailing zeros `double.toString` adds.
  String _clamped(double bound) {
    final digits = decimalDigits;
    if (digits != null) return bound.toStringAsFixed(digits);

    var text = bound.toString();
    if (!text.contains('.')) return text;
    while (text.endsWith('0')) {
      text = text.substring(0, text.length - 1);
    }
    if (text.endsWith('.')) {
      text = text.substring(0, text.length - 1);
    }

    return text;
  }
}

/// Converts all input to uppercase.
class CoreUpperCaseFormatter extends CoreInputFormatter {
  /// Creates a [CoreUpperCaseFormatter].
  const CoreUpperCaseFormatter();

  @override
  String format(String oldValue, String newValue) => newValue.toUpperCase();
}

/// Converts all input to lowercase.
class CoreLowerCaseFormatter extends CoreInputFormatter {
  /// Creates a [CoreLowerCaseFormatter].
  const CoreLowerCaseFormatter();

  @override
  String format(String oldValue, String newValue) => newValue.toLowerCase();
}

/// Pads input with leading zeros and trims to a fixed [length].
class CoreTimeFormatter extends CoreInputFormatter {
  /// Creates a [CoreTimeFormatter].
  const CoreTimeFormatter({required this.length});

  /// Total length of the formatted output.
  final int length;

  @override
  String format(String oldValue, String newValue) {
    var text = newValue;
    if (text.length > length) {
      final substringCount = text.length - length;
      text = text.substring(substringCount);
    }
    final padLength = length - text.length;
    if (padLength > 0) {
      text = text.padLeft(length, '0');
    }

    return text.substring(0, min(length, text.length));
  }
}

/// Evaluates the input as a math expression and replaces it with the result.
class CoreMathExpressionFormatter extends CoreInputFormatter {
  /// Creates a [CoreMathExpressionFormatter].
  const CoreMathExpressionFormatter({this.context});

  /// Optional variable bindings available inside the expression.
  final Map<String, Object?>? context;

  @override
  String format(String oldValue, String newValue) {
    Object? result;
    try {
      final expression = Expression.parse(newValue);
      const evaluator = ExpressionEvaluator();
      result = evaluator.eval(expression, context ?? const {});
      if (result is! num) {
        result = '';
      }
    } on Exception {
      result = '';
    }
    var resultText = result?.toString() ?? '';
    if (resultText.contains('.')) {
      while (resultText.endsWith('0')) {
        resultText = resultText.substring(0, resultText.length - 1);
      }
      if (resultText.endsWith('.')) {
        resultText = resultText.substring(0, resultText.length - 1);
      }
    }

    return resultText;
  }
}
