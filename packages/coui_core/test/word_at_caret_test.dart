import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('getWordAtCaret', () {
    test('returns the word the caret sits at the end of', () {
      expect(getWordAtCaret(10, 'I like App'), equals((7, 'App')));
    });

    test('returns the word the caret sits inside', () {
      expect(getWordAtCaret(8, 'I like App now'), equals((7, 'App')));
    });

    test('returns the word the caret sits at the start of', () {
      expect(getWordAtCaret(7, 'I like App now'), equals((7, 'App')));
    });

    test('returns the whole text when there are no separators', () {
      expect(getWordAtCaret(3, 'Apple'), equals((0, 'Apple')));
    });

    test('returns an empty word between two separators', () {
      // Two spaces: the caret sits in the gap and owns nothing.
      expect(getWordAtCaret(2, 'a  b'), equals((2, '')));
    });

    test('returns an empty word for empty text', () {
      expect(getWordAtCaret(0, ''), equals((0, '')));
    });

    test('handles a caret at the very end of the text', () {
      expect(getWordAtCaret(5, 'Apple'), equals((0, 'Apple')));
    });

    test('honours a custom separator set', () {
      // Every character in the set terminates a word.
      expect(getWordAtCaret(4, 'a,b;cd', ',;'), equals((4, 'cd')));
    });

    test('rejects a caret past the end', () {
      expect(() => getWordAtCaret(6, 'Apple'), throwsRangeError);
    });

    test('rejects a negative caret', () {
      expect(() => getWordAtCaret(-1, 'Apple'), throwsRangeError);
    });
  });

  group('replaceWordAtCaret', () {
    test('replaces only the word under the caret', () {
      expect(
        replaceWordAtCaret(10, 'Apple', 'I like App'),
        equals((7, 'I like Apple')),
      );
    });

    test('keeps the text that follows the replaced word', () {
      // The case that separates `replaceWord` from `replaceAll`: the tail
      // must survive.
      expect(
        replaceWordAtCaret(10, 'Apple', 'I like App now'),
        equals((7, 'I like Apple now')),
      );
    });

    test('replaces the first word without touching the rest', () {
      expect(
        replaceWordAtCaret(1, 'Apple', 'Ap is good'),
        equals((0, 'Apple is good')),
      );
    });

    test('inserts at an empty gap between separators', () {
      expect(replaceWordAtCaret(2, 'X', 'a  b'), equals((2, 'a X b')));
    });

    test('inserts into empty text', () {
      expect(replaceWordAtCaret(0, 'Apple', ''), equals((0, 'Apple')));
    });

    test('reports a start offset that positions the caret after the word', () {
      final (start, text) = replaceWordAtCaret(10, 'Apple', 'I like App now');
      // The caller places the caret here; it must land just past the
      // inserted word rather than at the end of the whole field.
      expect(start + 'Apple'.length, equals(12));
      expect(text.substring(0, 12), equals('I like Apple'));
    });

    test('honours a custom separator set', () {
      expect(replaceWordAtCaret(4, 'Z', 'a,b;cd', ',;'), equals((4, 'a,b;Z')));
    });

    test('rejects a caret outside the text', () {
      expect(() => replaceWordAtCaret(6, 'X', 'Apple'), throwsRangeError);
      expect(() => replaceWordAtCaret(-1, 'X', 'Apple'), throwsRangeError);
    });
  });
}
