// Pins what a Flutter PhoneInput hands its caller as the user types.
//
// The corruption this guards against was on the typing path: every keystroke
// went through `CorePhoneNumber.fromInput`, and the result — not the field
// text — is what `onChanged` reports. So a caller storing that value stored
// the damaged one, with nothing on screen to show it.
//
// `reports GB and IT faithfully` is the case the whole rule exists for. The
// two inputs are the same shape (`0` + digits) and differ only in the country;
// the dial code carries nothing that could tell them apart. Any rule that
// reaches inside a bare `0…` is right for one and wrong for the other.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _kUnitedKingdom = CoreCountry(
  code: 'GB',
  dialCode: '+44',
  name: 'United Kingdom',
);
const _kItaly = CoreCountry(code: 'IT', dialCode: '+39', name: 'Italy');
const _kKorea = CoreCountry(code: 'KR', dialCode: '+82', name: 'Korea');

Widget _app(Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

/// Types [text] into a `PhoneInput` for [country] and returns what the
/// caller was handed.
Future<PhoneNumber?> _typed(
  WidgetTester tester,
  CoreCountry country,
  String text,
) async {
  PhoneNumber? reported;
  await tester.pumpWidget(
    _app(
      PhoneInput(
        initialCountry: country,
        onChanged: (value) => reported = value,
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(EditableText), text);
  await tester.pumpAndSettle();

  return reported;
}

void main() {
  group('PhoneInput reading', () {
    testWidgets('reports GB and IT faithfully', (tester) async {
      // Neither is guessed at, so neither is silently corrupted. Stripping
      // the 0 would serve GB and damage IT; keeping it does the reverse.
      expect(
        (await _typed(tester, _kUnitedKingdom, '07911123456'))?.fullNumber,
        '+4407911123456',
      );
      expect(
        (await _typed(tester, _kItaly, '0612345678'))?.fullNumber,
        '+390612345678',
      );
    });

    testWidgets('a typed dial code is removed', (tester) async {
      // The one removal that is not a guess — and the way a caller asks for
      // the dial code to come off.
      final value = await _typed(tester, _kUnitedKingdom, '+447911123456');

      expect(value?.number, '7911123456');
      expect(value?.fullNumber, '+447911123456');
    });

    testWidgets('a plus-less dial code is left alone', (tester) async {
      // `+1` used to match by prefix, so every US number starting with 1 lost
      // that digit.
      final value = await _typed(tester, .unitedStates, '15551234567');

      expect(value?.number, '15551234567');
    });

    testWidgets('+ is typeable even with onlyNumber on', (tester) async {
      // Without this the new rule is unusable: the dial code only comes off
      // when the typist writes it, and digits-only filtering forbade `+`.
      final value = await _typed(tester, _kKorea, '+821012345678');

      expect(value?.number, '1012345678');
    });

    testWidgets('a + after digits is still rejected', (tester) async {
      final value = await _typed(tester, _kKorea, '10+12345678');

      expect(value?.number, '1012345678');
    });
  });
}
