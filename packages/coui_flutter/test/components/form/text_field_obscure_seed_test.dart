// Pins `TextField.obscureText` as a mount-time seed.
//
// The field reads the flag once, into its own obscured state, and a
// `passwordToggle` is the only thing that flips it afterwards. A caller
// following the Material habit — flipping `obscureText: !visible` from
// outside — used to get nothing at all: no mask change, no message. These
// cases hold the seed semantics in place and make the misuse loud in
// debug builds — reported, not thrown, so the tree survives it.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(body: child),
  ),
);

bool _masked(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).obscureText;

void main() {
  group('TextField obscureText seed', () {
    testWidgets('a later change does not re-mask and reports in debug', (
      tester,
    ) async {
      await tester.pumpWidget(_app(TextField(obscureText: true)));
      expect(_masked(tester), isTrue);

      await tester.pumpWidget(_app(TextField()));

      final error = tester.takeException();
      expect(error, isA<FlutterError>());
      expect(error.toString(), contains('passwordToggle'));
      expect(
        _masked(tester),
        isTrue,
        reason: 'the field owns the obscured state after mount',
      );
    });

    testWidgets('does not report when a passwordToggle owns the state', (
      tester,
    ) async {
      const features = [CoreInputFeature.passwordToggle()];
      await tester.pumpWidget(
        _app(TextField(obscureText: true, features: features)),
      );

      await tester.pumpWidget(_app(TextField(features: features)));

      expect(tester.takeException(), isNull);
      expect(_masked(tester), isTrue);
    });

    testWidgets('a new key reseeds from the new value', (tester) async {
      await tester.pumpWidget(
        _app(TextField(key: const ValueKey(true), obscureText: true)),
      );
      expect(_masked(tester), isTrue);

      await tester.pumpWidget(_app(TextField(key: const ValueKey(false))));

      expect(tester.takeException(), isNull);
      expect(_masked(tester), isFalse);
    });
  });
}
