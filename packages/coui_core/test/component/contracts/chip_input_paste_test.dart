// The shared paste-to-chips rule both platforms run.
//
// Neither platform had a paste hook at all: Flutter committed the whole
// buffer as one value and had no interception anywhere in
// `form/chip_input/`, and Web bound only `keydown`, so pasted text sat in
// the buffer waiting for an Enter the user still had to press. A caller's
// only recourse was post-processing inside `onSubmitted`, which cannot
// run at paste time.
//
// Splitting, trimming, empty-dropping and the `maxChips` cap live here
// rather than twice, so the two platforms cannot drift into disagreeing
// about what `a,,b` or an already-full field means.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

List<String> _commaSplit(String pasted) => pasted.split(',');

void main() {
  group('CoreChipInputContract.chipsAfterPaste', () {
    test('splits a separated paste into several chips', () {
      expect(
        CoreChipInputContract.chipsAfterPaste(
          existing: const [],
          pasted: 'a,b,c',
          splitter: _commaSplit,
        ),
        equals(['a', 'b', 'c']),
      );
    });

    test('appends to the chips already there', () {
      expect(
        CoreChipInputContract.chipsAfterPaste(
          existing: const ['x'],
          pasted: 'a,b',
          splitter: _commaSplit,
        ),
        equals(['x', 'a', 'b']),
      );
    });

    test('trims each value and drops the empties', () {
      expect(
        CoreChipInputContract.chipsAfterPaste(
          existing: const [],
          pasted: ' a , , b ,   ',
          splitter: _commaSplit,
        ),
        equals(['a', 'b']),
      );
    });

    test('text with no separator becomes one chip', () {
      expect(
        CoreChipInputContract.chipsAfterPaste(
          existing: const [],
          pasted: 'solo',
          splitter: _commaSplit,
        ),
        equals(['solo']),
      );
    });

    test('maxChips caps the result', () {
      expect(
        CoreChipInputContract.chipsAfterPaste(
          existing: const ['x'],
          pasted: 'a,b,c',
          splitter: _commaSplit,
          maxChips: 3,
        ),
        equals(['x', 'a', 'b']),
      );
    });

    test('a full field takes nothing and reports no change', () {
      const existing = ['x', 'y'];
      expect(
        CoreChipInputContract.chipsAfterPaste(
          existing: existing,
          pasted: 'a,b',
          splitter: _commaSplit,
          maxChips: 2,
        ),
        same(existing),
        reason: 'identity lets a caller skip notifying on a no-op paste',
      );
    });

    test('an all-blank paste reports no change', () {
      const existing = ['x'];
      expect(
        CoreChipInputContract.chipsAfterPaste(
          existing: existing,
          pasted: ' , , ',
          splitter: _commaSplit,
        ),
        same(existing),
      );
    });
  });

  group('CoreChipInputContract splitters', () {
    test('splitOn cuts on the given pattern', () {
      expect(
        CoreChipInputContract.splitOn(';')('a;b'),
        equals(['a', 'b']),
      );
    });

    test('splitOnCommonSeparators covers comma, semicolon, tab, newline', () {
      expect(
        CoreChipInputContract.chipsAfterPaste(
          existing: const [],
          pasted: 'a,b;c\nd\te',
          splitter: CoreChipInputContract.splitOnCommonSeparators,
        ),
        equals(['a', 'b', 'c', 'd', 'e']),
      );
    });

    test('splitOnCommonSeparators survives CRLF without blank chips', () {
      expect(
        CoreChipInputContract.chipsAfterPaste(
          existing: const [],
          pasted: 'a\r\nb',
          splitter: CoreChipInputContract.splitOnCommonSeparators,
        ),
        equals(['a', 'b']),
        reason: 'CR and LF both split, so the gap between them is empty',
      );
    });
  });
}
