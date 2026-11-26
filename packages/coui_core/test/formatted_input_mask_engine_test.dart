// Tests for CoreFormattedInputMaskEngine — the single-field AsYouType
// masking algorithm that replaces the old N-segment-TextField rendering.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

CoreFormattedInputEditResult _apply(
  List<CoreFormattedInputPart> parts,
  String oldText,
  int oldCursor,
  String newText,
  int newCursor,
) {
  return CoreFormattedInputMaskEngine.apply(
    parts: parts,
    oldValue: CoreFormattedInputEditValue(
      text: oldText,
      selectionStart: oldCursor,
      selectionEnd: oldCursor,
    ),
    newValue: CoreFormattedInputEditValue(
      text: newText,
      selectionStart: newCursor,
      selectionEnd: newCursor,
    ),
  );
}

void main() {
  group('CoreFormattedInputMaskEngine.format', () {
    test('empty raw value produces empty text', () {
      expect(
        CoreFormattedInputMaskEngine.format(CoreFormattedInputMasks.phone, ''),
        '',
      );
    });

    test('stops before any literal the next digit has not reached yet', () {
      expect(
        CoreFormattedInputMaskEngine.format(CoreFormattedInputMasks.phone, '3'),
        '(3',
      );
      expect(
        CoreFormattedInputMaskEngine.format(
          CoreFormattedInputMasks.phone,
          '333',
        ),
        '(333',
      );
    });

    test('emits a literal the instant the next digit is placed', () {
      expect(
        CoreFormattedInputMaskEngine.format(
          CoreFormattedInputMasks.phone,
          '3334',
        ),
        '(333) 4',
      );
    });

    test('fully formats a complete phone number', () {
      expect(
        CoreFormattedInputMaskEngine.format(
          CoreFormattedInputMasks.phone,
          '3334567890',
        ),
        '(333) 456-7890',
      );
    });

    test('formats the Korean mobile preset as 3-4-4', () {
      expect(
        CoreFormattedInputMaskEngine.format(
          CoreFormattedInputMasks.koreanPhone,
          '01012345678',
        ),
        '010-1234-5678',
      );
    });
  });

  group('CoreFormattedInputMaskEngine.apply — insertion', () {
    test('typing the first digit into an empty field', () {
      const newText = '0';
      final result = _apply(
        CoreFormattedInputMasks.koreanPhone,
        '',
        0,
        newText,
        newText.length,
      );
      expect(result.text, '0');
      expect(result.rawValue, '0');
      expect(result.cursorOffset, newText.length);
    });

    test('typing past a group boundary auto-inserts the literal', () {
      // Group 1 is already full ("010"); typing one more digit is what
      // triggers the '-' to appear — a literal is never shown ahead of
      // the digit that earns it.
      const oldText = '010';
      const newText = '0101';
      const expectedText = '010-1';
      final result = _apply(
        CoreFormattedInputMasks.koreanPhone,
        oldText,
        oldText.length,
        newText,
        newText.length,
      );
      expect(result.text, expectedText);
      expect(result.rawValue, newText);
      // Right after the newly-typed '1', including the auto-inserted '-'.
      expect(result.cursorOffset, expectedText.length);
    });

    test('pasting a full raw digit string at once', () {
      const newText = '01012345678';
      const expectedText = '010-1234-5678';
      final result = _apply(
        CoreFormattedInputMasks.koreanPhone,
        '',
        0,
        newText,
        newText.length,
      );
      expect(result.text, expectedText);
      expect(result.rawValue, newText);
      expect(result.cursorOffset, expectedText.length);
    });

    test('pasting more digits than the mask can hold drops the overflow', () {
      const newText = '010123456789999';
      const expectedRaw = '01012345678'; // 11-digit capacity, excess dropped
      final result = _apply(
        CoreFormattedInputMasks.koreanPhone,
        '',
        0,
        newText,
        newText.length,
      );
      expect(result.rawValue, expectedRaw);
      expect(result.text, '010-1234-5678');
    });

    test('typing a non-matching character is silently dropped', () {
      // User typed 'a' into a digits-only slot — the OS still inserted the
      // raw character into newValue.text before our formatter ran.
      const oldText = '01';
      const newText = '01a';
      final result = _apply(
        CoreFormattedInputMasks.koreanPhone,
        oldText,
        oldText.length,
        newText,
        newText.length,
      );
      expect(result.rawValue, oldText);
      expect(result.text, oldText);
      expect(result.cursorOffset, oldText.length);
    });
  });

  group('CoreFormattedInputMaskEngine.apply — plain digit backspace', () {
    test(
      'backspacing the last digit removes it and keeps the cursor at the end',
      () {
        // "010-1234-567" + Backspace on trailing '7' (a digit, not a
        // literal) — a plain one-fewer-digit edit, no boundary crossed.
        const oldText = '010-1234-567';
        const newText = '010-1234-56';
        final result = _apply(
          CoreFormattedInputMasks.koreanPhone,
          oldText,
          oldText.length,
          newText,
          newText.length,
        );
        expect(result.rawValue, '010123456');
        expect(result.text, newText);
        expect(result.cursorOffset, result.text.length);
      },
    );
  });

  group(
    'CoreFormattedInputMaskEngine.apply — literal-boundary backspace (DDR-05)',
    () {
      test(
        'backspace right after the first hyphen deletes the preceding '
        'digit, not the hyphen',
        () {
          // Full value "010-1234" (7 raw digits), cursor placed right
          // after the '-'. Backspace removes the character immediately
          // before the cursor at the OS level — the '-' itself — giving
          // "0101234" with the cursor one position earlier.
          const oldText = '010-1234';
          final oldCursor = oldText.indexOf('-') + 1;
          final newText = oldText.replaceFirst('-', '');
          final newCursor = oldCursor - 1;
          final result = _apply(
            CoreFormattedInputMasks.koreanPhone,
            oldText,
            oldCursor,
            newText,
            newCursor,
          );
          // The raw digit stream must still lose exactly one digit (the
          // last digit of the first group), reflowing the next group's
          // first digit up to refill it — never a no-op backspace.
          expect(result.rawValue, '011234');
          expect(result.text, '011-234');
        },
      );

      test(
        'backspace right after the closing paren+space of the phone preset',
        () {
          // "(333) 456-7890" with the cursor right after ") ". The OS
          // removes the space character; the digit stream must still
          // shrink by one (the last digit of the first group).
          const oldText = '(333) 456-7890';
          final oldCursor = oldText.indexOf(' ') + 1;
          final newText = oldText.replaceFirst(' ', '');
          final newCursor = oldCursor - 1;
          final result = _apply(
            CoreFormattedInputMasks.phone,
            oldText,
            oldCursor,
            newText,
            newCursor,
          );
          expect(result.rawValue, '334567890');
          expect(result.text, '(334) 567-890');
        },
      );

      test('backspace on an empty field is a no-op, not a crash', () {
        final result = _apply(
          CoreFormattedInputMasks.koreanPhone,
          '',
          0,
          '',
          0,
        );
        expect(result.rawValue, '');
        expect(result.text, '');
        expect(result.cursorOffset, 0);
      });
    },
  );

  group('CoreFormattedInputMaskEngine.apply — range deletion', () {
    test('deleting a selected middle chunk reflows the remaining digits', () {
      // "(333) 456-7890" — select "456" and delete it in one action.
      const oldText = '(333) 456-7890';
      const newText = '(333) -7890';
      final result = _apply(
        CoreFormattedInputMasks.phone,
        oldText,
        oldText.indexOf(' ') + 1, // unused on this path (range delete)
        newText,
        newText.indexOf('-'), // where the deleted "456" used to start
      );
      expect(result.rawValue, '3337890');
      expect(result.text, '(333) 789-0');
    });
  });

  group(
    'CoreFormattedInputMaskEngine.apply — heterogeneous per-slot patterns',
    () {
      const mask = [
        CoreFormattedInputPart.editable(length: 2, pattern: '[A-Z]'),
        CoreFormattedInputPart.static('-'),
        CoreFormattedInputPart.editable(length: 4, pattern: r'\d'),
      ];

      test('each slot only accepts its own pattern', () {
        const newText = 'AB1234';
        final result = _apply(mask, '', 0, newText, newText.length);
        expect(result.rawValue, 'AB1234');
        expect(result.text, 'AB-1234');
      });

      test('characters that match no slot pattern are dropped', () {
        const newText = 'A!B12#34';
        final result = _apply(mask, '', 0, newText, newText.length);
        expect(result.rawValue, 'AB1234');
        expect(result.text, 'AB-1234');
      });
    },
  );
}
