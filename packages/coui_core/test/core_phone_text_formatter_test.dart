// Pins the phone-entry formatter.
//
// It exists because `CoreAllowPatternFormatter` cannot express "one `+`, and
// only at the front": it tests one character at a time, so `allow(r'[\d+]')`
// accepts `12+34` and `++82` alike. The two whole-string formatters are no
// substitute either — `integerOnly` parses through `int`, which drops the
// sign, and `decimalOnly` erases a lone `+` so it can never be typed.
//
// The typing cases below are the ones that matter. A formatter can look
// correct on pasted whole strings and still be unusable, because the user
// reaches `+8` only by first surviving `+` on its own. That is exactly how
// the decimal formatter's sign became unreachable.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// Feeds [keystrokes] one character at a time, as a text field would.
String _type(CoreInputFormatter formatter, String keystrokes) {
  var value = '';
  for (final rune in keystrokes.runes) {
    value = formatter.format(value, value + String.fromCharCode(rune));
  }

  return value;
}

void main() {
  final formatter = CoreInputFormatters.phoneText();

  group('CorePhoneTextFormatter', () {
    test('keeps digits', () {
      expect(formatter.format('', '5551234567'), '5551234567');
    });

    test('keeps a leading +', () {
      expect(formatter.format('', '+447911123456'), '+447911123456');
    });

    test('drops a + that is not leading', () {
      expect(formatter.format('', '82+10'), '8210');
      expect(formatter.format('', '1+2+3'), '123');
    });

    test('keeps only the first of several +', () {
      expect(formatter.format('', '++82'), '+82');
      expect(formatter.format('', '+8+2'), '+82');
    });

    test('drops everything that is neither a digit nor a leading +', () {
      expect(formatter.format('', '+44 (79) 11-123456'), '+447911123456');
      expect(formatter.format('', 'abc123'), '123');
    });

    test('a + is reachable by typing, not only by pasting', () {
      // The failure mode this formatter had to avoid: erasing a lone `+` on
      // the first keystroke makes the character impossible to enter, because
      // it can never be followed by digits.
      expect(_type(formatter, '+'), '+');
      expect(_type(formatter, '+8'), '+8');
      expect(_type(formatter, '+447911123456'), '+447911123456');
    });

    test('a + typed after digits never lands', () {
      expect(_type(formatter, '82+10'), '8210');
    });

    test('leading noise does not disqualify the + behind it', () {
      // Position is measured among the characters KEPT, not among those
      // typed, so a discarded prefix still leaves the `+` in front. Reading
      // the source index instead would drop the `+` out of pasted forms
      // people actually copy.
      expect(formatter.format('', 'a+82'), '+82');
      expect(formatter.format('', '  +82'), '+82');
      expect(formatter.format('', '(+82) 10'), '+8210');
    });

    test('the existing allow() cannot do this', () {
      // Pins the reason this class exists, so deleting it in favour of
      // `allow` fails here rather than in a phone field.
      expect(CoreInputFormatters.allow(r'[\d+]').format('', '82+10'), '82+10');
    });
  });
}
