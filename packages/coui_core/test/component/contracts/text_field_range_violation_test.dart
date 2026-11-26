// The shared min / max verdict both platforms read.
//
// `min` / `max` used to be Web-only: the Web widget emitted them as
// `<input min max>` and the browser did the rest, while Flutter declared
// the same two fields and read neither. Same code, one platform showing a
// constraint and the other showing nothing.
//
// The cases below pin the shape of the verdict rather than the chrome —
// in particular the two that are easy to get wrong in the direction of
// "helpfully" reporting more:
//
//   - text that does not parse is *not* a range violation. The browser
//     files that under `badInput`, and a field showing the range error
//     for `abc` would be lying about which rule was broken.
//   - an absent bound does not constrain. A `min`-only field has no
//     ceiling, and vice versa.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreTextFieldContract.isRangeViolation', () {
    test('unbounded text never violates', () {
      expect(CoreTextFieldContract.isRangeViolation('99'), isFalse);
    });

    test('empty text is unconstrained', () {
      expect(
        CoreTextFieldContract.isRangeViolation('', min: 0, max: 10),
        isFalse,
      );
      expect(
        CoreTextFieldContract.isRangeViolation('   ', min: 0, max: 10),
        isFalse,
      );
    });

    test('a value above max violates', () {
      expect(
        CoreTextFieldContract.isRangeViolation('99', min: 0, max: 10),
        isTrue,
      );
    });

    test('a value below min violates', () {
      expect(
        CoreTextFieldContract.isRangeViolation('-1', min: 0, max: 10),
        isTrue,
      );
    });

    test('the bounds themselves are inclusive', () {
      expect(
        CoreTextFieldContract.isRangeViolation('0', min: 0, max: 10),
        isFalse,
      );
      expect(
        CoreTextFieldContract.isRangeViolation('10', min: 0, max: 10),
        isFalse,
      );
    });

    test('a half-open range only constrains the side it names', () {
      expect(CoreTextFieldContract.isRangeViolation('99', min: 0), isFalse);
      expect(CoreTextFieldContract.isRangeViolation('-1', min: 0), isTrue);
      expect(CoreTextFieldContract.isRangeViolation('-99', max: 10), isFalse);
      expect(CoreTextFieldContract.isRangeViolation('11', max: 10), isTrue);
    });

    test('unparseable text is badInput, not a range violation', () {
      expect(
        CoreTextFieldContract.isRangeViolation('abc', min: 0, max: 10),
        isFalse,
      );
    });

    test('fractional values are compared, not truncated', () {
      expect(
        CoreTextFieldContract.isRangeViolation('10.5', min: 0, max: 10),
        isTrue,
      );
      expect(
        CoreTextFieldContract.isRangeViolation('9.5', min: 0, max: 10),
        isFalse,
      );
    });
  });
}
