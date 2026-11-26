// Immutable value object.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:phonecodes/phonecodes.dart' as phonecodes;

/// Platform-independent country entry for phone input components.
///
/// Use [code] (ISO 2-letter), [dialCode] ('+N'), and [name] as the
/// minimal fields required to render a country selector.
///
/// Example:
/// ```dart
/// const CoreCountry(code: 'US', dialCode: '+1', name: 'United States');
/// ```
class CoreCountry {
  /// Creates a [CoreCountry].
  const CoreCountry({
    required this.code,
    required this.dialCode,
    required this.name,
  });

  /// ISO 2-letter country code (e.g. `US`, `KR`).
  final String code;

  /// Dial code with plus prefix (e.g. `+1`, `+82`).
  final String dialCode;

  /// Localized country name.
  final String name;

  /// The full 247-country dataset, shared with the Flutter `PhoneInput`
  /// (both derive from the same `phonecodes` package) so a `PhoneInput`
  /// with no explicit `countries` lists the same set on Web and Flutter.
  static final List<CoreCountry> all = [
    for (final c in phonecodes.Country.values)
      CoreCountry(code: c.code, dialCode: c.dialCode, name: c.name),
  ];

  /// The United States (`+1`).
  ///
  /// A compile-time `const` (matching the `US` entry in [all]) so it stays
  /// usable in `const` contexts the way the old `phonecodes` enum member
  /// was — `const PhoneInput(initialCountry: CoreCountry.unitedStates)`.
  static const CoreCountry unitedStates = CoreCountry(
    code: 'US',
    dialCode: '+1',
    name: 'United States',
  );

  /// South Korea (`+82`) — a compile-time `const` matching the `KR` entry
  /// in [all], so it is usable in `const` contexts like [unitedStates].
  static const CoreCountry southKorea = CoreCountry(
    code: 'KR',
    dialCode: '+82',
    name: 'South Korea',
  );

  /// Offset from ASCII A to Regional Indicator Symbol Letter A.
  static const int _kRegionalIndicatorOffset = 0x1F1E6 - 0x41;

  /// Looks up a country in [all] by its ISO 2-letter [code]
  /// (case-insensitive), e.g. `CoreCountry.byCode('CA')`. Returns `null`
  /// when no country matches — replaces the `phonecodes` enum's named
  /// members (`Country.canada`) with a data-list lookup.
  static CoreCountry? byCode(String code) {
    final upper = code.toUpperCase();
    for (final c in all) {
      if (c.code == upper) return c;
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    return other is CoreCountry &&
        other.code == code &&
        other.dialCode == dialCode &&
        other.name == name;
  }

  @override
  String toString() => 'CoreCountry($code, $dialCode, $name)';

  /// Converts an ISO 2-letter country code to its flag emoji string.
  ///
  /// Used to render country flags consistently across Web and Flutter.
  /// Returns an empty string if [code] is not exactly 2 characters.
  static String flagEmoji(String code) {
    if (code.length != 2) return '';
    final upper = code.toUpperCase();
    return String.fromCharCodes([
      upper.codeUnitAt(0) + _kRegionalIndicatorOffset,
      upper.codeUnitAt(1) + _kRegionalIndicatorOffset,
    ]);
  }

  @override
  int get hashCode => Object.hash(code, dialCode, name);
}
