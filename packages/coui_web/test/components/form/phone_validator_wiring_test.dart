// Proves an incomplete phone number surfaces as a form error on Web.
//
// The core unit test already pins what `PhoneValidator` decides. What this
// adds is the part that only exists on the platform: the message it asks for
// has to travel through `CoUIWebValidationContext` -> the private
// `CoreValidationMessages` bridge -> `CouiLocalizations` before anyone sees
// it. A key wired into the interface but not into the bridge would pass the
// core test and produce nothing here.
//
// Deliberately driven through the real `CoUIWebValidationContext` rather than
// a fake, for exactly that reason.

import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

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

InvalidResult? _errorFor(CorePhoneNumber? value) {
  final controller = FormController()
    ..attach(
      CoUIWebValidationContext(),
      const _StubHandle(_kFieldKey),
      value,
      const PhoneValidator(),
    );

  return controller.getSyncError(_kFieldKey) as InvalidResult?;
}

void main() {
  group('PhoneValidator in a Web Form', () {
    test('a country-only value surfaces the localized error', () {
      final error = _errorFor(const CorePhoneNumber(_kKorea, ''));

      expect(error, isNotNull);
      expect(
        error!.message,
        DefaultCouiLocalizations.instance.phoneNumberIncomplete,
        reason: 'the message must come from localization, not a literal',
      );
      expect(error.message, isNotEmpty);
    });

    test('a complete number produces no error', () {
      expect(_errorFor(const CorePhoneNumber(_kKorea, '1012345678')), isNull);
    });

    test('the incomplete message is distinct from the generic empty one', () {
      expect(
        DefaultCouiLocalizations.instance.phoneNumberIncomplete,
        isNot(DefaultCouiLocalizations.instance.formNotEmpty),
      );
    });

    test('the key is translated, not passed through', () {
      expect(
        KoCouiLocalizations.instance.phoneNumberIncomplete,
        isNot(DefaultCouiLocalizations.instance.phoneNumberIncomplete),
      );
      expect(KoCouiLocalizations.instance.phoneNumberIncomplete, isNotEmpty);
    });
  });
}
