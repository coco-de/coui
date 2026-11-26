/// Platform-independent ambient scope value published by `FormField` /
/// `Fieldset`.
library;

import 'package:meta/meta.dart';

/// Ambient disabled / error constraint a `FormField` — or an enclosing
/// `Fieldset` — exposes to the input it wraps.
///
/// `FormField` already reflects its own `enabled` / error state in its
/// OWN label chrome (the composed `FormLabel`'s disabled overlay, the
/// composed error `ValidatorHint`), but never told its `child` input
/// slot about either — an error message could be showing right above a
/// `TextField` whose border stayed the ordinary enabled colour, and a
/// `Fieldset(enabled: false)` never reached the fields nested inside it
/// at all. `CoreFormFieldScope` is the value both `FormField` and
/// `Fieldset` publish as an ambient scope (same shape as
/// `CouiLocalizationsScope` / `FormFieldHandleScope` — pure metadata, no
/// widget of its own) so a consuming input can fold the wrapper's state
/// into its own chrome.
///
/// [disabled] combines with the input's own `enabled` flag with AND —
/// an enclosing `Fieldset(enabled: false)` always wins over a field
/// stated `enabled: true` (HTML `<fieldset disabled>` semantics).
/// [hasError] combines with the input's own error flag with OR — a
/// `FormField(error: '...')` puts its child into the error tone even
/// when the input was not separately told an error string. A
/// `Fieldset` never states an error of its own, so the scope it
/// publishes always carries `hasError: false`.
@immutable
class CoreFormFieldScope {
  /// Creates a [CoreFormFieldScope].
  const CoreFormFieldScope({required this.disabled, required this.hasError});

  /// Whether the wrapper that published this scope (the `FormField` or
  /// `Fieldset`) is disabled.
  final bool disabled;

  /// Whether the wrapper that published this scope carries an error.
  final bool hasError;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreFormFieldScope &&
          runtimeType == other.runtimeType &&
          disabled == other.disabled &&
          hasError == other.hasError;

  @override
  int get hashCode => Object.hash(disabled, hasError);
}
