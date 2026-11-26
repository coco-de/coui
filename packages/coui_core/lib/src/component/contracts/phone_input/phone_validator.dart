import 'dart:async';

import 'package:coui_core/src/component/contracts/form/core_validation_context.dart';
import 'package:coui_core/src/component/contracts/form/form_validation_mode.dart';
import 'package:coui_core/src/component/contracts/form/validation_result.dart';
import 'package:coui_core/src/component/contracts/form/validator.dart';
import 'package:coui_core/src/component/contracts/phone_input/core_phone_number.dart';
import 'package:meta/meta.dart';

/// Fails a [CorePhoneNumber] that carries no national digits.
///
/// A `PhoneInput` always reports a country, so a half-filled field arrives as
/// a non-null value whose [CorePhoneNumber.number] is empty — which
/// [RequiredValidator] passes, because the value itself is present. Without
/// this leaf a caller wanting "a complete phone number" has to hand-write the
/// check, which is the gap this closes.
///
/// ```dart
/// FormField(
///   validator: const CompositeValidator([
///     RequiredValidator(),
///     PhoneValidator(),
///   ]),
///   child: PhoneInput(...),
/// )
/// ```
///
/// ## What it deliberately does not check
///
/// Emptiness is the only judgement available. Deciding whether a number is
/// the right *length* for its country, or whether its trunk prefix belongs,
/// needs per-territory metadata that neither `CoreCountry` nor its upstream
/// dataset carries — `CoreCountry` is `code` / `dialCode` / `name` and
/// nothing else. A validator that guessed at length would reject valid
/// numbers in whichever countries it guessed wrong about, and it would do so
/// silently.
///
/// ## Why the name has no `Core` prefix
///
/// It follows the validator family it joins — `NotValidator`, `OrValidator`,
/// `CompositeValidator`, `RequiredValidator` are all bare — rather than the
/// `Core`-prefixed value types it sits beside in this directory. The leaf is
/// read at the call site next to its siblings, so matching them wins.
@immutable
class PhoneValidator extends Validator<CorePhoneNumber> {
  /// Creates a [PhoneValidator].
  const PhoneValidator({this.message});

  /// Overrides the default `phoneNumberIncomplete` message. Null uses the
  /// localized default from [CoreValidationContext.messages].
  final String? message;

  @override
  FutureOr<ValidationResult?> validate(
    CoreValidationContext context,
    CorePhoneNumber? value,
    FormValidationMode state,
  ) {
    // `country` is non-nullable on `CorePhoneNumber`, so "which country" is
    // never the missing half — only the digits can be.
    final isIncomplete = value == null || value.number.isEmpty;
    if (!isIncomplete) {
      return null;
    }

    return InvalidResult(
      message ?? context.messages.phoneNumberIncomplete,
      state: state,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PhoneValidator && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
