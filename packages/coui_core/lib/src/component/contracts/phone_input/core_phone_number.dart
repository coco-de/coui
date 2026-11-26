import 'package:coui_core/src/component/contracts/phone_input/core_country.dart';
import 'package:meta/meta.dart';

/// Platform-independent phone number value for phone input components.
///
/// Holds the selected [country] plus the national [number] (no dial code).
/// Both platforms' `PhoneInput` reports this type through `onChanged` and
/// accepts it as `initialValue`, so a caller that stores or restores a
/// phone value speaks the same type on Web and Flutter.
///
/// Example:
/// ```dart
/// const CorePhoneNumber(CoreCountry.unitedStates, '5551234567');
/// ```
@immutable
class CorePhoneNumber {
  /// Creates a [CorePhoneNumber] for [country] holding the national [number].
  const CorePhoneNumber(this.country, this.number);

  /// Derives a [CorePhoneNumber] from the raw [text] sitting in a number
  /// field, dropping the dial code only when the typist wrote it.
  ///
  /// [filterPlusCode] (the default) drops a leading `+<dialCode>` **that
  /// matches [country]** — `+447911123456` under GB becomes `7911123456`.
  /// Nothing else is removed. Text that carries no such prefix is carried
  /// through exactly as typed.
  ///
  /// Deriving on read rather than rewriting the field is what lets a country
  /// change re-interpret the same text against the newly selected dial code.
  ///
  /// ## Why nothing else is stripped
  ///
  /// Earlier versions also removed a leading `0` and a dial code written
  /// without its plus. Both are guesses about what the remaining digits mean,
  /// and no single guess is right everywhere: a UK number drops its trunk `0`
  /// in E.164 (`07911123456` → `+447911123456`) while an Italian one keeps it
  /// (`0612345678` → `+390612345678`). The two inputs are the same shape and
  /// the dial code carries no trunk semantics, so any rule reaching inside a
  /// bare `0…` is right for one country and wrong for the other — it does not
  /// remove the corruption, it relocates it.
  ///
  /// Telling those countries apart needs a per-territory national-prefix
  /// table, which neither [CoreCountry] nor its upstream dataset carries.
  /// Until that data exists, this reads what was typed and does not guess.
  /// A caller who wants the dial code removed types it.
  factory CorePhoneNumber.fromInput(
    CoreCountry country,
    String text, {
    bool filterPlusCode = true,
  }) {
    final dialCode = country.dialCode;
    // The one removal that is not a guess: the typist wrote this country's
    // dial code, so the rest is the national number by construction.
    final national = filterPlusCode && text.startsWith(dialCode)
        ? text.substring(dialCode.length)
        : text;

    return CorePhoneNumber(country, national);
  }

  /// Selected country, carrying its ISO code, dial code and name.
  final CoreCountry country;

  /// National phone number — no dial code, no trunk prefix.
  final String number;

  /// ISO 2-letter code of [country] (e.g. `US`, `KR`).
  String get countryCode => country.code;

  /// Dial code of [country] with plus prefix (e.g. `+1`, `+82`).
  String get dialCode => country.dialCode;

  /// The full phone number including the dial code.
  String get fullNumber => '$dialCode$number';

  /// The [fullNumber], or `null` when [number] is empty.
  String? get value => number.isEmpty ? null : fullNumber;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CorePhoneNumber &&
        other.country == country &&
        other.number == number;
  }

  @override
  String toString() => number.isEmpty ? '' : fullNumber;

  @override
  int get hashCode => Object.hash(country, number);
}
