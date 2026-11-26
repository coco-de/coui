import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Helper to create a simple TextEditingValue for testing.
TextEditingValue _tv(String text) {
  return TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
}

// Constants for test values.
const _kEmptyString = '';
const _kSimpleAddition = '1+1';
const _kSimpleMultiplication = '2*3';
const _kSimpleDivision = '10/4';
const _kComplexExpression = '2+3*4';
const _kInvalidExpression = 'abc';
const _kPartialExpression = '1+';
const _kDecimalExpression = '1.5+1.5';
const _kNegativeExpression = '-5+2';
const _kResult2 = '2';
const _kResult6 = '6';
const _kResult2point5 = '2.5';
const _kResult14 = '14';
const _kResultNeg3 = '-3';
const _kIntMin = 0;
const _kIntMax = 100;
const _kDecimalDigits = 2;
const _kTimeLength = 4;

void main() {
  group('CoreInputFormatters.mathExpression', () {
    late CoreInputFormatter formatter;

    setUp(() {
      formatter = CoreInputFormatters.mathExpression();
    });

    String format(String input) => formatter.format(_kEmptyString, input);

    test('evaluates simple addition', () {
      expect(format(_kSimpleAddition), equals(_kResult2));
    });

    test('evaluates simple multiplication', () {
      expect(format(_kSimpleMultiplication), equals(_kResult6));
    });

    test('evaluates simple division', () {
      expect(format(_kSimpleDivision), equals(_kResult2point5));
    });

    test('evaluates complex expression respecting operator precedence', () {
      expect(format(_kComplexExpression), equals(_kResult14));
    });

    test('returns empty string for invalid expression', () {
      expect(format(_kInvalidExpression), equals(_kEmptyString));
    });

    test('returns empty string for partial expression', () {
      expect(format(_kPartialExpression), equals(_kEmptyString));
    });

    test('evaluates decimal expression', () {
      expect(format(_kDecimalExpression), equals('3'));
    });

    test('evaluates expression with negative numbers', () {
      expect(format(_kNegativeExpression), equals(_kResultNeg3));
    });

    test('trims trailing zeros from decimal result', () {
      expect(format('1.0+1.0'), equals(_kResult2));
    });

    test('handles empty input', () {
      expect(format(_kEmptyString), equals(_kEmptyString));
    });

    test('can be created with custom context variables', () {
      final ctxFormatter = CoreInputFormatters.mathExpression(
        context: {'x': 5},
      );
      expect(ctxFormatter.format(_kEmptyString, 'x+1'), equals(_kResult6));
    });
  });

  group('CoreInputFormatters.integerOnly', () {
    test('clamps to min and max bounds', () {
      final formatter = CoreInputFormatters.integerOnly(
        max: _kIntMax,
        min: _kIntMin,
      );
      expect(formatter.format('', '150'), equals('100'));
      expect(formatter.format('', '42'), equals('42'));
    });

    test('rejects non-integer input', () {
      final formatter = CoreInputFormatters.integerOnly();
      expect(formatter.format('7', 'abc'), equals('7'));
    });
  });

  group('CoreInputFormatters.integerOnly bounds and sign', () {
    test('a negative entry is clamped against a non-negative minimum', () {
      // The sign used to be stripped before the bound was applied, so
      // `-5` was compared as `5`, passed, and had its `-` put back.
      final formatter = CoreInputFormatters.integerOnly(min: _kIntMin);

      expect(formatter.format('', '-5'), equals('0'));
    });

    test('a lone minus survives when the range admits negatives', () {
      final formatter = CoreInputFormatters.integerOnly(min: -10);

      expect(formatter.format('', '-'), equals('-'));
    });

    test('a lone minus is refused when the range cannot hold one', () {
      final formatter = CoreInputFormatters.integerOnly(min: _kIntMin);

      expect(formatter.format('7', '-'), equals('7'));
    });

    test('negatives inside the range are kept', () {
      final formatter = CoreInputFormatters.integerOnly(max: 100, min: -100);

      expect(formatter.format('', '-42'), equals('-42'));
    });
  });

  group('CoreInputFormatters.decimalOnly', () {
    test('respects decimal digit limit', () {
      final formatter = CoreInputFormatters.decimalOnly(
        decimalDigits: _kDecimalDigits,
      );
      expect(formatter.format('', '3.14159'), equals('3.14'));
    });

    // Typing is a sequence, and each keystroke is fed through the
    // formatter with the whole field as `newValue`. A formatter that
    // rewrites what it is given has to survive every prefix of the
    // number the person is aiming at — the old one did not, because it
    // parsed to a `double` and printed it back, which collapsed `0.00`
    // to `0` and left the next digit nowhere to go.
    test('a small decimal can be typed one character at a time', () {
      final formatter = CoreInputFormatters.decimalOnly();

      var text = '';
      for (final key in ['0', '.', '0', '0', '5']) {
        text = formatter.format(text, '$text$key');
      }

      expect(text, equals('0.005'));
    });

    test('trailing zeros survive while more digits may still follow', () {
      final formatter = CoreInputFormatters.decimalOnly();

      expect(formatter.format('1.1', '1.10'), equals('1.10'));
    });

    test('a fixed decimal width is not immediately unpadded', () {
      // `decimalDigits: 2` padded via `toStringAsFixed` and then trimmed
      // the padding straight back off, so `1.50` could never be held.
      final formatter = CoreInputFormatters.decimalOnly(
        decimalDigits: _kDecimalDigits,
      );

      expect(formatter.format('1.5', '1.50'), equals('1.50'));
    });

    test('a trailing decimal point is not eaten', () {
      final formatter = CoreInputFormatters.decimalOnly();

      expect(formatter.format('0', '0.'), equals('0.'));
    });

    test('a second decimal point is refused', () {
      final formatter = CoreInputFormatters.decimalOnly();

      expect(formatter.format('1.5', '1.5.'), equals('1.5'));
    });

    test('a negative entry is clamped against a non-negative minimum', () {
      final formatter = CoreInputFormatters.decimalOnly(min: 0);

      expect(formatter.format('', '-5'), equals('0'));
    });

    test('clamping to a bound honours the fixed decimal width', () {
      final formatter = CoreInputFormatters.decimalOnly(
        decimalDigits: _kDecimalDigits,
        max: 10,
      );

      expect(formatter.format('', '99'), equals('10.00'));
    });

    test('decimalDigits: 0 refuses a decimal point', () {
      final formatter = CoreInputFormatters.decimalOnly(decimalDigits: 0);

      expect(formatter.format('12', '12.'), equals('12'));
    });
  });

  group('CoreInputFormatters case formatters', () {
    test('toUpperCase converts text', () {
      expect(
        CoreInputFormatters.toUpperCase().format('', 'abc'),
        equals('ABC'),
      );
    });

    test('toLowerCase converts text', () {
      expect(
        CoreInputFormatters.toLowerCase().format('', 'ABC'),
        equals('abc'),
      );
    });
  });

  group('CoreInputFormatters.time', () {
    test('pads with leading zeros', () {
      final formatter = CoreInputFormatters.time(length: _kTimeLength);
      expect(formatter.format('', '12'), equals('0012'));
    });
  });

  group('InputFormatter (Flutter adapter)', () {
    test('preserves caret position after formatting', () {
      const flutterFormatter = InputFormatter(CoreUpperCaseFormatter());
      final result = flutterFormatter.formatEditUpdate(
        _tv(_kEmptyString),
        _tv('hello'),
      );
      expect(result.text, equals('HELLO'));
      expect(
        result.selection.baseOffset,
        lessThanOrEqualTo(result.text.length),
      );
    });
  });

  group('TextInputFormatters factory', () {
    test('integerOnly returns a TextInputFormatter', () {
      expect(
        TextInputFormatters.integerOnly(min: 0),
        isA<TextInputFormatter>(),
      );
    });

    test('mathExpression returns a TextInputFormatter', () {
      expect(
        TextInputFormatters.mathExpression(),
        isA<TextInputFormatter>(),
      );
    });
  });
}
