// Pins `CorePhoneCountryDetector.detect` — the single, platform-neutral
// implementation both `PhoneInput` widgets call so typing detection can't
// hand-drift between Flutter and Web.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CorePhoneCountryDetector.detect', () {
    test('matches a unique dial code (+82 -> South Korea)', () {
      final detected = CorePhoneCountryDetector.detect(
        '+821012345678',
        CoreCountry.all,
      );

      expect(detected?.code, 'KR');
    });

    test('a duplicated dial code is ambiguous (+7 -> null)', () {
      // Kazakhstan and Russia both dial +7 in the shared dataset — no
      // tie-break table is built, so this is treated like no match.
      final detected = CorePhoneCountryDetector.detect(
        '+71234567890',
        CoreCountry.all,
      );

      expect(detected, isNull);
    });

    test('+1 is shared by the US and Canada, so it is ambiguous (null)', () {
      // The single most common ambiguity — the selection the typist already
      // has (US or CA) stays put rather than being flipped to whichever row
      // the dataset happens to list first.
      final detected = CorePhoneCountryDetector.detect(
        '+15551234567',
        CoreCountry.all,
      );

      expect(detected, isNull);
    });

    test('text without a leading + never detects (null)', () {
      final detected = CorePhoneCountryDetector.detect(
        '821012345678',
        CoreCountry.all,
      );

      expect(detected, isNull);
    });

    test('a partial dial code with no exact match is null (+8)', () {
      final detected = CorePhoneCountryDetector.detect('+8', CoreCountry.all);

      expect(detected, isNull);
    });

    test('longest-prefix match resolves a country whose dial code '
        'extends another (+1242 -> Bahamas, not US/CA)', () {
      final detected = CorePhoneCountryDetector.detect(
        '+12425551234',
        CoreCountry.all,
      );

      expect(detected?.code, 'BS');
    });

    test('detection is scoped to the supplied countries list', () {
      const korea = CoreCountry(code: 'KR', dialCode: '+82', name: 'Korea');

      final detected = CorePhoneCountryDetector.detect(
        '+821012345678',
        const [korea],
      );

      expect(detected, korea);

      final outOfScope = CorePhoneCountryDetector.detect(
        '+441234567890',
        const [korea],
      );

      expect(outOfScope, isNull);
    });

    test('an empty match set is null', () {
      final detected = CorePhoneCountryDetector.detect(
        '+821012345678',
        const [],
      );

      expect(detected, isNull);
    });
  });
}
