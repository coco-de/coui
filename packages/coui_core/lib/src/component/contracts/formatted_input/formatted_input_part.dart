/// Segment definition for `FormattedInput`.
library;

import 'package:coui_core/src/component/contracts/formatted_input/formatted_input_mask_engine.dart';
import 'package:meta/meta.dart';

/// A single segment within a `FormattedInput` mask.
///
/// A segment is either an **editable** field (accepts [length] characters,
/// optionally constrained by [pattern]) or a **static** separator that
/// renders fixed [text] (e.g. `'/'`, `'-'`, `') '`).
///
/// Platform-neutral — both Flutter `FormattedInput` and Web
/// `FormattedInput` consume the same part list so a phone / credit-card
/// / date mask behaves identically.
@immutable
class CoreFormattedInputPart {
  /// Creates an editable segment that accepts [length] characters.
  ///
  /// - [placeholder]: placeholder character shown for empty positions.
  /// - [pattern]: optional regular-expression source restricting input
  ///   (e.g. `r'\d'` for digits only).
  const CoreFormattedInputPart.editable({
    required this.length,
    this.placeholder = '_',
    this.pattern,
  }) : text = null,
       editable = true;

  /// Creates a static separator segment rendering fixed [text].
  const CoreFormattedInputPart.static(this.text)
    : length = 0,
      placeholder = '',
      pattern = null,
      editable = false;

  /// Number of characters accepted by an editable segment.
  final int length;

  /// Static text rendered by a separator segment, or `null` for editable.
  final String? text;

  /// Placeholder character for empty positions in an editable segment.
  final String placeholder;

  /// Optional regular-expression source restricting editable input.
  final String? pattern;

  /// Whether this segment is editable (`true`) or a static separator.
  final bool editable;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreFormattedInputPart &&
          runtimeType == other.runtimeType &&
          length == other.length &&
          text == other.text &&
          placeholder == other.placeholder &&
          pattern == other.pattern &&
          editable == other.editable;

  @override
  int get hashCode => Object.hash(length, text, placeholder, pattern, editable);
}

/// Built-in [CoreFormattedInputPart] mask presets.
abstract final class CoreFormattedInputMasks {
  const CoreFormattedInputMasks._();

  /// Phone number mask: `(___) ___-____`.
  static const List<CoreFormattedInputPart> phone = [
    CoreFormattedInputPart.static('('),
    CoreFormattedInputPart.editable(length: 3, pattern: r'\d'),
    CoreFormattedInputPart.static(') '),
    CoreFormattedInputPart.editable(length: 3, pattern: r'\d'),
    CoreFormattedInputPart.static('-'),
    CoreFormattedInputPart.editable(length: 4, pattern: r'\d'),
  ];

  /// Credit card mask: `____ ____ ____ ____`.
  static const List<CoreFormattedInputPart> creditCard = [
    CoreFormattedInputPart.editable(length: 4, pattern: r'\d'),
    CoreFormattedInputPart.static(' '),
    CoreFormattedInputPart.editable(length: 4, pattern: r'\d'),
    CoreFormattedInputPart.static(' '),
    CoreFormattedInputPart.editable(length: 4, pattern: r'\d'),
    CoreFormattedInputPart.static(' '),
    CoreFormattedInputPart.editable(length: 4, pattern: r'\d'),
  ];

  /// Date mask: `__/__/____`.
  static const List<CoreFormattedInputPart> date = [
    CoreFormattedInputPart.editable(length: 2, pattern: r'\d'),
    CoreFormattedInputPart.static('/'),
    CoreFormattedInputPart.editable(length: 2, pattern: r'\d'),
    CoreFormattedInputPart.static('/'),
    CoreFormattedInputPart.editable(length: 4, pattern: r'\d'),
  ];

  /// Korean mobile phone mask: `___-____-____` (3-4-4, 11 digits total —
  /// e.g. `010-1234-5678`). Landline numbers use variable-length regional
  /// prefixes and are out of scope; mobile is the only shape an SMS
  /// verification flow needs.
  static const List<CoreFormattedInputPart> koreanPhone = [
    CoreFormattedInputPart.editable(length: 3, pattern: r'\d'),
    CoreFormattedInputPart.static('-'),
    CoreFormattedInputPart.editable(length: 4, pattern: r'\d'),
    CoreFormattedInputPart.static('-'),
    CoreFormattedInputPart.editable(length: 4, pattern: r'\d'),
  ];

  /// Default autofill intent for [phone] — platform widgets translate
  /// this into `AutofillHints.telephoneNumber` / HTML `autocomplete=tel`.
  static const CoreFormattedInputAutofillHint phoneAutofillHint =
      .telephoneNumber;

  /// Default autofill intent for [koreanPhone].
  static const CoreFormattedInputAutofillHint koreanPhoneAutofillHint =
      .telephoneNumber;

  /// Default autofill intent for [creditCard].
  static const CoreFormattedInputAutofillHint creditCardAutofillHint =
      .creditCardNumber;
}
