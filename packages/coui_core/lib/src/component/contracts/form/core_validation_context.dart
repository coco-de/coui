/// Platform-independent validation context.
library;

/// Localized default validation messages a validator surfaces when it has no
/// explicit message of its own.
///
/// The Flutter binding adapts `CoUILocalizations`; the Web binding supplies
/// its own localized strings. Lives in `coui_core` so validators can produce
/// localized errors without depending on a platform localization class.
abstract interface class CoreValidationMessages {
  /// Generic "invalid value" message.
  String get invalidValue;

  /// "This field cannot be empty" message.
  String get formNotEmpty;

  /// Message for a phone number that carries a country but no digits.
  ///
  /// Separate from [formNotEmpty] because the field is not blank — a country
  /// is already chosen — so "cannot be empty" reads as though nothing was
  /// touched. This says the number itself is unfinished.
  String get phoneNumberIncomplete;
}

/// Context passed to `Validator.validate`, abstracting the platform
/// dependencies a validator needs.
///
/// Replaces the Flutter `BuildContext` that validators previously took: it
/// exposes [messages] (for localized default errors) and [isActive] (a
/// liveness flag an asynchronous validator checks before using a late
/// result, mirroring `BuildContext.mounted`). The Flutter binding builds
/// this from a `BuildContext`; the Web binding builds its own.
abstract interface class CoreValidationContext {
  /// Localized default validation messages.
  CoreValidationMessages get messages;

  /// Whether the validating host is still active (mounted). Asynchronous
  /// validators check this before applying a result that resolved late.
  bool get isActive;
}
