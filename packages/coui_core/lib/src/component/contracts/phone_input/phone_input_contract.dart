/// Platform-independent contract for phone input components.
///
/// Defines the interface that all phone input implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/phone_input/core_country.dart';
import 'package:coui_core/src/component/contracts/phone_input/phone_input_style.dart';

/// Contract for a phone input component.
///
/// Type parameters:
/// - [Ctrl] - text editing controller type.
///   Flutter: `TextEditingController?`, Web: `Null`.
/// - [V] - phone value type emitted by `onChanged` and accepted by
///   `initialValue`. Both platforms bind `CorePhoneNumber` (Flutter names
///   it `PhoneNumber`, Web `PhoneInputValue`).
/// - [C] - country type used by `initialCountry` / `countries`.
///   Both platforms bind `CoreCountry`.
///
/// The change callback is derived directly as `void Function(V)?` —
/// no phantom `ChangedCb` type parameter (per `cautions.md`
/// "Contract callback 타입").
///
/// Implementations should render a combined country selector
/// and phone number text field.
abstract interface class CorePhoneInputContract<Ctrl, V, C> {
  /// Default for [filterPlusCode] — shared so both platforms cannot drift.
  static const bool defaultFilterPlusCode = true;

  /// Country a phone input starts on when neither `initialValue` nor
  /// `initialCountry` names one — South Korea, the home market of the
  /// services this kit is built for. Shared so both platforms cannot drift.
  static const CoreCountry defaultInitialCountry = CoreCountry.southKorea;

  /// Callback when the phone number changes.
  void Function(V)? get onChanged;

  /// Whether the input is enabled.
  bool get enabled;

  /// Whether to allow only numeric input.
  bool get onlyNumber;

  /// Controller for the number input field.
  Ctrl get controller;

  /// Placeholder text for the number input field.
  String? get placeholder;

  /// Default country when no initial value is provided.
  ///
  /// `null` → [defaultInitialCountry].
  C? get initialCountry;

  /// Initial phone number (without dial code).
  String? get initialNumber;

  /// Combined initial phone number (country + number).
  ///
  /// When provided, its country takes precedence over [initialCountry] and
  /// its number over [initialNumber].
  V? get initialValue;

  /// Whether to drop a leading `+<dialCode>` (else a bare `+`) when reading
  /// the typed number.
  ///
  /// Filtering happens on read, not by rewriting the field, so the number a
  /// caller receives is re-derived from the same text whenever the selected
  /// country changes.
  bool get filterPlusCode;

  /// Available countries for selection.
  List<C>? get countries;

  /// Per-instance composite chrome / slot style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CorePhoneInputTheme (legacy flat fields)
  ///   → CorePhoneInputTheme.style
  ///   → parent component slot override
  ///   → widget.phoneInputStyle
  /// ```
  CorePhoneInputStyle? get phoneInputStyle;
}
