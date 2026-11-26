// Pins the const country entries and the phone input's default country to
// the shared dataset, so a hand-written const cannot drift from the entry
// both platforms list.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreCountry consts', () {
    test('southKorea is the KR entry of the dataset', () {
      expect(CoreCountry.byCode('KR'), CoreCountry.southKorea);
    });

    test('unitedStates is the US entry of the dataset', () {
      expect(CoreCountry.byCode('US'), CoreCountry.unitedStates);
    });
  });

  group('CorePhoneInputContract.defaultInitialCountry (#6471)', () {
    test('is South Korea (+82)', () {
      const country = CorePhoneInputContract.defaultInitialCountry;
      expect(country.code, 'KR');
      expect(country.dialCode, '+82');
    });
  });
}
