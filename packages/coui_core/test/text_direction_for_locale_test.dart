import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('a language is read in the direction it is written', () {
    test('right-to-left languages', () {
      for (final code in ['ar', 'he', 'fa', 'ur']) {
        expect(
          CoreTextDirectionForLocale.of(code),
          CoreTextDirection.rtl,
          reason: '$code should be right-to-left',
        );
      }
    });

    test('everything else', () {
      for (final code in ['en', 'ko', 'de', 'fi', 'ja']) {
        expect(
          CoreTextDirectionForLocale.of(code),
          CoreTextDirection.ltr,
          reason: '$code should be left-to-right',
        );
      }
    });
  });

  group('the region does not decide it', () {
    test('a full tag resolves on its language', () {
      // Direction is a property of the language. `ar-EG` and `ar` are
      // the same answer, and a tag that arrived with an underscore
      // instead of a hyphen is the same answer again.
      expect(CoreTextDirectionForLocale.of('ar-EG'), CoreTextDirection.rtl);
      expect(CoreTextDirectionForLocale.of('ar_EG'), CoreTextDirection.rtl);
      expect(CoreTextDirectionForLocale.of('en-GB'), CoreTextDirection.ltr);
    });

    test('except where the region is what makes it right-to-left', () {
      // Uzbek is written left-to-right in Uzbekistan and right-to-left
      // in Afghanistan. Cutting the tag at the language would get this
      // one wrong in the direction that matters.
      expect(CoreTextDirectionForLocale.of('uz'), CoreTextDirection.ltr);
      expect(CoreTextDirectionForLocale.of('uz-AF'), CoreTextDirection.rtl);
    });
  });

  group('an unknown language reads left-to-right', () {
    test('rather than disappearing', () {
      // The listed set is the right-to-left one because it is the
      // closed one. A language nobody listed gets the common answer
      // instead of no answer.
      expect(CoreTextDirectionForLocale.of('zzz'), CoreTextDirection.ltr);
      expect(CoreTextDirectionForLocale.of(''), CoreTextDirection.ltr);
    });
  });
}
