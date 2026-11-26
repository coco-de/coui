// Proves an incomplete phone number surfaces as a form error on Flutter.
//
// The core unit test pins what `PhoneValidator` decides. What only exists on
// the platform is the trip the message takes: `CoUIValidationContext` wraps a
// real `BuildContext`, the private `CoreValidationMessages` bridge reads
// `CoUILocalizations` off it, and only then does a string exist. A key added
// to the interface but not to the bridge passes the core test and produces
// nothing here — which is why this drives the real context rather than a fake.

import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _kKorea = CoreCountry(code: 'KR', dialCode: '+82', name: 'Korea');
const _kFieldKey = FormKey<CorePhoneNumber>('phone');

/// Minimal handle — `attach` only reads [formKey] from it.
class _StubHandle implements CoreFormFieldHandle {
  const _StubHandle(this.formKey);

  @override
  final CoreFormKey<dynamic> formKey;

  @override
  bool get mounted => true;

  @override
  FutureOr<ValidationResult?> reportNewFormValue<T>(T? value) => null;

  @override
  FutureOr<ValidationResult?> revalidate() => null;
}

/// Pumps a host, then validates [value] through the real Flutter context.
Future<InvalidResult?> _errorFor(
  WidgetTester tester,
  CorePhoneNumber? value, {
  Locale locale = const Locale('en'),
}) async {
  late BuildContext hostContext;
  // `Localizations` directly rather than `MaterialApp`: Material and Cupertino
  // ship no `ko` delegate, and their absence is *thrown* as a framework
  // warning, which the test binding counts as a failure. Nothing here renders
  // a Material widget, so those delegates are not owed — and leaving them out
  // keeps the case about CoUI's own localization rather than Flutter's.
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Localizations(
        locale: locale,
        delegates: const [
          CoUILocalizationsDelegate(),
          material.DefaultWidgetsLocalizations.delegate,
        ],
        child: Theme(
          data: const ThemeData(),
          child: Builder(
            builder: (context) {
              hostContext = context;

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    ),
  );

  final controller = FormController();
  addTearDown(controller.dispose);
  controller.attach(
    CoUIValidationContext(hostContext),
    const _StubHandle(_kFieldKey),
    value,
    const PhoneValidator(),
  );

  return controller.getSyncError(_kFieldKey) as InvalidResult?;
}

void main() {
  group('PhoneValidator in a Flutter Form', () {
    testWidgets('a country-only value surfaces the localized error', (
      tester,
    ) async {
      final error = await _errorFor(tester, const CorePhoneNumber(_kKorea, ''));

      expect(error, isNotNull);
      expect(
        error!.message,
        DefaultCoUILocalizations.instance.phoneNumberIncomplete,
        reason: 'the message must come from localization, not a literal',
      );
      expect(error.message, isNotEmpty);
    });

    testWidgets('a complete number produces no error', (tester) async {
      expect(
        await _errorFor(tester, const CorePhoneNumber(_kKorea, '1012345678')),
        isNull,
      );
    });

    testWidgets('the error follows the active locale', (tester) async {
      final korean = await _errorFor(
        tester,
        const CorePhoneNumber(_kKorea, ''),
        locale: const Locale('ko'),
      );

      expect(
        korean!.message,
        KoCoUILocalizations.instance.phoneNumberIncomplete,
      );
      expect(
        korean.message,
        isNot(DefaultCoUILocalizations.instance.phoneNumberIncomplete),
        reason: 'a hardcoded English string would pass every other case',
      );
    });

    testWidgets('the incomplete message is distinct from the empty one', (
      tester,
    ) async {
      expect(
        DefaultCoUILocalizations.instance.phoneNumberIncomplete,
        isNot(DefaultCoUILocalizations.instance.formNotEmpty),
      );
    });
  });
}
