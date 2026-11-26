import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kbdKeysFromActivator', () {
    test('a plain shortcut is its modifiers then its key', () {
      expect(
        kbdKeysFromActivator(
          const SingleActivator(LogicalKeyboardKey.keyS, control: true),
        ),
        ['Ctrl', 'S'],
      );
    });

    test('modifiers follow Apple HIG order — Ctrl, Alt, Shift, ⌘', () {
      expect(
        kbdKeysFromActivator(
          const SingleActivator(
            LogicalKeyboardKey.keyK,
            meta: true,
            shift: true,
            alt: true,
            control: true,
          ),
        ),
        ['Ctrl', 'Alt', 'Shift', '⌘', 'K'],
      );
    });

    test('Shift comes before ⌘, not after it', () {
      expect(
        kbdKeysFromActivator(
          const SingleActivator(
            LogicalKeyboardKey.keyF,
            meta: true,
            shift: true,
          ),
        ),
        ['Shift', '⌘', 'F'],
      );
    });

    test('a character activator is upper-cased after its modifiers', () {
      expect(
        kbdKeysFromActivator(
          const CharacterActivator('s', control: true, alt: true),
        ),
        ['Ctrl', 'Alt', 'S'],
      );
    });

    test('named triggers use their glyph', () {
      expect(
        kbdKeysFromActivator(const SingleActivator(LogicalKeyboardKey.enter)),
        ['↵'],
      );
      expect(
        kbdKeysFromActivator(
          const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true),
        ),
        ['Shift', '↑'],
      );
    });

    test(
      'a key set is ordered the same way whatever order it was built in',
      () {
        final a = kbdKeysFromActivator(
          LogicalKeySet(
            LogicalKeyboardKey.metaLeft,
            LogicalKeyboardKey.keyP,
            LogicalKeyboardKey.shiftLeft,
          ),
        );
        final b = kbdKeysFromActivator(
          LogicalKeySet(
            LogicalKeyboardKey.shiftRight,
            LogicalKeyboardKey.metaRight,
            LogicalKeyboardKey.keyP,
          ),
        );

        expect(a, ['Shift', '⌘', 'P']);
        expect(b, a);
      },
    );
  });
}
