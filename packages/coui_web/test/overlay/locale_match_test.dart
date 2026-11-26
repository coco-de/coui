import 'package:coui_web/src/overlay/locale_match.dart';
import 'package:test/test.dart';

void main() {
  group('matchLocale', () {
    const supported = ['en-US', 'ko', 'ja-JP'];

    test('exact language + region match wins', () {
      expect(matchLocale(['en-US'], supported), equals('en-US'));
      expect(matchLocale(['ja-JP'], supported), equals('ja-JP'));
    });

    test('falls back to a language-only match', () {
      // en-GB → no exact, en language → en-US.
      expect(matchLocale(['en-GB'], supported), equals('en-US'));
      // ko-KR → ko.
      expect(matchLocale(['ko-KR'], supported), equals('ko'));
    });

    test('honours browser preference priority order', () {
      expect(matchLocale(['ko', 'en-US'], supported), equals('ko'));
      expect(matchLocale(['fr', 'en-US'], supported), equals('en-US'));
    });

    test('preserves the supported entry casing/region', () {
      expect(matchLocale(['EN-us'], supported), equals('en-US'));
    });

    test('returns null when nothing matches or lists are empty', () {
      expect(matchLocale(['fr', 'de'], supported), isNull);
      expect(matchLocale(['en-US'], const []), isNull);
      expect(matchLocale(const [], supported), isNull);
    });
  });
}
