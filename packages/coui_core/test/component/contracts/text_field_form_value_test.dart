// The value a text field reports to an enclosing `FormField`.
//
// Flutter and Web both read it from `CoreTextFieldContract.formValueOf`, so
// a blank field is the same answer on each — a rule two platforms copied by
// hand is one they eventually disagree on. What each platform does with it
// (mount, every change, a `ReplaceResult`) is pinned in its own widget tests.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreTextFieldContract.formValueOf', () {
    test('empty text is no value, not the empty string', () {
      expect(CoreTextFieldContract.formValueOf(''), isNull);
    });

    test('any text is itself', () {
      expect(CoreTextFieldContract.formValueOf('Ada'), 'Ada');
    });

    test("whitespace is text — trimming is a validator's call, not the "
        "field's", () {
      expect(CoreTextFieldContract.formValueOf(' '), ' ');
      expect(CoreTextFieldContract.formValueOf('  hi  '), '  hi  ');
    });
  });
}
