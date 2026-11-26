// Pins the phone-completeness validator.
//
// The gap it closes is narrow and easy to mis-state: a `PhoneInput` always
// reports a country, so a field where the user picked a country and typed
// nothing arrives as a NON-null `CorePhoneNumber` whose `number` is empty.
// `RequiredValidator` passes that value — the value is present — so before
// this leaf there was no way to say "a complete phone number" in a `Form`
// without hand-writing the check.
//
// The `RequiredValidator passes a country-only value` case is the one that
// justifies the leaf existing at all; if it ever starts failing, this
// validator is redundant and should be deleted rather than kept.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kKorea = CoreCountry(code: 'KR', dialCode: '+82', name: 'Korea');

const _kIncompleteMessage = 'incomplete!';
const _kEmptyMessage = 'empty!';

class _Messages implements CoreValidationMessages {
  @override
  String get invalidValue => 'invalid!';

  @override
  String get formNotEmpty => _kEmptyMessage;

  @override
  String get phoneNumberIncomplete => _kIncompleteMessage;
}

class _Context implements CoreValidationContext {
  @override
  CoreValidationMessages get messages => _Messages();

  @override
  bool get isActive => true;
}

Future<ValidationResult?> _run(
  Validator<CorePhoneNumber> validator,
  CorePhoneNumber? value,
) async => validator.validate(_Context(), value, FormValidationMode.submitted);

void main() {
  group('PhoneValidator', () {
    test('passes a number carrying digits', () async {
      expect(
        await _run(
          const PhoneValidator(),
          const CorePhoneNumber(
            _kKorea,
            '1012345678',
          ),
        ),
        isNull,
      );
    });

    test('fails a country-only value', () async {
      final result = await _run(
        const PhoneValidator(),
        const CorePhoneNumber(_kKorea, ''),
      );

      expect(result, isA<InvalidResult>());
      expect((result! as InvalidResult).message, _kIncompleteMessage);
    });

    test('fails a null value', () async {
      final result = await _run(const PhoneValidator(), null);

      expect(result, isA<InvalidResult>());
      expect((result! as InvalidResult).message, _kIncompleteMessage);
    });

    test('an explicit message overrides the localized default', () async {
      final result = await _run(
        const PhoneValidator(message: 'custom'),
        const CorePhoneNumber(_kKorea, ''),
      );

      expect((result! as InvalidResult).message, 'custom');
    });

    test('the incomplete message is not the generic empty message', () {
      expect(
        _Messages().phoneNumberIncomplete,
        isNot(_Messages().formNotEmpty),
        reason: 'the field is not blank — a country is already chosen',
      );
    });

    test('RequiredValidator passes a country-only value', () async {
      // The reason this leaf exists. A phone value is never "missing" in the
      // sense RequiredValidator checks, so it cannot catch a half-filled
      // field on its own.
      expect(
        await const RequiredValidator<CorePhoneNumber>().validate(
          _Context(),
          const CorePhoneNumber(_kKorea, ''),
          FormValidationMode.submitted,
        ),
        isNull,
      );
    });

    test('composes with RequiredValidator', () async {
      const composite = CompositeValidator<CorePhoneNumber>([
        RequiredValidator<CorePhoneNumber>(),
        PhoneValidator(),
      ]);

      expect(
        await composite.validate(
          _Context(),
          const CorePhoneNumber(_kKorea, '1012345678'),
          FormValidationMode.submitted,
        ),
        isNull,
      );

      final incomplete = await composite.validate(
        _Context(),
        const CorePhoneNumber(_kKorea, ''),
        FormValidationMode.submitted,
      );
      expect((incomplete! as InvalidResult).message, _kIncompleteMessage);
    });

    test('value equality covers the message', () {
      expect(const PhoneValidator(), const PhoneValidator());
      expect(
        const PhoneValidator().hashCode,
        const PhoneValidator().hashCode,
      );
      expect(
        const PhoneValidator(message: 'a'),
        isNot(const PhoneValidator(message: 'b')),
      );
    });
  });
}
