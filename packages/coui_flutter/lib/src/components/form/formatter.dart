import 'dart:math';

import 'package:expressions/expressions.dart';
import 'package:flutter/services.dart';

TextSelection contraintToNewText(String newText, TextEditingValue newValue) {
  return TextSelection(
    baseOffset: newValue.selection.baseOffset.clamp(0, newText.length),
    extentOffset: newValue.selection.extentOffset.clamp(0, newText.length),
  );
}

abstract final class TextInputFormatters {
  const TextInputFormatters._();
  static TextInputFormatter mathExpression({Map<String, dynamic>? context}) {
    return _MathExpressionFormatter(context: context);
  }
}

class _TimeFormatter extends TextInputFormatter {
  const _TimeFormatter({required this.length});
  final int length;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue newValue,
    TextEditingValue oldValue,
  ) {
    String newText = newValue.text;
    int substringCount = 0;
    if (newText.length > length) {
      substringCount = newText.length - length;
      newText = newText.substring(substringCount);
    }
    final padLength = length - newText.length;
    int baseOffset2 = newValue.selection.baseOffset;
    int extentOffset2 = newValue.selection.extentOffset;
    if (padLength > 0) {
      newText = newText.padLeft(length, '0');
      baseOffset2 += padLength;
      extentOffset2 += padLength;
    }

    return newValue.copyWith(
      composing: newValue.composing.isValid
          ? TextRange(
              end: newValue.composing.end.clamp(
                0,
                min(length, newValue.text.length),
              ),
              start: newValue.composing.start.clamp(
                0,
                min(length, newValue.text.length),
              ),
            )
          : newValue.composing,
      selection: TextSelection(
        baseOffset: baseOffset2.clamp(0, min(length, newText.length)),
        extentOffset: extentOffset2.clamp(0, min(length, newText.length)),
      ),
      text: newText,
    );
  }
}

class _IntegerOnlyFormatter extends TextInputFormatter {
  const _IntegerOnlyFormatter({this.max, this.min});

  final int? min;

  final int? max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue newValue,
    TextEditingValue oldValue,
  ) {
    String newText = newValue.text;
    if (newText.isEmpty) {
      return newValue;
    }
    final negate = newText.startsWith('-');
    if (negate) {
      newText = newText.substring(1);
    }
    int? value = int.tryParse(newText);
    if (value == null) {
      return negate
          ? const TextEditingValue(
              selection: TextSelection.collapsed(offset: 1),
              text: '-',
            )
          : oldValue;
    }
    if (min != null && value <= min!) {
      value = min;
    }
    if (max != null && value >= max!) {
      value = max;
    }
    newText = value?.toString();
    if (negate) {
      newText = '-$newText';
    }

    return TextEditingValue(
      selection: contraintToNewText(newValue, newText),
      text: newText,
    );
  }
}

class _DoubleOnlyFormatter extends TextInputFormatter {
  const _DoubleOnlyFormatter({this.decimalDigits, this.max, this.min});

  final double? min;
  final double? max;

  final int? decimalDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue newValue,
    TextEditingValue oldValue,
  ) {
    String newText = newValue.text;
    if (newText.isEmpty) {
      return newValue;
    }
    final negate = newText.startsWith('-');
    if (negate) {
      newText = newText.substring(1);
    }
    bool endsWithDot = newText.endsWith('.');
    if (endsWithDot) {
      newText = newText.substring(0, newText.length - 1);
    }
    double? value = double.tryParse(newText);
    if (value == null) {
      return negate
          ? const TextEditingValue(
              selection: TextSelection.collapsed(offset: 1),
              text: '-',
            )
          : oldValue;
    }
    if (min != null && value <= min!) {
      value = min;
      endsWithDot = false;
    }
    if (max != null && value >= max!) {
      value = max;
      endsWithDot = false;
    }
    newText = decimalDigits == null
        ? value.toStringAsFixed(decimalDigits!)
        : value?.toString();
    if (newText.contains('.')) {
      while (newText.endsWith('0')) {
        newText = newText.substring(0, newText.length - 1);
      }
      if (newText.endsWith('.')) {
        newText = newText.substring(0, newText.length - 1);
      }
    }
    if (endsWithDot) {
      newText += '.';
    }
    if (negate) {
      newText = '-$newText';
    }

    return TextEditingValue(
      selection: contraintToNewText(newValue, newText),
      text: newText,
    );
  }
}

class _MathExpressionFormatter extends TextInputFormatter {
  const _MathExpressionFormatter({this.context});
  final Map<String, dynamic>? context;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue newValue,
    TextEditingValue oldValue,
  ) {
    final newText = newValue.text;
    Object? result;
    try {
      final expression = Expression.parse(newText);
      const evaluator = ExpressionEvaluator();
      result = evaluator.eval(expression, context ?? {});
      if (result is! num) {
        result = '';
      }
    } catch (e) {
      result = '';
    }
    String resultText = result?.toString();
    if (resultText.contains('.')) {
      while (resultText.endsWith('0')) {
        resultText = resultText.substring(0, resultText.length - 1);
      }
      if (resultText.endsWith('.')) {
        resultText = resultText.substring(0, resultText.length - 1);
      }
    }

    return TextEditingValue(
      selection: contraintToNewText(newValue, resultText),
      text: resultText,
    );
  }
}

class _ToUpperCaseTextFormatter extends TextInputFormatter {
  const _ToUpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue newValue,
    TextEditingValue oldValue,
  ) {
    return TextEditingValue(
      selection: newValue.selection,
      text: newValue.text.toUpperCase(),
    );
  }
}

class _ToLowerCaseTextFormatter extends TextInputFormatter {
  const _ToLowerCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue newValue,
    TextEditingValue oldValue,
  ) {
    return TextEditingValue(
      selection: newValue.selection,
      text: newValue.text.toLowerCase(),
    );
  }
}
