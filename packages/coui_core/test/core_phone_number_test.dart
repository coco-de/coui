// Pins the shared phone-number read semantics.
//
// Both platforms derive their reported value through
// `CorePhoneNumber.fromInput`, so these expectations are the single
// description of what the field text means. A platform that hand-copied the
// chain could drift silently; a change here fails for both at once.
//
// ## What changed, and why the old expectations are gone
//
// This used to strip three things: a typed `+<dialCode>`, a leading `0`, and
// a dial code written without its plus. The last two are guesses about what
// the remaining digits mean, and the `GB and IT` case below is why no single
// guess works — the two inputs are the same shape, and the dial code carries
// no trunk semantics to tell them apart:
//
//   GB  07911123456  trunk 0 is dropped in E.164   -> +447911123456
//   IT  0612345678   trunk 0 is PART of the number -> +390612345678
//
// Stripping serves GB and corrupts IT; not stripping serves IT and corrupts
// GB. Telling them apart needs a per-territory national-prefix table that
// neither `CoreCountry` (code / dialCode / name) nor its upstream dataset
// carries. So the rule is now: read what was typed, strip only the dial code
// the typist actually wrote, guess nothing.
//
// The consequence is deliberate and is the behaviour change this file
// records: a GB caller who types `07911123456` gets `+4407911123456`, not
// `+447911123456`. That is what they typed. To have the dial code removed
// they type it.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kIndonesia = CoreCountry(
  code: 'ID',
  dialCode: '+62',
  name: 'Indonesia',
);
const _kUnitedKingdom = CoreCountry(
  code: 'GB',
  dialCode: '+44',
  name: 'United Kingdom',
);
const _kItaly = CoreCountry(code: 'IT', dialCode: '+39', name: 'Italy');

/// Reads [text] the way both platforms ship.
String _national(CoreCountry country, String text) =>
    CorePhoneNumber.fromInput(country, text).number;

/// The full E.164-shaped value both platforms hand to callers.
String _full(CoreCountry country, String text) =>
    CorePhoneNumber.fromInput(country, text).fullNumber;

void main() {
  group('CorePhoneNumber.fromInput', () {
    test('drops a typed +dialCode that matches the country', () {
      expect(_national(.unitedStates, '+15551234567'), '5551234567');
      expect(_national(_kIndonesia, '+628123456788'), '8123456788');
    });

    test('keeps a + that is not this country dial code', () {
      // Previously the bare `+` was eaten, turning a mistyped number into a
      // plausible-looking wrong one. Leaving it makes the mistake visible.
      expect(_national(.unitedStates, '+445551234'), '+445551234');
    });

    test('keeps a leading trunk zero', () {
      expect(_national(_kIndonesia, '08123456788'), '08123456788');
      expect(_national(_kIndonesia, '008123456788'), '008123456788');
    });

    test('keeps a dial code written without its plus', () {
      // `+62` was matched by prefix without the plus, so this used to become
      // `8123456788` — and, for `+1`, every US number starting with 1 lost
      // that digit.
      expect(_national(_kIndonesia, '628123456788'), '628123456788');
      expect(_national(.unitedStates, '15551234567'), '15551234567');
    });

    test('GB and IT are both read faithfully', () {
      // The case the whole rule exists for. Neither is guessed at: each
      // carries exactly what was typed, so neither is silently corrupted.
      expect(_full(_kUnitedKingdom, '07911123456'), '+4407911123456');
      expect(_full(_kItaly, '0612345678'), '+390612345678');

      // And when the dial code IS typed, both agree — this is the form that
      // was always unambiguous.
      expect(_full(_kUnitedKingdom, '+447911123456'), '+447911123456');
      expect(_full(_kItaly, '+390612345678'), '+390612345678');
    });

    test('strips at most the dial code, never twice', () {
      expect(_national(_kIndonesia, '+6208123456788'), '08123456788');
    });

    test('leaves text that carries no dial code alone', () {
      expect(_national(.unitedStates, '5551234567'), '5551234567');
      expect(_national(.unitedStates, ''), '');
    });

    test('filterPlusCode: false keeps the dial code too', () {
      expect(
        CorePhoneNumber.fromInput(
          .unitedStates,
          '+15551234567',
          filterPlusCode: false,
        ).number,
        '+15551234567',
      );
    });

    test('re-reading the same text under a new country re-interprets it', () {
      // The reason reading happens on read: the same field text means a
      // different national number once the caller picks another country.
      const typed = '+628123456788';

      expect(_national(.unitedStates, typed), typed);
      expect(_national(_kIndonesia, typed), '8123456788');
    });
  });

  group('CorePhoneNumber value semantics', () {
    test('exposes the carried country through code / dialCode', () {
      const phone = CorePhoneNumber(_kIndonesia, '8123456788');

      expect(phone.countryCode, 'ID');
      expect(phone.dialCode, '+62');
      expect(phone.fullNumber, '+628123456788');
      expect(phone.value, '+628123456788');
      expect(phone.toString(), '+628123456788');
    });

    test('an empty number has no value', () {
      const phone = CorePhoneNumber(_kIndonesia, '');

      expect(phone.value, isNull);
      expect(phone.toString(), '');
    });

    test('equality covers country and number', () {
      const a = CorePhoneNumber(_kIndonesia, '8123456788');
      const b = CorePhoneNumber(_kIndonesia, '8123456788');
      const otherCountry = CorePhoneNumber(.unitedStates, '8123456788');
      const otherNumber = CorePhoneNumber(_kIndonesia, '9123456788');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(otherCountry));
      expect(a, isNot(otherNumber));
    });
  });
}
